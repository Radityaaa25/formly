import 'dart:async';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import '../../core/router/app_router.dart';
import '../../core/services/audio_service.dart';
import '../../core/services/pose/exercise_analyzer.dart';
import '../../core/services/pose/pose_frame.dart';
import '../../core/services/tts_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_button.dart';
import '../../core/widgets/pain_slider.dart';
import '../../core/widgets/pose_camera.dart';
import '../../data/mock_data.dart';
import '../../data/models/exercise.dart';
import '../../data/models/session_result.dart';
import '../../data/repositories/user_repository.dart';
import '../../state/app_state.dart';
import '../../state/user_data_state.dart';

enum _Phase { pain, checks, countdown, live }

class SessionScreen extends ConsumerStatefulWidget {
  const SessionScreen({
    super.key,
    required this.exerciseId,
    this.variationName,
    this.sets,
    this.reps,
  });

  final String exerciseId;
  final String? variationName;
  final int? sets;
  final int? reps;

  @override
  ConsumerState<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends ConsumerState<SessionScreen> {
  late final int _targetReps;
  late final int _plankTargetSeconds;

  late final Exercise _exercise;
  late ExerciseAnalyzer _analyzer;
  late _Phase _phase;

  final _checks = _PoseChecks();
  final Map<String, int> _errors = {};

  Timer? _countdownTimer;
  Timer? _clockTimer;

  CameraLensDirection _lens = CameraLensDirection.back;
  int _count = 3;
  int _reps = 0;
  int _elapsed = 0;
  int _painBefore = 2;
  double _scoreSum = 0;
  int _scoreCount = 0;
  double _quality = 0;

  bool _paused = false;
  bool _targetAnnounced = false;
  bool _poseWarning = false;
  bool _autoStarting = false;
  DateTime? _invalidSince;
  DateTime? _allGoodSince;
  DateTime _lastCheckAnnounce = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastCueAt = DateTime.fromMillisecondsSinceEpoch(0);
  String? _liveCue;

  bool get _timed => _exercise.kind == ExerciseKind.timed;

  @override
  void initState() {
    super.initState();
    _exercise = MockData.exerciseById(widget.exerciseId);
    _targetReps = widget.reps ?? 10;
    _plankTargetSeconds = widget.reps ?? 30;
    _analyzer = ExerciseAnalyzer.forExercise(_exercise.id);
    _phase = ref.read(appModeProvider) == AppMode.rehab
        ? _Phase.pain
        : _Phase.checks;
    final settings = ref.read(appSettingsProvider);
    unawaited(
      TtsService.instance
          .init(
            volume: settings.volume / 100,
            speechRate: 0.3 + (settings.speechRate / 100) * 0.6,
          )
          .then((_) {
            if (!mounted) return;
            if (_phase == _Phase.checks) {
              _speak('Siapkan posisi dan pastikan pencahayaan cukup.');
            }
          }),
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _clockTimer?.cancel();
    unawaited(AudioService.instance.stop());
    unawaited(TtsService.instance.stop());
    super.dispose();
  }

  void _speak(String text) {
    if (ref.read(appSettingsProvider).silentMode) return;
    unawaited(TtsService.instance.speak(text));
  }

  // ---------------- POSE CALLBACK ----------------

  void _onPose(PoseFrame frame) {
    if (!mounted) return;
    if (_phase == _Phase.checks) {
      final changed = _checks.update(frame, _exercise);
      if (changed) setState(() {});

      _maybeAnnounceCheckIssue();
      _maybeAutoStart();
      return;
    }

    if (_phase != _Phase.live || _paused) return;

    final output = _analyzer.update(frame);
    _quality = output.quality > 0 ? output.quality : _quality;

    if (!output.poseValid) {
      _invalidSince ??= DateTime.now();
      if (!_poseWarning &&
          DateTime.now().difference(_invalidSince!).inMilliseconds > 1500) {
        _poseWarning = true;
        _speak('Posisi kurang terlihat');
        setState(() {});
      }
      return;
    }

    if (_poseWarning) {
      _poseWarning = false;
      _invalidSince = null;
      _speak('Bagus, lanjut');
      setState(() {});
    }

    if (output.repCompleted) {
      _handleRepCompleted(output);
    } else {
      final cue = output.liveCue;
      if (cue != null && cue != _liveCue) {
        setState(() => _liveCue = cue);
      }
      if (cue != null && DateTime.now().difference(_lastCueAt).inSeconds >= 5) {
        _lastCueAt = DateTime.now();
        _speak(cue);
      }
    }

    if (!_timed && _reps >= _targetReps && !_targetAnnounced) {
      _targetAnnounced = true;
      _speak('Target tercapai. Tekan selesai kalau sudah cukup.');
    }

    setState(() {});
  }

  void _handleRepCompleted(AnalyzerOutput output) {
    _reps += 1;
    final score = output.repScore ?? 80;
    _scoreSum += score;
    _scoreCount += 1;
    for (final error in output.repErrors) {
      _errors[error] = (_errors[error] ?? 0) + 1;
    }

    String phrase = '';
    if (output.repErrors.isNotEmpty) {
      phrase = output.repErrors.first;
    } else if (_reps % 3 == 0 || score >= 92) {
      phrase = _encouragements[math.Random().nextInt(_encouragements.length)];
    }

    _liveCue = output.repErrors.isEmpty
        ? 'Bagus, pertahankan'
        : output.repErrors.first;
    _lastCueAt = DateTime.now();
    _speak(phrase.isEmpty ? '$_reps' : '$_reps. $phrase');
  }

  static const _encouragements = [
    'Bagus!',
    'Mantap, pertahankan!',
    'Semangat, kamu bisa!',
    'Keren, lanjutkan!',
    'Formamu bagus!',
    'Terus begitu!',
  ];

  void _maybeAnnounceCheckIssue() {
    final issue = _checks.firstIssue(_exercise);
    if (issue == null) return;
    if (DateTime.now().difference(_lastCheckAnnounce).inSeconds < 4) return;
    _lastCheckAnnounce = DateTime.now();
    _speak(issue);
  }

  void _maybeAutoStart() {
    if (_autoStarting) return;
    if (!_checks.allPassed) {
      _allGoodSince = null;
      return;
    }
    _allGoodSince ??= DateTime.now();
    if (DateTime.now().difference(_allGoodSince!).inMilliseconds >= 900) {
      _autoStarting = true;
      _speak('Siap. Mulai dalam tiga.');
      _startCountdown();
    }
  }

  // ---------------- FLOW ----------------

  void _startCountdown() {
    if (_phase == _Phase.countdown || _phase == _Phase.live) return;
    setState(() {
      _phase = _Phase.countdown;
      _count = 3;
    });
    if (!ref.read(appSettingsProvider).silentMode) {
      unawaited(AudioService.instance.start());
    }
    _speak('3');
    _countdownTimer = Timer.periodic(const Duration(milliseconds: 900), (
      timer,
    ) {
      if (!mounted) return;
      final next = _count - 1;
      setState(() => _count = next);
      if (next <= 0) {
        timer.cancel();
        _goLive();
      } else {
        _speak('$next');
      }
    });
  }

  void _goLive() {
    setState(() {
      _phase = _Phase.live;
      _paused = false;
      _liveCue = _timed ? 'Tahan posisi' : 'Mulai';
    });
    _speak('Mulai');
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_paused) return;
      setState(() {
        _elapsed += 1;
        if (_timed && _elapsed >= _plankTargetSeconds) {
          _targetAnnounced = true;
        }
      });
      if (_timed && _elapsed == _plankTargetSeconds) {
        _speak('Hebat, tahan sampai selesai');
      }
    });
  }

  void _togglePause() {
    setState(() => _paused = !_paused);
    if (_paused) {
      unawaited(AudioService.instance.pause());
      _speak('Dijeda');
    } else {
      unawaited(AudioService.instance.resume());
      _invalidSince = null;
      _speak('Lanjut');
    }
  }

  void _flipCamera() {
    setState(() {
      _lens = _lens == CameraLensDirection.back
          ? CameraLensDirection.front
          : CameraLensDirection.back;
      _analyzer = ExerciseAnalyzer.forExercise(_exercise.id);
      _checks.reset();
      _autoStarting = false;
      _allGoodSince = null;
      _poseWarning = false;
      _invalidSince = null;
    });
    if (_phase == _Phase.checks) {
      _speak('Kamera diganti. Siapkan posisi.');
    }
  }

  void _finish() {
    _countdownTimer?.cancel();
    _clockTimer?.cancel();
    unawaited(AudioService.instance.stop());
    unawaited(TtsService.instance.stop());

    final averageScore = _scoreCount > 0
        ? (_scoreSum / _scoreCount).round()
        : (_quality > 0 ? _quality.round() : 80);
    final errors = _errors.entries
        .map((entry) => SessionError(label: entry.key, count: entry.value))
        .toList();

    final result = SessionResult(
      exercise: _exercise,
      reps: _timed ? _elapsed : _reps,
      score: averageScore,
      durationSeconds: _elapsed,
      painBefore: _painBefore,
      painAfter: ref.read(appModeProvider) == AppMode.rehab
          ? _painBefore
          : null,
      xpEarned: 45,
      newBadge: _reps >= 10 ? '7 Hari Beruntun' : null,
      errors: errors,
    );
    ref.read(lastSessionProvider.notifier).setResult(result);

    final container = ProviderScope.containerOf(context, listen: false);
    unawaited(
      UserRepository.saveSession(result).then((saved) {
        if (!saved) return;
        container.invalidate(userDashboardProvider);
        container.invalidate(userProfileProvider);
        container.invalidate(rehabProgramProvider);
      }),
    );

    context.pushReplacement(AppRoutes.summary);
  }

  void _stop() {
    _countdownTimer?.cancel();
    _clockTimer?.cancel();
    unawaited(AudioService.instance.stop());
    unawaited(TtsService.instance.stop());
    context.go(AppRoutes.home);
  }

  // ---------------- BUILD ----------------

  @override
  Widget build(BuildContext context) {
    final variationSubtitle = widget.variationName == null
        ? null
        : [
            widget.variationName!,
            if (widget.sets != null && widget.reps != null)
              _timed
                  ? '${widget.sets}×${widget.reps} dtk'
                  : '${widget.sets}×${widget.reps} rep',
          ].join(' · ');

    return Scaffold(
      backgroundColor: AppColors.cam,
      body: PoseCamera(
        lensDirection: _lens,
        onPose: _onPose,
        dim: _phase == _Phase.live ? 0.15 : 0.3,
        child: Stack(
          children: [
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: _TopBar(
                  name: _exercise.name,
                  subtitle: variationSubtitle,
                  phase: _phase,
                  paused: _paused && _phase == _Phase.live,
                  poseWarning: _poseWarning,
                  onFlip: _flipCamera,
                  onClose: _stop,
                ),
              ),
            ),
            if (_phase == _Phase.live)
              SafeArea(
                top: false,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    child: _LiveControls(
                      timed: _timed,
                      reps: _reps,
                      targetReps: _targetReps,
                      elapsed: _elapsed,
                      targetSeconds: _plankTargetSeconds,
                      cue: _liveCue ?? 'Pertahankan form',
                      paused: _paused,
                      score: (_scoreCount > 0
                          ? (_scoreSum / _scoreCount).round()
                          : _quality.round()),
                      onTogglePause: _togglePause,
                      onFinish: _finish,
                    ),
                  ),
                ),
              ),
            if (_phase == _Phase.countdown && _count > 0)
              _CountdownOverlay(count: _count),
            if (_phase == _Phase.pain)
              _BottomPanel(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sebelum mulai',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Bagaimana rasa nyerimu sekarang?',
                      style: TextStyle(
                        fontSize: 14.5,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                    const SizedBox(height: 20),
                    PainSlider(
                      value: _painBefore,
                      onChanged: (value) => setState(() => _painBefore = value),
                    ),
                    const SizedBox(height: 20),
                    GlassButton(
                      label: 'Lanjut',
                      size: GlassButtonSize.large,
                      expand: true,
                      onPressed: () {
                        setState(() => _phase = _Phase.checks);
                        _speak(
                          'Siapkan posisi dan pastikan pencahayaan cukup.',
                        );
                      },
                    ),
                  ],
                ),
              ),
            if (_phase == _Phase.checks)
              _BottomPanel(
                child: _ChecksPanel(
                  checks: _checks,
                  exercise: _exercise,
                  autoStarting: _autoStarting,
                  onForceStart: _startCountdown,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------- CHECKS ----------------

class _PoseChecks {
  bool light = false;
  bool pose = false;
  bool stable = false;

  int _stableFrames = 0;

  bool get allPassed => light && pose && stable;

  void reset() {
    light = false;
    pose = false;
    stable = false;
    _stableFrames = 0;
  }

  bool update(PoseFrame frame, Exercise exercise) {
    final before = '$light$pose$stable';

    light = frame.brightness >= 45;
    pose = _poseDetected(frame, exercise);

    if (light && pose) {
      _stableFrames += 1;
    } else {
      _stableFrames = math.max(0, _stableFrames - 2);
    }
    stable = _stableFrames >= 5;

    final after = '$light$pose$stable';
    return before != after;
  }

  bool _poseDetected(PoseFrame frame, Exercise exercise) {
    if (exercise.side == ExerciseSide.front) {
      final shoulders =
          frame.has(PoseLandmarkType.leftShoulder, minLikelihood: 0.2) &&
          frame.has(PoseLandmarkType.rightShoulder, minLikelihood: 0.2);
      final arms =
          frame.has(PoseLandmarkType.leftElbow, minLikelihood: 0.15) ||
          frame.has(PoseLandmarkType.rightElbow, minLikelihood: 0.15) ||
          frame.has(PoseLandmarkType.leftWrist, minLikelihood: 0.15) ||
          frame.has(PoseLandmarkType.rightWrist, minLikelihood: 0.15);
      return shoulders && arms;
    }

    // Lebih toleran: minimal 3 dari 4 titik (bahu-pinggul-lutut-mata kaki)
    // terlihat, jadi badan tetap terdeteksi walau ujung kaki sedikit keluar frame.
    bool chain(
      PoseLandmarkType shoulder,
      PoseLandmarkType hip,
      PoseLandmarkType knee,
      PoseLandmarkType ankle,
    ) {
      final visible = [
        shoulder,
        hip,
        knee,
        ankle,
      ].where((type) => frame.has(type, minLikelihood: 0.15)).length;
      return frame.has(shoulder, minLikelihood: 0.15) &&
          frame.has(hip, minLikelihood: 0.15) &&
          visible >= 3;
    }

    return chain(
          PoseLandmarkType.leftShoulder,
          PoseLandmarkType.leftHip,
          PoseLandmarkType.leftKnee,
          PoseLandmarkType.leftAnkle,
        ) ||
        chain(
          PoseLandmarkType.rightShoulder,
          PoseLandmarkType.rightHip,
          PoseLandmarkType.rightKnee,
          PoseLandmarkType.rightAnkle,
        );
  }

  String? firstIssue(Exercise exercise) {
    if (!light) return 'Cahaya kurang, cari tempat lebih terang';
    if (!pose) {
      return exercise.side == ExerciseSide.front
          ? 'Pastikan badan bagian atas terlihat kamera'
          : 'Pastikan badanmu terlihat kamera';
    }
    if (!stable) return 'Tahan posisi sebentar';
    return null;
  }
}

class _ChecksPanel extends StatelessWidget {
  const _ChecksPanel({
    required this.checks,
    required this.exercise,
    required this.autoStarting,
    required this.onForceStart,
  });

  final _PoseChecks checks;
  final Exercise exercise;
  final bool autoStarting;
  final VoidCallback onForceStart;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          autoStarting ? 'Siap! Mulai otomatis...' : 'Menyiapkan posisi',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          autoStarting
              ? 'Semua pengecekan lolos. Bersiaplah.'
              : 'Arahkan kamera sampai semua centang hijau.',
          style: const TextStyle(
            fontSize: 13.5,
            color: AppColors.mutedForeground,
          ),
        ),
        const SizedBox(height: 14),
        _CheckRow(
          ok: checks.light,
          label: 'Pencahayaan cukup',
          hint: 'Hindari membelakangi jendela',
        ),
        _CheckRow(
          ok: checks.pose,
          label: 'Gerakan terdeteksi',
          hint: exercise.side == ExerciseSide.front
              ? 'Posisikan badan bagian atas di depan kamera'
              : 'Posisikan badan menyamping ke kamera',
        ),
        _CheckRow(
          ok: checks.stable,
          label: 'Deteksi stabil',
          hint: 'Tahan posisi sebentar',
        ),
        const SizedBox(height: 14),
        GlassButton(
          label: autoStarting ? 'Mulai' : 'Mulai paksa',
          variant: GlassButtonVariant.secondary,
          expand: true,
          onPressed: onForceStart,
        ),
      ],
    );
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({required this.ok, required this.label, required this.hint});

  final bool ok;
  final String label;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: ok ? AppColors.success : AppColors.muted,
              shape: BoxShape.circle,
            ),
            child: Icon(
              ok ? Icons.check_rounded : Icons.priority_high_rounded,
              size: 15,
              color: ok ? Colors.white : AppColors.mutedForeground,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: ok
                        ? AppColors.foreground
                        : AppColors.mutedForeground,
                  ),
                ),
                Text(
                  hint,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------- UI PARTS ----------------

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.name,
    this.subtitle,
    required this.phase,
    required this.paused,
    required this.poseWarning,
    required this.onFlip,
    required this.onClose,
  });

  final String name;
  final String? subtitle;
  final _Phase phase;
  final bool paused;
  final bool poseWarning;
  final VoidCallback onFlip;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final detecting = phase == _Phase.live && !paused;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 6, 6, 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty)
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          if (detecting)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: poseWarning ? AppColors.warning : AppColors.success,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  poseWarning ? 'Posisi kurang terlihat' : 'Deteksi aktif',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          _CircleDarkButton(
            icon: Icons.flip_camera_android_rounded,
            onTap: onFlip,
          ),
          const SizedBox(width: 6),
          _CircleDarkButton(icon: Icons.close_rounded, onTap: onClose),
        ],
      ),
    );
  }
}

class _CircleDarkButton extends StatelessWidget {
  const _CircleDarkButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _LiveControls extends StatelessWidget {
  const _LiveControls({
    required this.timed,
    required this.reps,
    required this.targetReps,
    required this.elapsed,
    required this.targetSeconds,
    required this.cue,
    required this.paused,
    required this.score,
    required this.onTogglePause,
    required this.onFinish,
  });

  final bool timed;
  final int reps;
  final int targetReps;
  final int elapsed;
  final int targetSeconds;
  final String cue;
  final bool paused;
  final int score;
  final VoidCallback onTogglePause;
  final VoidCallback onFinish;

  String get _timeLabel {
    final minutes = elapsed ~/ 60;
    final seconds = elapsed % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: Container(
            key: ValueKey(cue),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Text(
              cue,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (timed)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _timeLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 58,
                  fontWeight: FontWeight.w800,
                  height: 0.95,
                  letterSpacing: -2,
                ),
              ),
              Text(
                ' / ${targetSeconds}s',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          )
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              TweenAnimationBuilder<double>(
                key: ValueKey(reps),
                tween: Tween(begin: 1.15, end: 1),
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutBack,
                builder: (context, scale, child) =>
                    Transform.scale(scale: scale, child: child),
                child: Text(
                  '$reps',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 84,
                    fontWeight: FontWeight.w800,
                    height: 0.9,
                    letterSpacing: -3,
                  ),
                ),
              ),
              Text(
                ' / $targetReps',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        const SizedBox(height: 8),
        Text(
          timed ? 'Waktu tahan' : 'Repetisi',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  children: [
                    Text(
                      '$score',
                      style: const TextStyle(
                        color: AppColors.sky,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Skor form',
                      style: TextStyle(color: Colors.white70, fontSize: 10.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _DarkButton(
                  icon: paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                  label: paused ? 'Lanjut' : 'Jeda',
                  onTap: onTogglePause,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GlassButton(
                  label: 'Selesai',
                  icon: const Icon(Icons.check_rounded),
                  expand: true,
                  onPressed: onFinish,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          "Katakan 'jeda' atau 'berhenti'",
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _DarkButton extends StatelessWidget {
  const _DarkButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        height: 54,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 7),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountdownOverlay extends StatelessWidget {
  const _CountdownOverlay({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: AppColors.cam.withValues(alpha: 0.5),
        child: Center(
          child: TweenAnimationBuilder<double>(
            key: ValueKey(count),
            tween: Tween(begin: 1.3, end: 1),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutBack,
            builder: (context, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 140,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomPanel extends StatelessWidget {
  const _BottomPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Column(
        children: [
          Expanded(
            child: ColoredBox(color: AppColors.navy.withValues(alpha: 0.32)),
          ),
          Container(
            width: double.infinity,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.72,
            ),
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.mutedForeground.withValues(
                          alpha: 0.28,
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

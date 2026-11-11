import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/services/ai_service.dart';
import '../../core/services/tts_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_background.dart';
import '../../core/widgets/glass_button.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/pain_slider.dart';
import '../../data/mock_data.dart';
import '../../data/models/session_result.dart';
import '../../state/app_state.dart';

class SummaryScreen extends ConsumerStatefulWidget {
  const SummaryScreen({super.key});

  @override
  ConsumerState<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends ConsumerState<SummaryScreen> {
  bool _playing = false;
  int _painAfter = 2;

  String _summary =
      'Gerakanmu stabil dari awal sampai akhir. Skor form naik 4 poin dari sesi lalu. Di set terakhir kedalaman squat mulai berkurang.';
  String _tip = 'Tips: dorong pinggul ke belakang seperti mau duduk.';
  bool _loadingAi = false;

  @override
  void initState() {
    super.initState();
    _loadAiSummary();
  }

  Future<void> _loadAiSummary() async {
    final result = ref.read(lastSessionProvider);
    if (result == null) return;
    setState(() => _loadingAi = true);
    final aiResult = await AiService.generateSummary(result);
    if (!mounted) return;
    setState(() {
      _summary = aiResult.summary;
      _tip = aiResult.tip;
      _loadingAi = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(appModeProvider);
    final workout = mode == AppMode.workout;
    final result =
        ref.watch(lastSessionProvider) ??
        SessionResult.sample(MockData.exerciseById('squat'));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                Center(
                  child: _CelebrationRing(
                    icon: workout ? Icons.check_rounded : Icons.check_rounded,
                  ),
                ),
                const SizedBox(height: 18),
                const Center(
                  child: Text(
                    'Sesi selesai',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.7,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: workout
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.local_fire_department_rounded,
                              size: 18,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Streak ${result.streakDays} hari',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        )
                      : const Text(
                          'Kerja bagus. Terapismu akan melihat hasil ini.',
                          style: TextStyle(color: AppColors.mutedForeground),
                        ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    _StatCard(value: '${result.reps}', label: 'Rep'),
                    const SizedBox(width: 12),
                    _StatCard(value: '${result.score}', label: 'Skor form'),
                    const SizedBox(width: 12),
                    _StatCard(value: result.durationLabel, label: 'Durasi'),
                  ],
                ),
                const SizedBox(height: 16),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Kesalahan yang sering muncul',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.mutedForeground,
                        ),
                      ),
                      const SizedBox(height: 14),
                      for (final error in result.errors) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                error.label,
                                style: const TextStyle(fontSize: 14.5),
                              ),
                            ),
                            Text(
                              '${error.count}×',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.warning,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_loadingAi)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              ),
                              SizedBox(width: 10),
                              Text(
                                'AI sedang menganalisis sesi...',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.mutedForeground,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        )
                      else ...[
                        Text(
                          _summary,
                          style: const TextStyle(fontSize: 15, height: 1.55),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.lightbulb_outline_rounded,
                              size: 17,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _tip,
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  height: 1.4,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),
                      GlassButton(
                        label: _playing ? 'Memutar...' : 'Dengarkan',
                        variant: GlassButtonVariant.secondary,
                        icon: const Icon(Icons.volume_up_rounded),
                        onPressed: _loadingAi ? null : _toggleSpeak,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (workout)
                  _RewardCard(
                    badge: result.newBadge ?? 'Badge baru',
                    xp: result.xpEarned,
                  )
                else
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Setelah sesi',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        PainSlider(
                          value: _painAfter,
                          onChanged: (value) =>
                              setState(() => _painAfter = value),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),
                GlassButton(
                  label: 'Kembali ke Beranda',
                  size: GlassButtonSize.large,
                  expand: true,
                  onPressed: () => context.go(AppRoutes.home),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _toggleSpeak() {
    if (_playing) {
      unawaited(TtsService.instance.stop());
      setState(() => _playing = false);
      return;
    }
    setState(() => _playing = true);
    unawaited(
      TtsService.instance.init().then((_) async {
        await TtsService.instance.speak('$_summary $_tip');
        if (mounted) setState(() => _playing = false);
      }),
    );
  }
}

class _CelebrationRing extends StatefulWidget {
  const _CelebrationRing({required this.icon});

  final IconData icon;

  @override
  State<_CelebrationRing> createState() => _CelebrationRingState();
}

class _CelebrationRingState extends State<_CelebrationRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox(
          width: 96,
          height: 96,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(96, 96),
                painter: _ArcPainter(progress: _controller.value),
              ),
              Transform.scale(
                scale: Curves.elasticOut.transform(
                  _controller.value.clamp(0.4, 1),
                ),
                child: child,
              ),
            ],
          ),
        );
      },
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primary.withValues(alpha: 0.12),
        ),
        child: Icon(widget.icon, size: 34, color: AppColors.primary),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  const _ArcPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..color = AppColors.primary;
    canvas.drawArc(rect.deflate(3), -1.5708, 6.2832 * progress, false, paint);
  }

  @override
  bool shouldRepaint(covariant _ArcPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  const _RewardCard({required this.badge, required this.xp});

  final String badge;
  final int xp;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF60A5FA), AppColors.primary],
              ),
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: Colors.white,
              size: 27,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Badge baru',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mutedForeground,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  badge,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '+$xp XP',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

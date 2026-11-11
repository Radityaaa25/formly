import 'dart:math' as math;

import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import 'pose_frame.dart';

class AnalyzerOutput {
  const AnalyzerOutput({
    required this.poseValid,
    required this.reps,
    this.repCompleted = false,
    this.repScore,
    this.repErrors = const [],
    this.liveCue,
    this.quality = 0,
  });

  final bool poseValid;
  final int reps;
  final bool repCompleted;
  final int? repScore;
  final List<String> repErrors;
  final String? liveCue;
  final double quality;
}

abstract class ExerciseAnalyzer {
  int reps = 0;
  double _scoreSum = 0;
  int _scoreCount = 0;
  List<String> _recentErrors = const [];

  double get averageScore => _scoreCount == 0 ? 0 : _scoreSum / _scoreCount;

  List<String> get recentErrors => _recentErrors;

  void recordRep(int score, List<String> errors) {
    reps += 1;
    _scoreSum += score;
    _scoreCount += 1;
    _recentErrors = errors;
  }

  AnalyzerOutput update(PoseFrame frame);

  void reset() {
    reps = 0;
    _scoreSum = 0;
    _scoreCount = 0;
    _recentErrors = const [];
  }

  AnalyzerOutput invalid() =>
      AnalyzerOutput(poseValid: false, reps: reps, quality: 0);

  static ExerciseAnalyzer forExercise(String id) {
    return switch (id) {
      'squat' => _SquatAnalyzer(),
      'knee' => _SquatAnalyzer(
        downAngle: 125,
        targetDepth: 118,
        kneeHint: 'Tekuk lutut lebih dalam',
      ),
      'lunge' => _LungeAnalyzer(),
      'pushup' => _PushupAnalyzer(),
      'bridge' => _BridgeAnalyzer(),
      'arm' => _ArmAnalyzer(),
      'shoulder' => _ShoulderAnalyzer(),
      'plank' => _PlankAnalyzer(),
      _ => _SquatAnalyzer(),
    };
  }
}

class _Side {
  const _Side({
    required this.shoulder,
    required this.hip,
    required this.knee,
    required this.ankle,
    this.elbow,
    this.wrist,
  });

  final PosePoint shoulder;
  final PosePoint hip;
  final PosePoint knee;
  final PosePoint ankle;
  final PosePoint? elbow;
  final PosePoint? wrist;
}

_Side? _pickSide(PoseFrame frame) {
  _Side? build({
    required PoseLandmarkType shoulder,
    required PoseLandmarkType hip,
    required PoseLandmarkType knee,
    required PoseLandmarkType ankle,
    required PoseLandmarkType elbow,
    required PoseLandmarkType wrist,
  }) {
    final s = frame.point(shoulder, minLikelihood: 0.2);
    final h = frame.point(hip, minLikelihood: 0.2);
    final k = frame.point(knee, minLikelihood: 0.2);
    final a = frame.point(ankle, minLikelihood: 0.15);
    if (s == null || h == null || k == null || a == null) return null;
    final score = h.likelihood + k.likelihood + a.likelihood + s.likelihood;
    if (score < 1.2) return null;
    return _Side(
      shoulder: s,
      hip: h,
      knee: k,
      ankle: a,
      elbow: frame.point(elbow),
      wrist: frame.point(wrist),
    );
  }

  final left = build(
    shoulder: PoseLandmarkType.leftShoulder,
    hip: PoseLandmarkType.leftHip,
    knee: PoseLandmarkType.leftKnee,
    ankle: PoseLandmarkType.leftAnkle,
    elbow: PoseLandmarkType.leftElbow,
    wrist: PoseLandmarkType.leftWrist,
  );
  final right = build(
    shoulder: PoseLandmarkType.rightShoulder,
    hip: PoseLandmarkType.rightHip,
    knee: PoseLandmarkType.rightKnee,
    ankle: PoseLandmarkType.rightAnkle,
    elbow: PoseLandmarkType.rightElbow,
    wrist: PoseLandmarkType.rightWrist,
  );

  if (left == null) return right;
  if (right == null) return left;
  final leftScore =
      left.hip.likelihood + left.knee.likelihood + left.ankle.likelihood;
  final rightScore =
      right.hip.likelihood + right.knee.likelihood + right.ankle.likelihood;
  return leftScore >= rightScore ? left : right;
}

class _SquatAnalyzer extends ExerciseAnalyzer {
  _SquatAnalyzer({
    this.downAngle = 105,
    this.targetDepth = 100,
    this.kneeHint = 'Turun sedikit lagi',
    this.badTorsoCue = 'Badan terlalu condong ke depan',
  });

  final double downAngle;
  final double targetDepth;
  final String kneeHint;
  final String badTorsoCue;

  static const double _upAngle = 160;
  static const double _maxTorsoLean = 60;

  bool _down = false;
  double _minAngle = 180;
  bool _badTorso = false;
  int _badLeanRun = 0;
  int _maxBadLeanRun = 0;

  /// Sudut kemiringan torso terhadap sumbu vertikal (0 = tegak).
  /// Lebih stabil daripada sudut pinggul untuk mendeteksi bungkuk.
  double _torsoLean(_Side side) {
    final dx = side.shoulder.x - side.hip.x;
    final dy = side.shoulder.y - side.hip.y;
    if (dy >= 0) return 90;
    return math.atan2(dx.abs(), -dy) * 180 / math.pi;
  }

  @override
  AnalyzerOutput update(PoseFrame frame) {
    final side = _pickSide(frame);
    if (side == null) return invalid();

    final knee = angleDeg(side.hip, side.knee, side.ankle);
    final lean = _torsoLean(side);
    final excessiveLean = lean > _maxTorsoLean;

    String? cue;

    if (!_down) {
      if (knee <= downAngle) {
        _down = true;
        _minAngle = knee;
        _badTorso = false;
        _badLeanRun = excessiveLean ? 1 : 0;
        _maxBadLeanRun = _badLeanRun;
      } else if (knee < _upAngle - 8) {
        cue = kneeHint;
      }
    } else {
      if (knee < _minAngle) _minAngle = knee;

      if (excessiveLean) {
        _badLeanRun += 1;
        if (_badLeanRun > _maxBadLeanRun) _maxBadLeanRun = _badLeanRun;
      } else {
        _badLeanRun = 0;
      }

      if (knee >= _upAngle) {
        final errors = <String>[];
        if (_minAngle > targetDepth) {
          errors.add('Kurang dalam saat turun');
        }
        // Butuh beberapa frame berturut-turut agar tidak salah deteksi.
        _badTorso = _maxBadLeanRun >= 4;
        if (_badTorso) errors.add(badTorsoCue);
        final score = (100 - errors.length * 18).clamp(40, 100);
        _down = false;
        _badLeanRun = 0;
        _maxBadLeanRun = 0;
        recordRep(score, errors);
        return AnalyzerOutput(
          poseValid: true,
          reps: reps,
          repCompleted: true,
          repScore: score,
          repErrors: errors,
          quality: score.toDouble(),
        );
      } else if (knee > downAngle + 6 && knee > _minAngle + 8) {
        cue = kneeHint;
      } else if (_minAngle <= targetDepth && !excessiveLean) {
        cue = 'Bagus, pertahankan';
      }
    }

    final quality =
        (100 - (_minAngle > targetDepth ? 15 : 0) - (_badTorso ? 12 : 0)).clamp(
          40,
          100,
        );
    return AnalyzerOutput(
      poseValid: true,
      reps: reps,
      liveCue: cue,
      quality: quality.toDouble(),
    );
  }

  @override
  void reset() {
    super.reset();
    _down = false;
    _minAngle = 180;
    _badTorso = false;
    _badLeanRun = 0;
    _maxBadLeanRun = 0;
  }
}

class _LungeAnalyzer extends _SquatAnalyzer {
  _LungeAnalyzer()
    : super(
        downAngle: 110,
        targetDepth: 105,
        kneeHint: 'Turun lebih dalam',
        badTorsoCue: 'Badan tetap tegak',
      );
}

class _PushupAnalyzer extends ExerciseAnalyzer {
  static const double _downAngle = 100;
  static const double _upAngle = 155;
  bool _down = false;
  double _minElbow = 180;
  bool _badBody = false;

  @override
  AnalyzerOutput update(PoseFrame frame) {
    final side = _pickSide(frame);
    if (side == null || side.elbow == null || side.wrist == null) {
      return invalid();
    }

    final elbow = angleDeg(side.shoulder, side.elbow!, side.wrist!);
    final body = angleDeg(side.shoulder, side.hip, side.ankle);
    String? cue;

    if (!_down) {
      if (elbow <= _downAngle) {
        _down = true;
        _minElbow = elbow;
        _badBody = body < 155;
      } else if (elbow < _upAngle - 8) {
        cue = 'Turun lebih dalam';
      }
    } else {
      if (elbow < _minElbow) _minElbow = elbow;
      if (body < 155) _badBody = true;

      if (elbow >= _upAngle) {
        final errors = <String>[];
        if (_minElbow > 110) errors.add('Kurang dalam saat turun');
        if (_badBody) errors.add('Badan kurang lurus');
        final score = (100 - errors.length * 18).clamp(40, 100);
        _down = false;
        recordRep(score, errors);
        return AnalyzerOutput(
          poseValid: true,
          reps: reps,
          repCompleted: true,
          repScore: score,
          repErrors: errors,
          quality: score.toDouble(),
        );
      } else if (body < 155) {
        cue = 'Badan tetap lurus';
      }
    }

    return AnalyzerOutput(
      poseValid: true,
      reps: reps,
      liveCue: cue,
      quality: (_badBody ? 78 : 95).toDouble(),
    );
  }

  @override
  void reset() {
    super.reset();
    _down = false;
    _minElbow = 180;
    _badBody = false;
  }
}

class _BridgeAnalyzer extends ExerciseAnalyzer {
  static const double _upAngle = 160;
  static const double _downAngle = 125;
  bool _up = false;
  double _maxAngle = 0;
  String? _cue;

  @override
  AnalyzerOutput update(PoseFrame frame) {
    final side = _pickSide(frame);
    if (side == null) return invalid();

    final hip = angleDeg(side.shoulder, side.hip, side.knee);
    if (!_up) {
      if (hip >= _upAngle) {
        _up = true;
        _maxAngle = hip;
        _cue = 'Tahan sebentar';
      } else if (hip > 135) {
        _cue = 'Angkat pinggul lebih tinggi';
      } else {
        _cue = null;
      }
    } else {
      if (hip > _maxAngle) _maxAngle = hip;
      if (hip <= _downAngle) {
        final errors = <String>[];
        if (_maxAngle < 165) errors.add('Angkat pinggul lebih tinggi');
        final score = (100 - errors.length * 20).clamp(50, 100);
        _up = false;
        _maxAngle = 0;
        recordRep(score, errors);
        return AnalyzerOutput(
          poseValid: true,
          reps: reps,
          repCompleted: true,
          repScore: score,
          repErrors: errors,
          quality: score.toDouble(),
        );
      }
      _cue = 'Dorong lewat tumit';
    }

    return AnalyzerOutput(
      poseValid: true,
      reps: reps,
      liveCue: _cue,
      quality: (_up ? 92 : 82).toDouble(),
    );
  }

  @override
  void reset() {
    super.reset();
    _up = false;
    _maxAngle = 0;
    _cue = null;
  }
}

class _ArmAnalyzer extends ExerciseAnalyzer {
  static const double _upAngle = 150;
  static const double _downAngle = 40;
  bool _up = false;
  double _maxAngle = 0;
  bool _asymmetric = false;

  @override
  AnalyzerOutput update(PoseFrame frame) {
    // Pilih sisi dengan confidence terbaik untuk sudut lengan.
    PosePoint? pick(
      PoseLandmarkType shoulder,
      PoseLandmarkType hip,
      PoseLandmarkType elbow,
    ) {
      final s = frame.point(shoulder);
      final h = frame.point(hip);
      final e = frame.point(elbow);
      if (s == null || h == null || e == null) return null;
      return e;
    }

    final leftElbow = pick(
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.leftHip,
      PoseLandmarkType.leftElbow,
    );
    final rightElbow = pick(
      PoseLandmarkType.rightShoulder,
      PoseLandmarkType.rightHip,
      PoseLandmarkType.rightElbow,
    );
    if (leftElbow == null && rightElbow == null) return invalid();

    double angleFor(
      PoseLandmarkType shoulder,
      PoseLandmarkType hip,
      PoseLandmarkType elbow,
    ) {
      final s = frame.point(shoulder);
      final h = frame.point(hip);
      final e = frame.point(elbow);
      if (s == null || h == null || e == null) return 0;
      return angleDeg(h, s, e);
    }

    final leftAngle = angleFor(
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.leftHip,
      PoseLandmarkType.leftElbow,
    );
    final rightAngle = angleFor(
      PoseLandmarkType.rightShoulder,
      PoseLandmarkType.rightHip,
      PoseLandmarkType.rightElbow,
    );
    final angle = math.max(leftAngle, rightAngle);

    if (leftElbow != null && rightElbow != null) {
      _asymmetric = (leftAngle - rightAngle).abs() > 30;
    }

    String? cue;
    if (!_up) {
      if (angle >= _upAngle) {
        _up = true;
        _maxAngle = angle;
      } else if (angle > 90) {
        cue = 'Angkat lebih tinggi';
      }
    } else {
      if (angle > _maxAngle) _maxAngle = angle;
      if (angle <= _downAngle) {
        final errors = <String>[];
        if (_maxAngle < 160) errors.add('Lengan kurang tinggi');
        if (_asymmetric) errors.add('Lengan tidak simetris');
        final score = (100 - errors.length * 18).clamp(50, 100);
        _up = false;
        _maxAngle = 0;
        recordRep(score, errors);
        return AnalyzerOutput(
          poseValid: true,
          reps: reps,
          repCompleted: true,
          repScore: score,
          repErrors: errors,
          quality: score.toDouble(),
        );
      }
      cue = 'Turunkan perlahan';
    }

    return AnalyzerOutput(
      poseValid: true,
      reps: reps,
      liveCue: cue,
      quality: 92,
    );
  }

  @override
  void reset() {
    super.reset();
    _up = false;
    _maxAngle = 0;
    _asymmetric = false;
  }
}

class _ShoulderAnalyzer extends ExerciseAnalyzer {
  bool _up = false;
  String? _cue;

  @override
  AnalyzerOutput update(PoseFrame frame) {
    final side = _pickSide(frame);
    if (side == null || side.wrist == null) return invalid();

    final torso = distance(side.shoulder, side.hip);
    if (torso < 0.05) return invalid();
    final delta = (side.shoulder.y - side.wrist!.y) / torso;

    if (!_up) {
      if (delta > 0.15) {
        _up = true;
        _cue = 'Bagus, lanjutkan putaran';
      } else {
        _cue = 'Angkat lengan membentuk lingkaran';
      }
    } else {
      if (delta < -0.02) {
        _up = false;
        recordRep(95, const []);
        return AnalyzerOutput(
          poseValid: true,
          reps: reps,
          repCompleted: true,
          repScore: 95,
          repErrors: const [],
          quality: 95,
        );
      }
      _cue = 'Lingkaran kecil dulu';
    }

    return AnalyzerOutput(
      poseValid: true,
      reps: reps,
      liveCue: _cue,
      quality: 90,
    );
  }

  @override
  void reset() {
    super.reset();
    _up = false;
    _cue = null;
  }
}

class _PlankAnalyzer extends ExerciseAnalyzer {
  @override
  AnalyzerOutput update(PoseFrame frame) {
    final side = _pickSide(frame);
    if (side == null) return invalid();

    final body = angleDeg(side.shoulder, side.hip, side.ankle);
    final expectedHipY =
        side.shoulder.y +
        (side.ankle.y - side.shoulder.y) *
            ((side.hip.x - side.shoulder.x) /
                ((side.ankle.x - side.shoulder.x) == 0
                    ? 0.0001
                    : (side.ankle.x - side.shoulder.x)));
    final verticalError = side.hip.y - expectedHipY;

    String? cue;
    if (verticalError > 0.035) {
      cue = 'Pinggul terlalu turun';
    } else if (verticalError < -0.035) {
      cue = 'Pinggul terlalu tinggi';
    } else if (body < 160) {
      cue = 'Tarik perut, badan lurus';
    }

    final quality = (100 - (verticalError.abs() * 400)).clamp(45, 100);
    return AnalyzerOutput(
      poseValid: true,
      reps: reps,
      liveCue: cue,
      quality: quality.toDouble(),
    );
  }
}

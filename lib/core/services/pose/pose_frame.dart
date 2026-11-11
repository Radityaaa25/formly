import 'dart:math' as math;
import 'dart:ui';

import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PosePoint {
  const PosePoint(this.x, this.y, this.likelihood);

  /// Koordinat ternormalisasi (0..1) terhadap gambar.
  final double x;
  final double y;
  final double likelihood;

  Offset get offset => Offset(x, y);
}

class PoseFrame {
  PoseFrame({
    required this.landmarks,
    required this.brightness,
    required this.imageSize,
  });

  final Map<PoseLandmarkType, PoseLandmark> landmarks;

  /// Rata-rata kecerahan frame (0..255).
  final double brightness;
  final Size imageSize;

  PosePoint? point(PoseLandmarkType type, {double minLikelihood = 0.35}) {
    final landmark = landmarks[type];
    if (landmark == null || landmark.likelihood < minLikelihood) return null;
    return PosePoint(landmark.x, landmark.y, landmark.likelihood);
  }

  bool has(PoseLandmarkType type, {double minLikelihood = 0.35}) {
    final l = landmarks[type];
    return l != null && l.likelihood >= minLikelihood;
  }

  double likelihoodOf(PoseLandmarkType type) =>
      landmarks[type]?.likelihood ?? 0;

  factory PoseFrame.fromPose(Pose pose, double brightness, Size imageSize) {
    final map = <PoseLandmarkType, PoseLandmark>{};
    pose.landmarks.forEach((type, landmark) {
      map[type] = landmark;
    });
    return PoseFrame(
      landmarks: map,
      brightness: brightness,
      imageSize: imageSize,
    );
  }
}

/// Sudut (derajat) di titik [b] yang dibentuk oleh [a]-[b]-[c].
double angleDeg(PosePoint a, PosePoint b, PosePoint c) {
  final abx = a.x - b.x;
  final aby = a.y - b.y;
  final cbx = c.x - b.x;
  final cby = c.y - b.y;
  final dot = abx * cbx + aby * cby;
  final magA = math.sqrt(abx * abx + aby * aby);
  final magC = math.sqrt(cbx * cbx + cby * cby);
  if (magA == 0 || magC == 0) return 180;
  final cosine = (dot / (magA * magC)).clamp(-1.0, 1.0);
  return math.acos(cosine) * 180 / math.pi;
}

double distance(PosePoint a, PosePoint b) {
  final dx = a.x - b.x;
  final dy = a.y - b.y;
  return math.sqrt(dx * dx + dy * dy);
}

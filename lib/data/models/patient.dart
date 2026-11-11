import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

enum PatientStatus { routine, needsAttention, inactive }

extension PatientStatusLabel on PatientStatus {
  String get label => switch (this) {
    PatientStatus.routine => 'Rutin',
    PatientStatus.needsAttention => 'Perlu perhatian',
    PatientStatus.inactive => 'Tidak aktif',
  };

  Color get color => switch (this) {
    PatientStatus.routine => AppColors.success,
    PatientStatus.needsAttention => AppColors.warning,
    PatientStatus.inactive => AppColors.mutedForeground,
  };

  Color get background => switch (this) {
    PatientStatus.routine => AppColors.success.withValues(alpha: 0.12),
    PatientStatus.needsAttention => AppColors.warning.withValues(alpha: 0.15),
    PatientStatus.inactive => AppColors.muted,
  };
}

class Patient {
  const Patient({
    required this.id,
    required this.name,
    required this.condition,
    required this.status,
    required this.adherence,
    required this.lastSession,
    required this.scores,
    required this.errors,
  });

  final String id;
  final String name;
  final String condition;
  final PatientStatus status;
  final int adherence;
  final String lastSession;
  final List<int> scores;
  final List<String> errors;

  String get initials => name
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => part[0])
      .take(2)
      .join();
}

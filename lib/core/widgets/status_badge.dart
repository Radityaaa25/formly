import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum StatusTone { success, warning, muted, primary }

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    this.tone = StatusTone.primary,
    this.color,
    this.background,
  });

  final String label;
  final StatusTone tone;
  final Color? color;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final resolvedColor = color ?? _toneColor;
    final resolvedBackground = background ?? _toneBackground;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: resolvedBackground,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: resolvedColor,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          height: 1.1,
        ),
      ),
    );
  }

  Color get _toneColor => switch (tone) {
    StatusTone.success => AppColors.success,
    StatusTone.warning => AppColors.warning,
    StatusTone.muted => AppColors.mutedForeground,
    StatusTone.primary => AppColors.primary,
  };

  Color get _toneBackground => switch (tone) {
    StatusTone.success => AppColors.success.withValues(alpha: 0.12),
    StatusTone.warning => AppColors.warning.withValues(alpha: 0.15),
    StatusTone.muted => AppColors.muted,
    StatusTone.primary => AppColors.primary.withValues(alpha: 0.10),
  };
}

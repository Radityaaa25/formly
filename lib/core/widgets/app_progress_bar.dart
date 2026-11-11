import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AppProgressBar extends StatelessWidget {
  const AppProgressBar({super.key, required this.value, required this.max});

  final num value;
  final num max;

  @override
  Widget build(BuildContext context) {
    final target = max <= 0 ? 0.0 : (value / max).clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 10,
        color: AppColors.accent,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: target),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          builder: (context, progress, _) {
            return FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryDeep, AppColors.primary],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

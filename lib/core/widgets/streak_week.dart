import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class StreakWeek extends StatelessWidget {
  const StreakWeek({super.key, required this.active, this.today = 5});

  final List<bool> active;
  final int today;

  static const _labels = ['S', 'S', 'R', 'K', 'J', 'S', 'M'];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var i = 0; i < _labels.length; i++)
          Column(
            children: [
              Text(
                _labels[i],
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mutedForeground,
                ),
              ),
              const SizedBox(height: 7),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < active.length && active[i]
                      ? AppColors.primary
                      : i == today
                      ? AppColors.sky.withValues(alpha: 0.16)
                      : AppColors.accent,
                  border: i == today && !(i < active.length && active[i])
                      ? Border.all(color: AppColors.sky, width: 2)
                      : null,
                  boxShadow: i < active.length && active[i]
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

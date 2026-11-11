import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'glass_card.dart';

class BadgeTile extends StatelessWidget {
  const BadgeTile({super.key, required this.label, required this.unlocked});

  final String label;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: unlocked ? 1 : 0.55,
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        radius: 22,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: unlocked ? AppColors.primary : AppColors.muted,
                gradient: unlocked
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF60A5FA), AppColors.primary],
                      )
                    : null,
              ),
              child: Icon(
                unlocked ? Icons.workspace_premium_rounded : Icons.lock_rounded,
                size: unlocked ? 25 : 20,
                color: unlocked ? Colors.white : AppColors.mutedForeground,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

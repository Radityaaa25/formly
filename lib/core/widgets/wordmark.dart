import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class Wordmark extends StatelessWidget {
  const Wordmark({super.key, this.fontSize = 26});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: 'formly',
        style: TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.2,
          color: AppColors.foreground,
        ),
        children: [
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: Padding(
              padding: const EdgeInsets.only(left: 3, bottom: 2),
              child: Container(
                width: fontSize * 0.22,
                height: fontSize * 0.22,
                decoration: const BoxDecoration(
                  color: AppColors.sky,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

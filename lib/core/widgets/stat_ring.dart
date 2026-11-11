import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class StatRing extends StatelessWidget {
  const StatRing({
    super.key,
    required this.value,
    required this.max,
    this.size = 96,
    this.stroke = 9,
    this.child,
  });

  final num value;
  final num max;
  final double size;
  final double stroke;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final target = max <= 0 ? 0.0 : (value / max).clamp(0.0, 1.0);
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: target),
        duration: const Duration(milliseconds: 950),
        curve: Curves.easeOutCubic,
        builder: (context, progress, _) {
          return Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
                painter: _RingPainter(progress: progress, stroke: stroke),
              ),
              if (child != null) Center(child: child),
            ],
          );
        },
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.progress, required this.stroke});

  final double progress;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = (math.min(size.width, size.height) - stroke) / 2;
    final center = size.center(Offset.zero);

    final background = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = AppColors.accent;
    canvas.drawCircle(center, radius, background);

    if (progress <= 0) return;

    final foreground = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = AppColors.primary;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      foreground,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.stroke != stroke;
}

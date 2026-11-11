import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class SkeletonFigure extends StatefulWidget {
  const SkeletonFigure({
    super.key,
    this.color = AppColors.sky,
    this.animate = true,
  });

  final Color color;
  final bool animate;

  @override
  State<SkeletonFigure> createState() => _SkeletonFigureState();
}

class _SkeletonFigureState extends State<SkeletonFigure>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    if (widget.animate) _controller.repeat(reverse: true);
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
      builder: (context, _) {
        final offset = (widget.animate ? (_controller.value - 0.5) : 0.0) * 16;
        return Transform.translate(
          offset: Offset(0, offset),
          child: CustomPaint(
            painter: _SkeletonPainter(color: widget.color),
            size: const Size(200, 320),
          ),
        );
      },
    );
  }
}

class _SkeletonPainter extends CustomPainter {
  const _SkeletonPainter({required this.color});

  final Color color;

  static const List<List<double>> _bones = [
    [100, 60, 100, 150],
    [100, 80, 65, 120],
    [65, 120, 55, 160],
    [100, 80, 135, 120],
    [135, 120, 145, 160],
    [100, 150, 75, 215],
    [75, 215, 80, 290],
    [100, 150, 125, 215],
    [125, 215, 120, 290],
  ];

  static const List<List<double>> _joints = [
    [100, 80],
    [65, 120],
    [55, 160],
    [135, 120],
    [145, 160],
    [100, 150],
    [75, 215],
    [80, 290],
    [125, 215],
    [120, 290],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 200;
    final sy = size.height / 320;
    Offset point(double x, double y) => Offset(x * sx, y * sy);

    final glow = Paint()
      ..color = color.withValues(alpha: 0.55)
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    final stroke = Paint()
      ..color = color
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (final bone in _bones) {
      final a = point(bone[0], bone[1]);
      final b = point(bone[2], bone[3]);
      canvas.drawLine(a, b, glow);
      canvas.drawLine(a, b, stroke);
    }

    final headCenter = point(100, 38);
    final headRadius = 16 * ((sx + sy) / 2);
    canvas.drawCircle(
      headCenter,
      headRadius,
      glow..style = PaintingStyle.stroke,
    );
    canvas.drawCircle(headCenter, headRadius, stroke);

    final jointFill = Paint()..color = AppColors.camForeground;
    final jointStroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    final jointGlow = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    for (final joint in _joints) {
      final center = point(joint[0], joint[1]);
      canvas.drawCircle(center, 6, jointGlow);
      canvas.drawCircle(center, 5, jointFill);
      canvas.drawCircle(center, 5, jointStroke);
    }
  }

  @override
  bool shouldRepaint(covariant _SkeletonPainter oldDelegate) =>
      oldDelegate.color != color;
}

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AppBackground extends StatefulWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  @override
  State<AppBackground> createState() => _AppBackgroundState();
}

class _AppBackgroundState extends State<AppBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.background,
      child: AnimatedBuilder(
        animation: _controller,
        child: widget.child,
        builder: (context, child) {
          final t = _controller.value * math.pi * 2;
          return Stack(
            fit: StackFit.expand,
            children: [
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFEAF3FF),
                      AppColors.background,
                      Colors.white,
                    ],
                    stops: [0, 0.45, 1],
                  ),
                ),
              ),
              IgnorePointer(
                child: Stack(
                  children: [
                    Positioned(
                      left: -80,
                      top: -60,
                      child: Transform.translate(
                        offset: Offset(math.sin(t) * 12, math.cos(t) * 14),
                        child: const _Blob(size: 320, color: Color(0x3538BDF8)),
                      ),
                    ),
                    Positioned(
                      right: -100,
                      top: 240,
                      child: Transform.translate(
                        offset: Offset(
                          math.cos(t + 2) * 14,
                          math.sin(t + 1) * 18,
                        ),
                        child: const _Blob(size: 340, color: Color(0x1A2563EB)),
                      ),
                    ),
                    Positioned(
                      left: 20,
                      bottom: -90,
                      child: Transform.translate(
                        offset: Offset(
                          math.sin(t + 4) * 16,
                          math.cos(t + 3) * 12,
                        ),
                        child: const _Blob(size: 300, color: Color(0x2838BDF8)),
                      ),
                    ),
                  ],
                ),
              ),
              child ?? const SizedBox.shrink(),
            ],
          );
        },
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0.0)],
          stops: const [0.0, 1.0],
        ),
      ),
    );
  }
}

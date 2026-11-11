import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class GlassCard extends StatefulWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin,
    this.radius = 22,
    this.color,
    this.borderColor,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final Color? color;
  final Color? borderColor;
  final VoidCallback? onTap;

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(widget.radius);

    final cardBody = Container(
      padding: widget.padding,
      decoration: BoxDecoration(
        color: widget.color ?? Colors.white,
        borderRadius: borderRadius,
        border: Border.all(
          color: widget.borderColor ?? AppColors.border,
          width: 1.5,
        ),
      ),
      child: Material(type: MaterialType.transparency, child: widget.child),
    );

    return AnimatedScale(
      scale: _pressed ? 0.98 : 1,
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOut,
      child: Container(
        margin: widget.margin,
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          boxShadow: [
            BoxShadow(
              color: AppColors.foreground.withValues(
                alpha: _pressed ? 0.04 : 0.07,
              ),
              blurRadius: 0,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: AppColors.foreground.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: widget.onTap == null
            ? cardBody
            : Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: borderRadius,
                  onHighlightChanged: (value) {
                    if (mounted) setState(() => _pressed = value);
                  },
                  onTap: widget.onTap,
                  child: cardBody,
                ),
              ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum GlassButtonVariant { primary, secondary, danger }

enum GlassButtonSize { medium, large }

class GlassButton extends StatefulWidget {
  const GlassButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = GlassButtonVariant.primary,
    this.size = GlassButtonSize.medium,
    this.expand = false,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final GlassButtonVariant variant;
  final GlassButtonSize size;
  final bool expand;
  final bool loading;

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null && !widget.loading;

  @override
  Widget build(BuildContext context) {
    final height = widget.size == GlassButtonSize.large ? 56.0 : 48.0;
    final textColor = switch (widget.variant) {
      GlassButtonVariant.primary => Colors.white,
      GlassButtonVariant.secondary => AppColors.primaryDeep,
      GlassButtonVariant.danger => AppColors.destructive,
    };
    final borderRadius = BorderRadius.circular(18);

    Widget body;
    if (widget.variant == GlassButtonVariant.primary) {
      body = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primaryLight, AppColors.primary],
          ),
          border: Border.all(
            color: AppColors.primaryDeep.withValues(alpha: 0.35),
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: borderRadius,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.center,
                      colors: [Color(0x3DFFFFFF), Color(0x00FFFFFF)],
                    ),
                  ),
                ),
              ),
            ),
            Center(child: _buildContent(textColor)),
          ],
        ),
      );
    } else {
      body = Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius,
          border: Border.all(
            color: widget.variant == GlassButtonVariant.danger
                ? AppColors.destructive.withValues(alpha: 0.35)
                : AppColors.border,
            width: 1.6,
          ),
        ),
        child: _buildContent(textColor),
      );
    }

    return Opacity(
      opacity: _enabled ? 1 : 0.5,
      child: AnimatedSlide(
        offset: _pressed ? const Offset(0, 0.05) : Offset.zero,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        child: Container(
          height: height,
          width: widget.expand ? double.infinity : null,
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            boxShadow: widget.variant == GlassButtonVariant.primary
                ? [
                    const BoxShadow(
                      color: AppColors.primaryDeep,
                      blurRadius: 0,
                      offset: Offset(0, 4),
                    ),
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.28),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: AppColors.foreground.withValues(alpha: 0.08),
                      blurRadius: 0,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: borderRadius,
              onHighlightChanged: (value) {
                if (mounted) setState(() => _pressed = value && _enabled);
              },
              onTap: _enabled ? widget.onPressed : null,
              child: body,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(Color color) {
    if (widget.loading) {
      return SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2.5, color: color),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (widget.icon != null) ...[
            IconTheme(
              data: IconThemeData(color: color, size: 20),
              child: widget.icon!,
            ),
            const SizedBox(width: 8),
          ],
          if (widget.expand)
            Flexible(
              child: Text(
                widget.label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: widget.size == GlassButtonSize.large ? 16.5 : 14.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                  height: 1.1,
                ),
              ),
            )
          else
            Text(
              widget.label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: widget.size == GlassButtonSize.large ? 16.5 : 14.5,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
                height: 1.1,
              ),
            ),
        ],
      ),
    );
  }
}

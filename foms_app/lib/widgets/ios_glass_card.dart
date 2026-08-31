import 'dart:ui';
import 'package:flutter/material.dart';

class IosGlassCard extends StatefulWidget {
  final Widget child;
  final double blur;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? surfaceColor;
  final double surfaceOpacity;
  final Color? borderColor;
  final double borderWidth;
  final VoidCallback? onTap;
  final bool animateOnTap;
  final List<BoxShadow>? shadows;
  final Gradient? borderGradient;

  const IosGlassCard({
    super.key,
    required this.child,
    this.blur = 20.0,
    this.borderRadius = 24.0,
    this.padding,
    this.margin,
    this.surfaceColor,
    this.surfaceOpacity = 0.72,
    this.borderColor,
    this.borderWidth = 1.0,
    this.onTap,
    this.animateOnTap = false,
    this.shadows,
    this.borderGradient,
  });

  @override
  State<IosGlassCard> createState() => _IosGlassCardState();
}

class _IosGlassCardState extends State<IosGlassCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.surfaceColor ?? Colors.white;
    final fill = baseColor.withValues(alpha: widget.surfaceOpacity);

    Widget content = Container(
      margin: widget.margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        boxShadow: widget.shadows ?? [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 10),
            spreadRadius: -4,
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.6),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: widget.blur,
            sigmaY: widget.blur,
            tileMode: TileMode.clamp,
          ),
          child: Container(
            padding: widget.padding ?? const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: widget.borderGradient == null
                  ? Border.all(
                      color: widget.borderColor ?? Colors.white.withValues(alpha: 0.8),
                      width: widget.borderWidth,
                    )
                  : null,
            ),
            child: widget.child,
          ),
        ),
      ),
    );

    if (widget.onTap != null) {
      return GestureDetector(
        onTap: widget.onTap,
        onTapDown: widget.animateOnTap ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: widget.animateOnTap ? (_) => setState(() => _isPressed = false) : null,
        onTapCancel: widget.animateOnTap ? () => setState(() => _isPressed = false) : null,
        child: AnimatedScale(
          scale: _isPressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: content,
        ),
      );
    }

    return content;
  }
}

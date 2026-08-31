import 'dart:ui';
import 'package:flutter/material.dart';

class LiquidGlassCard extends StatefulWidget {
  final Widget child;
  final double blur;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? surfaceColor;
  final double surfaceOpacity;
  final Color? glowColor;
  final double glowSpread;
  final double glowBlur;
  final VoidCallback? onTap;
  final bool animateOnTap;
  final bool showGlossReflection;

  const LiquidGlassCard({
    super.key,
    required this.child,
    this.blur = 28.0,
    this.borderRadius = 28.0,
    this.padding,
    this.margin,
    this.surfaceColor,
    this.surfaceOpacity = 0.65,
    this.glowColor,
    this.glowSpread = -2.0,
    this.glowBlur = 30.0,
    this.onTap,
    this.animateOnTap = false,
    this.showGlossReflection = true,
  });

  @override
  State<LiquidGlassCard> createState() => _LiquidGlassCardState();
}

class _LiquidGlassCardState extends State<LiquidGlassCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.surfaceColor ?? Colors.white;
    final fill = baseColor.withValues(alpha: widget.surfaceOpacity);
    final glow = widget.glowColor ?? const Color(0xFF2563EB).withValues(alpha: 0.12);

    Widget content = Container(
      margin: widget.margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        boxShadow: [
          // Deep ambient liquid shadow
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 32,
            offset: const Offset(0, 14),
            spreadRadius: -4,
          ),
          // Subtle neon refractive backglow
          BoxShadow(
            color: glow,
            blurRadius: widget.glowBlur,
            spreadRadius: widget.glowSpread,
            offset: const Offset(0, 6),
          ),
          // Top specular highlight
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.75),
            blurRadius: 6,
            offset: const Offset(0, -1),
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
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.85),
                width: 1.2,
              ),
            ),
            child: Stack(
              children: [
                // Curved liquid top glossy sheen reflection
                if (widget.showGlossReflection)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 54,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(widget.borderRadius),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(alpha: 0.45),
                            Colors.white.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Main content
                Padding(
                  padding: widget.padding ?? const EdgeInsets.all(22),
                  child: widget.child,
                ),
              ],
            ),
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
          scale: _isPressed ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutBack,
          child: content,
        ),
      );
    }

    return content;
  }
}

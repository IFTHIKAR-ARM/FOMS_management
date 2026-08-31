import 'dart:math';
import 'package:flutter/material.dart';

class PremiumBackground extends StatefulWidget {
  final Widget child;
  const PremiumBackground({super.key, required this.child});

  @override
  State<PremiumBackground> createState() => _PremiumBackgroundState();
}

class _PremiumBackgroundState extends State<PremiumBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    duration: const Duration(seconds: 16),
    vsync: this,
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base sleek liquid gradient canvas
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFE2E8F0),
                  Color(0xFFF1F5F9),
                  Color(0xFFEBF4FF),
                  Color(0xFFEDE9FE),
                ],
              ),
            ),
          ),
        ),

        // Fluid Breathing Liquid Plasma Orbs
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final t = _controller.value * 2 * pi;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // 1. Electric Sapphire Liquid Orb (Top-Left)
                  Positioned(
                    left: -100 + sin(t) * 130,
                    top: -80 + cos(t * 0.8) * 110,
                    child: Container(
                      width: 520,
                      height: 520,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2563EB).withValues(alpha: 0.50),
                            blurRadius: 180,
                            spreadRadius: 70,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 2. Neon Cyan Liquid Orb (Top-Right)
                  Positioned(
                    right: -120 + cos(t * 1.1) * 140,
                    top: 80 + sin(t * 0.9) * 150,
                    child: Container(
                      width: 500,
                      height: 500,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF06B6D4).withValues(alpha: 0.42),
                            blurRadius: 170,
                            spreadRadius: 60,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 3. Radiant Magenta/Violet Liquid Orb (Bottom-Left)
                  Positioned(
                    left: -60 + cos(t * 0.7) * 150,
                    bottom: -120 + sin(t * 1.3) * 120,
                    child: Container(
                      width: 560,
                      height: 560,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF8B5CF6).withValues(alpha: 0.45),
                            blurRadius: 180,
                            spreadRadius: 70,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 4. Glowing Coral / Sunset Amber Orb (Bottom-Right)
                  Positioned(
                    right: -80 + sin(t * 1.2) * 120,
                    bottom: -60 + cos(t * 0.6) * 100,
                    child: Container(
                      width: 480,
                      height: 480,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF97316).withValues(alpha: 0.32),
                            blurRadius: 160,
                            spreadRadius: 50,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),

        // Translucent liquid glass tint overlay
        Positioned.fill(
          child: Container(
            color: Colors.white.withValues(alpha: 0.16),
          ),
        ),

        // Main App Viewport
        Positioned.fill(child: widget.child),
      ],
    );
  }
}

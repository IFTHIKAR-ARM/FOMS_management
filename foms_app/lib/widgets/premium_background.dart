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
    duration: const Duration(seconds: 20),
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
        // Base sleek iOS 26 canvas gradient
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFEBF4FF),
                  Color(0xFFF8FAFC),
                  Color(0xFFF1F5F9),
                  Color(0xFFE0E7FF),
                ],
              ),
            ),
          ),
        ),

        // Fluid Breathing Mesh Aurora Orbs
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final t = _controller.value * 2 * pi;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // 1. Electric Cobalt Orb (Top-Left)
                  Positioned(
                    left: -80 + sin(t) * 110,
                    top: -60 + cos(t * 0.9) * 90,
                    child: Container(
                      width: 480,
                      height: 480,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF3B82F6).withValues(alpha: 0.45),
                            blurRadius: 160,
                            spreadRadius: 60,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 2. Cyan / Neon Mint Orb (Center-Right)
                  Positioned(
                    right: -100 + cos(t * 1.1) * 120,
                    top: 150 + sin(t * 0.8) * 140,
                    child: Container(
                      width: 460,
                      height: 460,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF06B6D4).withValues(alpha: 0.35),
                            blurRadius: 150,
                            spreadRadius: 50,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 3. Radiant Violet / Purple Orb (Bottom-Left)
                  Positioned(
                    left: -40 + cos(t * 0.7) * 130,
                    bottom: -100 + sin(t * 1.2) * 100,
                    child: Container(
                      width: 520,
                      height: 520,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF8B5CF6).withValues(alpha: 0.38),
                            blurRadius: 160,
                            spreadRadius: 60,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 4. Warm Sunset Amber Orb (Bottom-Right)
                  Positioned(
                    right: -60 + sin(t * 1.3) * 100,
                    bottom: -40 + cos(t * 0.7) * 80,
                    child: Container(
                      width: 420,
                      height: 420,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
                            blurRadius: 140,
                            spreadRadius: 40,
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

        // Translucent Ultra-fine noise / soft overlay
        Positioned.fill(
          child: Container(
            color: Colors.white.withValues(alpha: 0.20),
          ),
        ),

        // Main App Content Layer
        Positioned.fill(child: widget.child),
      ],
    );
  }
}

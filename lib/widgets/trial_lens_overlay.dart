import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Clinical Retinoscopy Trial Lens Frame Overlay — JMR Technologies
/// Authentic ophthalmic trial lens holder matching standard clinical simulators.
/// Displays 3D beveled ring, left sphere power tab, right cylinder power tab,
/// top alignment tick, and rotating cylinder axis indicator.
class AAOTrialLensOverlay extends StatelessWidget {
  final double size;
  final double sphere;
  final double cylinder;
  final double axis;
  final bool isPlusLens;

  const AAOTrialLensOverlay({
    super.key,
    required this.size,
    required this.sphere,
    required this.cylinder,
    required this.axis,
    this.isPlusLens = true,
  });

  @override
  Widget build(BuildContext context) {
    // Only display when trial lenses are active
    if (sphere == 0.0 && cylinder == 0.0) {
      return const SizedBox.shrink();
    }

    // Authentic Clinical Colors (Vibrant Olive Green for Plus, Crimson Red for Minus)
    final Color baseColor = isPlusLens ? const Color(0xFF558B2F) : const Color(0xFFC62828);
    final Color lightTone = isPlusLens ? const Color(0xFF689F38) : const Color(0xFFD32F2F);
    final Color darkTone = isPlusLens ? const Color(0xFF33691E) : const Color(0xFF8E0000);
    final Color highlightTone = isPlusLens ? const Color(0xFF8BC34A) : const Color(0xFFEF5350);

    final String sphereText = '${sphere > 0 ? '+' : ''}${sphere.toStringAsFixed(2)}';
    final String cylText = '${cylinder > 0 ? '+' : ''}${cylinder.toStringAsFixed(2)}';
    final String axisText = '${axis.toInt()}°';

    final double ringDiameter = size * 0.82;
    final double ringThickness = size * 0.082;
    final double tabWidth = size * 0.24;
    final double tabHeight = size * 0.11;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // 1. Left Sphere Power Tab (Extends horizontally from the left rim)
          if (sphere != 0.0)
            Positioned(
              left: (size - ringDiameter) / 2 - tabWidth * 0.68,
              top: (size - tabHeight) / 2,
              child: Container(
                width: tabWidth,
                height: tabHeight,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [darkTone, baseColor, lightTone],
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                  ),
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(5)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.45),
                      blurRadius: 6,
                      offset: const Offset(-2, 3),
                    ),
                  ],
                  border: Border(
                    top: BorderSide(color: highlightTone.withValues(alpha: 0.8), width: 1.5),
                    left: BorderSide(color: highlightTone.withValues(alpha: 0.8), width: 1.5),
                    bottom: BorderSide(color: darkTone, width: 1.5),
                  ),
                ),
                alignment: Alignment.center,
                padding: const EdgeInsets.only(right: 6),
                child: Text(
                  sphereText,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: size * 0.050,
                    letterSpacing: -0.2,
                    shadows: const [
                      Shadow(color: Colors.black87, blurRadius: 3, offset: Offset(1, 1)),
                    ],
                  ),
                ),
              ),
            ),

          // 2. Right Cylinder Power Tab (Extends horizontally from the right rim)
          if (cylinder != 0.0)
            Positioned(
              right: (size - ringDiameter) / 2 - tabWidth * 0.68,
              top: (size - tabHeight) / 2,
              child: Container(
                width: tabWidth,
                height: tabHeight,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [lightTone, baseColor, darkTone],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(5)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.45),
                      blurRadius: 6,
                      offset: const Offset(2, 3),
                    ),
                  ],
                  border: Border(
                    top: BorderSide(color: highlightTone.withValues(alpha: 0.8), width: 1.5),
                    right: BorderSide(color: highlightTone.withValues(alpha: 0.8), width: 1.5),
                    bottom: BorderSide(color: darkTone, width: 1.5),
                  ),
                ),
                alignment: Alignment.center,
                padding: const EdgeInsets.only(left: 6),
                child: Text(
                  cylText,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: size * 0.050,
                    letterSpacing: -0.2,
                    shadows: const [
                      Shadow(color: Colors.black87, blurRadius: 3, offset: Offset(1, 1)),
                    ],
                  ),
                ),
              ),
            ),

          // 3. Main Circular Trial Frame Ring (Beveled 3D Rim)
          Container(
            width: ringDiameter,
            height: ringDiameter,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.transparent,
                  Colors.transparent,
                  darkTone,
                  baseColor,
                  lightTone,
                ],
                stops: const [0.0, 0.74, 0.78, 0.90, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 10,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: highlightTone.withValues(alpha: 0.5), width: 1.2),
              ),
            ),
          ),

          // 4. Rotating Axis Ring: Top Notch Indicator & Bottom Axis Degree Badge
          Transform.rotate(
            angle: (axis - 90) * math.pi / 180,
            child: SizedBox(
              width: ringDiameter,
              height: ringDiameter,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Top Axis Alignment Indicator ('|' line)
                  Positioned(
                    top: ringThickness * 0.16,
                    child: Container(
                      width: 4.0,
                      height: ringThickness * 0.65,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: const [
                          BoxShadow(color: Colors.black87, blurRadius: 3),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Axis Degree Badge (e.g. '90°', '180°')
                  if (cylinder != 0.0)
                    Positioned(
                      bottom: ringThickness * 0.08,
                      child: Text(
                        axisText,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: size * 0.052,
                          letterSpacing: 0.2,
                          shadows: const [
                            Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(0, 1)),
                            Shadow(color: Colors.black54, blurRadius: 2, offset: Offset(1, 2)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

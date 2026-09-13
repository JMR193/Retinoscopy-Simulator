import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../state/retinoscopy_state.dart';

/// Copeland's ±45° Straddling Clinical Axis Verification Widget
/// Displays dual-angle straddle reflex comparisons (thickness and brilliance)
/// with real-time rotational refinement controls.
class CopelandStraddleView extends StatelessWidget {
  final RetinoscopyState state;

  const CopelandStraddleView({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final double widthMinus = state.calculateStraddleWidth(-1);
    final double widthPlus = state.calculateStraddleWidth(1);
    final double luxMinus = state.calculateStraddleLuminance(-1);
    final double luxPlus = state.calculateStraddleLuminance(1);

    final double angleMinus = (_stateStreakMinus45(state.streakAngle));
    final double anglePlus = (_stateStreakPlus45(state.streakAngle));
    final bool isEquilibrium = state.isStraddleEquilibrium;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isEquilibrium ? Colors.green.withValues(alpha: 0.5) : colorScheme.primary.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                isEquilibrium ? Icons.verified : Icons.explore,
                color: isEquilibrium ? Colors.greenAccent : colorScheme.primary,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Copeland ±45° Straddle Verification',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (isEquilibrium ? Colors.green : Colors.orange).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isEquilibrium ? Colors.green : Colors.orange),
                ),
                child: Text(
                  isEquilibrium ? 'AXIS VERIFIED' : 'ALIGNING AXIS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isEquilibrium ? Colors.greenAccent : Colors.orange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Dual Straddle Comparison Cards
          Row(
            children: [
              Expanded(
                child: _buildStraddleCard(
                  title: 'Straddle -45°',
                  angle: angleMinus,
                  width: widthMinus,
                  luminance: luxMinus,
                  isHighlight: widthMinus < widthPlus && !isEquilibrium,
                  isDark: isDark,
                  colorScheme: colorScheme,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStraddleCard(
                  title: 'Straddle +45°',
                  angle: anglePlus,
                  width: widthPlus,
                  luminance: luxPlus,
                  isHighlight: widthPlus < widthMinus && !isEquilibrium,
                  isDark: isDark,
                  colorScheme: colorScheme,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Clinical Guidance Banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isEquilibrium
                  ? (isDark ? const Color(0xFF064E3B) : Colors.green.shade50)
                  : (isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF)),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isEquilibrium ? Colors.green : Colors.blue.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  isEquilibrium ? Icons.check_circle : Icons.tips_and_updates,
                  color: isEquilibrium ? Colors.greenAccent : Colors.blueAccent,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    state.straddleClinicalAdvice,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Quick Axis Step Adjustment Toolbar
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Adjust Cyl Axis: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
              IconButton(
                icon: const Icon(Icons.rotate_left, size: 20),
                tooltip: '-5°',
                visualDensity: VisualDensity.compact,
                onPressed: () {
                  _stepAxis(state, -5.0);
                },
              ),
              IconButton(
                icon: const Icon(Icons.arrow_back, size: 16),
                tooltip: '-1°',
                visualDensity: VisualDensity.compact,
                onPressed: () {
                  _stepAxis(state, -1.0);
                },
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
                ),
                child: Text(
                  '${(state.plusLensesSelected ? state.plusAxis : state.minusAxis).toInt()}°',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: colorScheme.onSurface),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward, size: 16),
                tooltip: '+1°',
                visualDensity: VisualDensity.compact,
                onPressed: () {
                  _stepAxis(state, 1.0);
                },
              ),
              IconButton(
                icon: const Icon(Icons.rotate_right, size: 20),
                tooltip: '+5°',
                visualDensity: VisualDensity.compact,
                onPressed: () {
                  _stepAxis(state, 5.0);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _stepAxis(RetinoscopyState state, double delta) {
    if (state.plusLensesSelected) {
      double newAxis = (state.plusAxis + delta);
      if (newAxis > 180.0) newAxis -= 180.0;
      if (newAxis < 1.0) newAxis += 180.0;
      state.plusAxis = newAxis;
    } else {
      double newAxis = (state.minusAxis + delta);
      if (newAxis > 180.0) newAxis -= 180.0;
      if (newAxis < 1.0) newAxis += 180.0;
      state.minusAxis = newAxis;
    }
  }

  double _stateStreakMinus45(double currentStreak) {
    double a = currentStreak - 45.0;
    if (a <= 0) a += 180.0;
    return a;
  }

  double _stateStreakPlus45(double currentStreak) {
    double a = currentStreak + 45.0;
    if (a > 180) a -= 180.0;
    return a;
  }

  Widget _buildStraddleCard({
    required String title,
    required double angle,
    required double width,
    required double luminance,
    required bool isHighlight,
    required bool isDark,
    required ColorScheme colorScheme,
  }) {
    final Color borderCol = isHighlight ? Colors.amber : (isDark ? Colors.white12 : Colors.black12);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderCol, width: isHighlight ? 1.5 : 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11.5,
                  color: isHighlight ? Colors.amber : (isDark ? Colors.white : Colors.black87),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${angle.toInt()}°',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colorScheme.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Mini Reflex Slit Graphic
          Center(
            child: Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black,
                border: Border.all(color: Colors.white24, width: 1),
              ),
              child: Center(
                child: Transform.rotate(
                  angle: (angle - 90) * math.pi / 180,
                  child: Container(
                    width: (width * 0.45).clamp(3.0, 26.0),
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFFF9800).withValues(alpha: luminance * 0.7),
                          Colors.white.withValues(alpha: luminance),
                          const Color(0xFFFF9800).withValues(alpha: luminance * 0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Metrics
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Brilliance:', style: TextStyle(fontSize: 9.5, color: Colors.grey)),
              Text('${(luminance * 100).toInt()}%', style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Thickness:', style: TextStyle(fontSize: 9.5, color: Colors.grey)),
              Text('${width.toStringAsFixed(1)} px', style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}

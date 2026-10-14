import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../state/retinoscopy_state.dart';

/// Clinical Reflex Motion Dynamics & Telemetry Gauge
///
/// Displays real-time optical characteristics of the fundus reflex:
/// 1. Motion Type: WITH (+), AGAINST (−), NEUTRALITY FLASH (★), or SCISSORS (✂)
/// 2. Velocity Index: Inversely proportional to dioptric distance from neutral point
/// 3. Luminance / Brilliance Index: Photometric reflex brightness in pupil
/// 4. Collimation / Width: Narrow slit to full-pupil flash
/// 5. Astigmatic Alignment: Break phenomenon displacement angle
class ReflexMotionGauge extends StatefulWidget {
  final RetinoscopyState state;
  final bool compactMode;

  const ReflexMotionGauge({
    super.key,
    required this.state,
    this.compactMode = false,
  });

  @override
  State<ReflexMotionGauge> createState() => _ReflexMotionGaugeState();
}

class _ReflexMotionGaugeState extends State<ReflexMotionGauge> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final String motion = state.reflexMotion;
    final double reflexWidth = state.reflexWidth;

    // Optical physics calculations for velocity and luminance:
    // Near neutrality, unneutralized error approaches 0, velocity approaches infinity (flash).
    final double sweepMeridian = (state.streakAngle + 90.0) % 180.0;
    final double sweepRad = sweepMeridian * math.pi / 180.0;
    final double patientAxisRad = state.patientAngle * math.pi / 180.0;
    final double patientMeridianPower = state.patientSphere + state.patientCylinder * math.pow(math.sin(sweepRad - patientAxisRad), 2);

    final double ts = state.plusLensesSelected ? state.plusSphere : state.minusSphere;
    final double tc = state.plusLensesSelected ? state.plusCylinder : state.minusCylinder;
    final double ta = state.plusLensesSelected ? state.plusAxis : state.minusAxis;
    final double trialAxisRad = ta * math.pi / 180.0;
    final double trialMeridianPower = ts + tc * math.pow(math.sin(sweepRad - trialAxisRad), 2);

    final double netDiopters = (patientMeridianPower - (trialMeridianPower - state.workingDistance)).abs();

    // Velocity index: 0.0 (far away) to 1.0 (flash point)
    final double velocityIndex = (1.0 / (1.0 + netDiopters * 0.75)).clamp(0.10, 1.0);
    // Luminance index: 0.15 (dim) to 1.0 (maximum brilliant flash)
    final double luminanceIndex = (1.0 / (1.0 + netDiopters * 0.90)).clamp(0.15, 1.0);
    // Width factor: 0.10 (thin streak) to 1.0 (fills pupil)
    final double widthFactor = ((reflexWidth.abs() / 90.0).clamp(0.12, 1.0));

    // Break phenomenon angle
    final double breakAngle = state.breakDisplacementAngle.abs();

    // Theme color based on motion type
    Color motionColor;
    String motionTitle;
    IconData motionIcon;

    if (motion == 'neutral') {
      motionColor = const Color(0xFFFFD60A); // Amber Gold
      motionTitle = 'NEUTRALITY FLASH';
      motionIcon = Icons.auto_awesome;
    } else if (motion == 'with') {
      motionColor = const Color(0xFF34C759); // Apple Green
      motionTitle = 'WITH MOTION (+)';
      motionIcon = Icons.arrow_forward_rounded;
    } else if (motion == 'against') {
      motionColor = const Color(0xFFFF453A); // Red
      motionTitle = 'AGAINST MOTION (−)';
      motionIcon = Icons.arrow_back_rounded;
    } else {
      motionColor = const Color(0xFFBF5AF2); // Purple
      motionTitle = 'SCISSORS MOTION';
      motionIcon = Icons.content_cut_rounded;
    }

    if (widget.compactMode) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: motionColor.withValues(alpha: 0.4), width: 1.2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(motionIcon, size: 14, color: motionColor),
            const SizedBox(width: 6),
            Text(
              motionTitle,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: motionColor,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: isDark ? Colors.white12 : Colors.black12,
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: velocityIndex,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: motionColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: motion == 'neutral'
                  ? motionColor.withValues(alpha: 0.5 + 0.3 * _pulseAnimation.value)
                  : (isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.08)),
              width: motion == 'neutral' ? 1.8 : 1.0,
            ),
            boxShadow: [
              if (motion == 'neutral')
                BoxShadow(
                  color: motionColor.withValues(alpha: 0.15 + 0.15 * _pulseAnimation.value),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar: Motion Badge & Proximity Diopters
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: motionColor.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: motionColor.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(motionIcon, size: 13, color: motionColor),
                            const SizedBox(width: 5),
                            Text(
                              motionTitle,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: motionColor,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Text(
                    netDiopters < 0.15
                        ? '★ At Neutrality'
                        : '${netDiopters.toStringAsFixed(2)} D from Neutral',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: netDiopters < 0.15
                          ? const Color(0xFFFFD60A)
                          : (isDark ? Colors.white70 : Colors.black87),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // 3 Telemetry Bars: Velocity, Luminance, Width
              _buildTelemetryRow(
                label: 'Reflex Speed',
                valueFactor: velocityIndex,
                valueText: netDiopters < 0.15
                    ? 'Infinite (Flash)'
                    : netDiopters < 1.0
                        ? 'Fast'
                        : netDiopters < 3.0
                            ? 'Moderate'
                            : 'Slow',
                barColor: motionColor,
                isDark: isDark,
              ),
              const SizedBox(height: 6),
              _buildTelemetryRow(
                label: 'Brilliance / Lux',
                valueFactor: luminanceIndex,
                valueText: '${(luminanceIndex * 100).toInt()}%',
                barColor: Colors.amber,
                isDark: isDark,
              ),
              const SizedBox(height: 6),
              _buildTelemetryRow(
                label: 'Pupil Fill / Width',
                valueFactor: widthFactor,
                valueText: netDiopters < 0.15 ? '100% Flood' : '${(widthFactor * 100).toInt()}%',
                barColor: Colors.cyan,
                isDark: isDark,
              ),

              // Astigmatic Break Phenomenon Callout (if active)
              if (state.isBreakPhenomenonActive) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.broken_image_outlined, size: 13, color: Colors.purpleAccent),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Break Phenomenon: Streak displaced ${breakAngle.toStringAsFixed(0)}° from cylinder axis (${state.patientAngle.toInt()}°)',
                          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Colors.purpleAccent),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildTelemetryRow({
    required String label,
    required double valueFactor,
    required String valueText,
    required Color barColor,
    required bool isDark,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 95,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Container(
              height: 6,
              color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200,
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: valueFactor.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [barColor.withValues(alpha: 0.6), barColor],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 80,
          child: Text(
            valueText,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}

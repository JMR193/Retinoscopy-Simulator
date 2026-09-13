import 'package:flutter/material.dart';
import '../state/retinoscopy_state.dart';

/// Interactive Clinical Protocol Guided Mode Stepper Banner
/// Guides students through AAO Plus-Cyl, Optometry Minus-Cyl, Mohindra Pediatric,
/// and MEM Dynamic Retinoscopy protocols with live verification.
class ProtocolGuidedBanner extends StatelessWidget {
  final RetinoscopyState state;
  final VoidCallback onDismiss;

  const ProtocolGuidedBanner({
    super.key,
    required this.state,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color protocolColor = _getProtocolColor(state.activeProtocol);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: protocolColor.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: protocolColor.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: protocolColor.withValues(alpha: isDark ? 0.2 : 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Icon(Icons.menu_book, size: 18, color: protocolColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    state.protocolStepTitle,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: protocolColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Step ${state.protocolStep}/5',
                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: onDismiss,
                ),
              ],
            ),
          ),

          // Guidance Body
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.protocolStepGuidance,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.45,
                    color: isDark ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),

                // Live Validation Chip
                _buildLiveValidationBadge(state, protocolColor, isDark),

                const SizedBox(height: 10),

                // Navigation Controls & Step Dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: state.protocolStep > 1 ? () => state.prevProtocolStep() : null,
                      icon: const Icon(Icons.arrow_back, size: 14),
                      label: const Text('Previous', style: TextStyle(fontSize: 11)),
                      style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                    ),
                    Row(
                      children: List.generate(5, (index) {
                        final bool active = index + 1 == state.protocolStep;
                        final bool past = index + 1 < state.protocolStep;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2.5),
                          width: active ? 18 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: active
                                ? protocolColor
                                : (past ? protocolColor.withValues(alpha: 0.4) : Colors.grey.withValues(alpha: 0.3)),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        );
                      }),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        if (state.protocolStep < 5) {
                          state.nextProtocolStep();
                        } else {
                          onDismiss();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: protocolColor,
                        foregroundColor: Colors.white,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      ),
                      icon: Icon(state.protocolStep < 5 ? Icons.arrow_forward : Icons.check, size: 14),
                      label: Text(state.protocolStep < 5 ? 'Next Step' : 'Finish', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveValidationBadge(RetinoscopyState state, Color color, bool isDark) {
    bool isCompleted = false;
    String statusText = 'In Progress';

    switch (state.protocolStep) {
      case 1:
        if (state.activeProtocol == ClinicalProtocolMode.mohindraPediatric) {
          isCompleted = state.workingDistance == 2.0;
          statusText = isCompleted ? 'WD Set to 50 cm (+2.00 D) ✓' : 'Set WD to 50 cm';
        } else {
          isCompleted = state.workingDistance > 0;
          statusText = isCompleted ? 'WD Offset Active (${state.workingDistanceFormatted}) ✓' : 'Set Working Distance';
        }
        break;
      case 2:
        isCompleted = (state.streakAngle % 90 == 0);
        statusText = isCompleted ? 'Streak at ${state.streakAngle.toStringAsFixed(0)}° ✓' : 'Sweep at 90° or 180°';
        break;
      case 3:
        isCompleted = state.reflexMotion == 'neutral' || state.pupilFillRatio > 0.85;
        statusText = isCompleted ? 'Meridian Neutralized! ✓' : 'Dial Sphere until Neutral';
        break;
      case 4:
        isCompleted = (_plusLensSelected(state) ? state.plusCylinder : state.minusCylinder).abs() > 0.1 && (state.reflexMotion == 'neutral' || state.pupilFillRatio > 0.80);
        statusText = isCompleted ? 'Cylinder Neutralized! ✓' : 'Dial Cylinder to Neutralize';
        break;
      case 5:
        isCompleted = state.isStraddleEquilibrium;
        statusText = isCompleted ? 'Copeland Straddle Equilibrium Verified! 🎯' : 'Refine Axis Alignment';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isCompleted
            ? Colors.green.withValues(alpha: isDark ? 0.25 : 0.15)
            : color.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCompleted ? Colors.green : color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 14,
            color: isCompleted ? Colors.green : color,
          ),
          const SizedBox(width: 6),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: isCompleted ? (isDark ? Colors.greenAccent : Colors.green[800]) : (isDark ? Colors.white70 : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  bool _plusLensSelected(RetinoscopyState state) => state.plusLensesSelected;

  Color _getProtocolColor(ClinicalProtocolMode mode) {
    switch (mode) {
      case ClinicalProtocolMode.aaoPlusCyl:
        return const Color(0xFF2E7D32); // Green
      case ClinicalProtocolMode.optometryMinusCyl:
        return const Color(0xFFC62828); // Red
      case ClinicalProtocolMode.mohindraPediatric:
        return const Color(0xFFE65100); // Orange
      case ClinicalProtocolMode.memDynamic:
        return const Color(0xFF6A1B9A); // Purple
      case ClinicalProtocolMode.none:
        return const Color(0xFF1565C0);
    }
  }
}


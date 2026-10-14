import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/audio_service.dart';

/// Interactive Spherocylindrical Transposition Laboratory Widget
///
/// Teaches and calculates the clinical transposition between:
/// 1. Plus-Cylinder Form (+Cyl)
/// 2. Minus-Cylinder Form (−Cyl)
/// 3. Optical Power Cross (Dual Meridians)
/// 4. Spherical Equivalent (SE)
class SpherocylinderTranspositionCard extends StatefulWidget {
  final double initialSphere;
  final double initialCylinder;
  final double initialAxis;
  final void Function(double sphere, double cylinder, double axis)? onApplyToSimulator;
  final VoidCallback? onClose;

  const SpherocylinderTranspositionCard({
    super.key,
    this.initialSphere = 1.00,
    this.initialCylinder = -2.00,
    this.initialAxis = 90.0,
    this.onApplyToSimulator,
    this.onClose,
  });

  @override
  State<SpherocylinderTranspositionCard> createState() => _SpherocylinderTranspositionCardState();
}

class _SpherocylinderTranspositionCardState extends State<SpherocylinderTranspositionCard> {
  late double _sphere;
  late double _cylinder;
  late double _axis;

  @override
  void initState() {
    super.initState();
    _sphere = widget.initialSphere;
    _cylinder = widget.initialCylinder;
    _axis = widget.initialAxis;
  }

  @override
  void didUpdateWidget(covariant SpherocylinderTranspositionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSphere != widget.initialSphere ||
        oldWidget.initialCylinder != widget.initialCylinder ||
        oldWidget.initialAxis != widget.initialAxis) {
      _sphere = widget.initialSphere;
      _cylinder = widget.initialCylinder;
      _axis = widget.initialAxis;
    }
  }

  String _formatDiopter(double val) {
    final s = val.toStringAsFixed(2);
    return val > 0 ? '+$s' : s;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Transposition Calculations:
    // 1. New Sphere = Old Sphere + Old Cylinder
    final double transSphere = _sphere + _cylinder;
    // 2. New Cylinder = -Old Cylinder
    final double transCylinder = -_cylinder;
    // 3. New Axis = (Old Axis + 90) % 180 (using 180 instead of 0)
    double transAxis = _axis + 90.0;
    if (transAxis > 180.0) transAxis -= 180.0;
    if (transAxis <= 0.0) transAxis = 180.0;
    // 4. Spherical Equivalent = Sphere + (Cylinder / 2)
    final double sphericalEquivalent = _sphere + (_cylinder / 2.0);

    // Principal Meridian Powers for Optical Cross:
    // Along axis: power = Sphere
    // Along perpendicular (axis + 90): power = Sphere + Cylinder
    final double powerAtAxis = _sphere;
    final double powerAtPerp = _sphere + _cylinder;

    final String form1 = '${_formatDiopter(_sphere)} DS / ${_formatDiopter(_cylinder)} DC × ${_axis.toInt()}°';
    final String form2 = '${_formatDiopter(transSphere)} DS / ${_formatDiopter(transCylinder)} DC × ${transAxis.toInt()}°';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.teal.withValues(alpha: 0.3) : Colors.teal.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.teal.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.sync_alt_rounded, color: Colors.tealAccent, size: 18),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Spherocylinder Transposition Lab',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
                if (widget.onClose != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: widget.onClose,
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Close Transposition Lab',
                  ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Two Reciprocal Forms Display Card
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              children: [
                // Form 1 & Form 2 Comparison Cards
                Row(
                  children: [
                    // Active Form
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: (_cylinder >= 0 ? Colors.green : Colors.blue).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: (_cylinder >= 0 ? Colors.green : Colors.blue).withValues(alpha: 0.35),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _cylinder >= 0 ? 'Plus-Cylinder Form (+Cyl)' : 'Minus-Cylinder Form (−Cyl)',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: _cylinder >= 0 ? Colors.green : Colors.blue,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              form1,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.compare_arrows_rounded, color: Colors.teal, size: 20),
                    const SizedBox(width: 8),
                    // Transposed Form
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: (transCylinder >= 0 ? Colors.green : Colors.blue).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: (transCylinder >= 0 ? Colors.green : Colors.blue).withValues(alpha: 0.35),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              transCylinder >= 0 ? 'Plus-Cylinder Form (+Cyl)' : 'Minus-Cylinder Form (−Cyl)',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: transCylinder >= 0 ? Colors.green : Colors.blue,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              form2,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Step-by-Step Educational Proof Box
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Mathematical Transposition Protocol:',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.tealAccent),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '1. S\' = S + C = ${_formatDiopter(_sphere)} + (${_formatDiopter(_cylinder)}) = ${_formatDiopter(transSphere)} DS\n'
                        '2. C\' = −C = −(${_formatDiopter(_cylinder)}) = ${_formatDiopter(transCylinder)} DC\n'
                        '3. Axis\' = (${_axis.toInt()}° + 90°) mod 180° = ${transAxis.toInt()}°\n'
                        '4. Spherical Equivalent (SE) = S + (C / 2) = ${_formatDiopter(sphericalEquivalent)} DS',
                        style: TextStyle(
                          fontSize: 11.5,
                          height: 1.45,
                          fontFamily: 'monospace',
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Optical Cross Meridian Summary
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMeridianBadge('Meridian @ ${_axis.toInt()}°', '${_formatDiopter(powerAtAxis)} DS', isDark),
                    _buildMeridianBadge('Meridian @ ${transAxis.toInt()}°', '${_formatDiopter(powerAtPerp)} DS', isDark),
                    _buildMeridianBadge('Spherical Equiv', '${_formatDiopter(sphericalEquivalent)} DS', isDark),
                  ],
                ),
                const SizedBox(height: 12),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.copy, size: 14),
                        label: const Text('Copy Form 2', style: TextStyle(fontSize: 11.5)),
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: form2));
                          HapticFeedback.lightImpact();
                          AudioService.playTick();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Copied "$form2" to clipboard'), duration: const Duration(seconds: 1)),
                          );
                        },
                      ),
                    ),
                    if (widget.onApplyToSimulator != null) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.flip_camera_android, size: 14),
                          label: const Text('Apply Transposed', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal[700],
                            foregroundColor: Colors.white,
                            visualDensity: VisualDensity.compact,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            AudioService.playTick();
                            widget.onApplyToSimulator!(transSphere, transCylinder, transAxis);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Applied Transposed Rx: $form2'), duration: const Duration(seconds: 1)),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeridianBadge(String title, String power, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
      ),
      child: Column(
        children: [
          Text(title, style: TextStyle(fontSize: 9.5, color: isDark ? Colors.white60 : Colors.black54)),
          const SizedBox(height: 2),
          Text(power, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal)),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../widgets/power_cross_view.dart';

/// Optical Power Cross & Transposition Calculator Screen
/// Provides instant bi-directional spherocylindrical transposition,
/// spherical equivalent, working distance compensator, and 2-meridian power cross.
class OpticalCalculatorScreen extends StatefulWidget {
  const OpticalCalculatorScreen({super.key});

  @override
  State<OpticalCalculatorScreen> createState() => _OpticalCalculatorScreenState();
}

class _OpticalCalculatorScreenState extends State<OpticalCalculatorScreen> {
  double _sphere = 2.00;
  double _cylinder = -1.50;
  double _axis = 90.0;
  double _workingDistance = 1.50; // 67 cm (+1.50 D)

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Transposition Calculations
    // Plus/Minus cylinder transposition:
    // S' = S + C
    // C' = -C
    // A' = (A + 90) % 180 (if 0 -> 180)
    final double transposedSphere = _sphere + _cylinder;
    final double transposedCylinder = -_cylinder;
    final double transposedAxis = (_axis + 90) > 180 ? _axis - 90 : _axis + 90;

    // Spherical Equivalent: SE = S + C/2
    final double sphericalEquivalent = _sphere + (_cylinder / 2);

    // Working Distance Compensated Net Rx:
    final double netSphere = _sphere - _workingDistance;
    final double netTransposedSphere = transposedSphere - _workingDistance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Optical Cross & Transposition'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Input Prescription Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Prescription Input',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${_sphere > 0 ? '+' : ''}${_sphere.toStringAsFixed(2)} DS / ${_cylinder > 0 ? '+' : ''}${_cylinder.toStringAsFixed(2)} DC × ${_axis.toInt()}°',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSlider(
                      label: 'Sphere Power',
                      value: _sphere,
                      min: -15.0,
                      max: 15.0,
                      divisions: 120,
                      color: Colors.blue,
                      onChanged: (v) => setState(() => _sphere = (v * 4).round() / 4),
                    ),
                    _buildSlider(
                      label: 'Cylinder Power',
                      value: _cylinder,
                      min: -8.0,
                      max: 8.0,
                      divisions: 64,
                      color: Colors.orange,
                      onChanged: (v) => setState(() => _cylinder = (v * 4).round() / 4),
                    ),
                    _buildSlider(
                      label: 'Cylinder Axis',
                      value: _axis,
                      min: 1.0,
                      max: 180.0,
                      divisions: 179,
                      color: Colors.purple,
                      isDegree: true,
                      onChanged: (v) => setState(() => _axis = v.roundToDouble()),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Dynamic 2-Meridian Power Cross
            PowerCrossView(
              sphere: _sphere,
              cylinder: _cylinder,
              axis: _axis,
            ),
            const SizedBox(height: 16),

            // Transposition & Equivalence Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.swap_horiz, color: Colors.indigo),
                        SizedBox(width: 8),
                        Text(
                          'Spherocylindrical Transposition',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildResultRow(
                      'Primary Form',
                      '${_sphere > 0 ? '+' : ''}${_sphere.toStringAsFixed(2)} DS / ${_cylinder > 0 ? '+' : ''}${_cylinder.toStringAsFixed(2)} DC × ${_axis.toInt()}°',
                      _cylinder < 0 ? Colors.red : Colors.green,
                    ),
                    const Divider(height: 16),
                    _buildResultRow(
                      'Transposed Form',
                      '${transposedSphere > 0 ? '+' : ''}${transposedSphere.toStringAsFixed(2)} DS / ${transposedCylinder > 0 ? '+' : ''}${transposedCylinder.toStringAsFixed(2)} DC × ${transposedAxis.toInt()}°',
                      transposedCylinder < 0 ? Colors.red : Colors.green,
                    ),
                    const Divider(height: 16),
                    _buildResultRow(
                      'Spherical Equivalent (SE)',
                      '${sphericalEquivalent > 0 ? '+' : ''}${sphericalEquivalent.toStringAsFixed(2)} DS',
                      Colors.teal,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Working Distance Compensation Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.straighten, color: Colors.deepOrange),
                        SizedBox(width: 8),
                        Text(
                          'Working Distance Compensation',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        ChoiceChip(
                          label: const Text('50 cm (+2.00 D)'),
                          selected: (_workingDistance - 2.00).abs() < 0.05,
                          onSelected: (_) => setState(() => _workingDistance = 2.00),
                        ),
                        ChoiceChip(
                          label: const Text('67 cm (+1.50 D)'),
                          selected: (_workingDistance - 1.50).abs() < 0.05,
                          onSelected: (_) => setState(() => _workingDistance = 1.50),
                        ),
                        ChoiceChip(
                          label: const Text('100 cm (+1.00 D)'),
                          selected: (_workingDistance - 1.00).abs() < 0.05,
                          onSelected: (_) => setState(() => _workingDistance = 1.00),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.deepOrange.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.deepOrange.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Final Net Patient Rx = Gross Trial Lens − Working Distance:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Text(
                            '• Primary Form: ${netSphere > 0 ? '+' : ''}${netSphere.toStringAsFixed(2)} DS ${_cylinder > 0 ? '+' : ''}${_cylinder.toStringAsFixed(2)} DC × ${_axis.toInt()}°',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                          ),
                          Text(
                            '• Transposed Form: ${netTransposedSphere > 0 ? '+' : ''}${netTransposedSphere.toStringAsFixed(2)} DS ${transposedCylinder > 0 ? '+' : ''}${transposedCylinder.toStringAsFixed(2)} DC × ${transposedAxis.toInt()}°',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required Color color,
    bool isDegree = false,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            Text(
              isDegree
                  ? '${value.toInt()}°'
                  : '${value > 0 ? '+' : ''}${value.toStringAsFixed(2)} D',
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          activeColor: color,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildResultRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color),
          ),
        ),
      ],
    );
  }
}

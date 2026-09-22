import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state/retinoscopy_state.dart';
import '../widgets/power_cross_view.dart';

/// Optical Power Cross, Retinoscopy Answers & Transposition Calculator Screen
/// Provides instant bi-directional spherocylindrical transposition,
/// retinoscopy dual-meridian answer solver, working distance compensator, and 2-meridian power cross.
class OpticalCalculatorScreen extends StatefulWidget {
  const OpticalCalculatorScreen({super.key});

  @override
  State<OpticalCalculatorScreen> createState() => _OpticalCalculatorScreenState();
}

class _OpticalCalculatorScreenState extends State<OpticalCalculatorScreen> {
  // Input Mode: 0 = Dual Meridian Neutralization (M1/M2), 1 = Gross Spherocylinder Lens
  int _inputMode = 0;

  // Dual Meridian Mode Inputs (Gross Neutralizing Powers)
  double _m1GrossPower = 3.50; // Gross Lens for Meridian 1
  double _m1Axis = 90.0;       // Axis for Meridian 1
  double _m2GrossPower = 1.50; // Gross Lens for Meridian 2

  // Gross Spherocylinder Mode Inputs
  double _grossSphere = 3.50;
  double _grossCylinder = -2.00;
  double _grossAxis = 180.0;

  double _workingDistance = 1.50; // 67 cm (+1.50 D)

  // Keratometry state
  double _k1 = 43.00; // Flat meridian power in Diopters
  double _k2 = 44.50; // Steep meridian power in Diopters
  double _k1Axis = 180.0; // Flat meridian axis

  // Zernike Wavefront & Optical Quality state
  double _pupilDiameter = 5.0; // mm
  double _sphericalAberrationZ40 = 0.12; // µm (Z_4^0)

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Derived Retinoscopy Answer Calculations
    double netM1, netM2, grossM1, grossM2, m1Axis, m2Axis;
    double plusSphere, plusCylinder, plusAxis;
    double minusSphere, minusCylinder, minusAxis;
    double sphericalEquivalent;

    if (_inputMode == 0) {
      // Dual Meridian Neutralization Mode
      grossM1 = _m1GrossPower;
      grossM2 = _m2GrossPower;
      m1Axis = _m1Axis;
      m2Axis = (_m1Axis + 90.0) > 180.0 ? _m1Axis - 90.0 : _m1Axis + 90.0;

      final result = RetinoscopyState.calculateRetinoscopyAnswer(
        grossM1Power: grossM1,
        grossM1Axis: m1Axis,
        grossM2Power: grossM2,
        workingDistance: _workingDistance,
      );

      netM1 = result['netM1'];
      netM2 = result['netM2'];
      plusSphere = result['plusSphere'];
      plusCylinder = result['plusCylinder'];
      plusAxis = result['plusAxis'];
      minusSphere = result['minusSphere'];
      minusCylinder = result['minusCylinder'];
      minusAxis = result['minusAxis'];
      sphericalEquivalent = result['sphericalEquivalent'];
    } else {
      // Gross Spherocylinder Mode
      m1Axis = _grossAxis;
      grossM1 = _grossSphere;
      m2Axis = (_grossAxis + 90.0) > 180.0 ? _grossAxis - 90.0 : _grossAxis + 90.0;
      grossM2 = _grossSphere + _grossCylinder;

      final result = RetinoscopyState.calculateRetinoscopyAnswer(
        grossM1Power: grossM1,
        grossM1Axis: m1Axis,
        grossM2Power: grossM2,
        workingDistance: _workingDistance,
      );

      netM1 = result['netM1'];
      netM2 = result['netM2'];
      plusSphere = result['plusSphere'];
      plusCylinder = result['plusCylinder'];
      plusAxis = result['plusAxis'];
      minusSphere = result['minusSphere'];
      minusCylinder = result['minusCylinder'];
      minusAxis = result['minusAxis'];
      sphericalEquivalent = result['sphericalEquivalent'];
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Retinoscopy Answers & Optical Cross'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Mode Selector Banner
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _inputMode = 0);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _inputMode == 0 ? colorScheme.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: _inputMode == 0
                              ? [
                                  BoxShadow(
                                    color: colorScheme.primary.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            'Dual Meridian (M1/M2)',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5,
                              letterSpacing: -0.2,
                              color: _inputMode == 0 ? colorScheme.onPrimary : colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _inputMode = 1);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _inputMode == 1 ? colorScheme.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: _inputMode == 1
                              ? [
                                  BoxShadow(
                                    color: colorScheme.primary.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            'Gross Spherocylinder',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5,
                              letterSpacing: -0.2,
                              color: _inputMode == 1 ? colorScheme.onPrimary : colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Input Prescription Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _inputMode == 0 ? 'Retinoscopy Gross Neutralizing Lenses' : 'Gross Spherocylindrical Lens',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _inputMode == 0
                                ? 'M1: ${grossM1 > 0 ? '+' : ''}${grossM1.toStringAsFixed(2)} D @ ${m1Axis.toInt()}° | M2: ${grossM2 > 0 ? '+' : ''}${grossM2.toStringAsFixed(2)} D @ ${m2Axis.toInt()}°'
                                : '${_grossSphere > 0 ? '+' : ''}${_grossSphere.toStringAsFixed(2)} DS / ${_grossCylinder > 0 ? '+' : ''}${_grossCylinder.toStringAsFixed(2)} DC × ${_grossAxis.toInt()}°',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.blue),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (_inputMode == 0) ...[
                      _buildSlider(
                        label: 'Meridian 1 Gross Power (M1)',
                        value: _m1GrossPower,
                        min: -15.0,
                        max: 15.0,
                        divisions: 120,
                        color: Colors.green,
                        onChanged: (v) => setState(() => _m1GrossPower = (v * 4).round() / 4),
                      ),
                      _buildSlider(
                        label: 'Meridian 1 Axis',
                        value: _m1Axis,
                        min: 1.0,
                        max: 180.0,
                        divisions: 179,
                        color: Colors.teal,
                        isDegree: true,
                        onChanged: (v) => setState(() => _m1Axis = v.roundToDouble()),
                      ),
                      _buildSlider(
                        label: 'Meridian 2 Gross Power (M2 @ ${(m1Axis + 90 > 180 ? m1Axis - 90 : m1Axis + 90).toInt()}°)',
                        value: _m2GrossPower,
                        min: -15.0,
                        max: 15.0,
                        divisions: 120,
                        color: Colors.amber,
                        onChanged: (v) => setState(() => _m2GrossPower = (v * 4).round() / 4),
                      ),
                    ] else ...[
                      _buildSlider(
                        label: 'Gross Sphere Power',
                        value: _grossSphere,
                        min: -15.0,
                        max: 15.0,
                        divisions: 120,
                        color: Colors.blue,
                        onChanged: (v) => setState(() => _grossSphere = (v * 4).round() / 4),
                      ),
                      _buildSlider(
                        label: 'Gross Cylinder Power',
                        value: _grossCylinder,
                        min: -8.0,
                        max: 8.0,
                        divisions: 64,
                        color: Colors.orange,
                        onChanged: (v) => setState(() => _grossCylinder = (v * 4).round() / 4),
                      ),
                      _buildSlider(
                        label: 'Cylinder Axis',
                        value: _grossAxis,
                        min: 1.0,
                        max: 180.0,
                        divisions: 179,
                        color: Colors.purple,
                        isDegree: true,
                        onChanged: (v) => setState(() => _grossAxis = v.roundToDouble()),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Working Distance Selector Card
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
                          'Working Distance Compensation (-WD)',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
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
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Retinoscopy Net Answer Card
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Colors.greenAccent, width: 1.5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.verified, color: Colors.greenAccent),
                        SizedBox(width: 8),
                        Text(
                          '🎯 Final Net Retinoscopy Answers',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    _buildResultRow(
                      'Plus Cylinder Form (+Cyl)',
                      '${plusSphere > 0 ? '+' : ''}${plusSphere.toStringAsFixed(2)} DS / ${plusCylinder > 0 ? '+' : ''}${plusCylinder.toStringAsFixed(2)} DC × ${plusAxis.toInt()}°',
                      Colors.greenAccent,
                    ),
                    const Divider(height: 16),

                    _buildResultRow(
                      'Minus Cylinder Form (-Cyl)',
                      '${minusSphere > 0 ? '+' : ''}${minusSphere.toStringAsFixed(2)} DS / ${minusCylinder > 0 ? '+' : ''}${minusCylinder.toStringAsFixed(2)} DC × ${minusAxis.toInt()}°',
                      Colors.orangeAccent,
                    ),
                    const Divider(height: 16),

                    _buildResultRow(
                      'Spherical Equivalent (SE)',
                      '${sphericalEquivalent > 0 ? '+' : ''}${sphericalEquivalent.toStringAsFixed(2)} DS',
                      Colors.cyanAccent,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Dynamic 2-Meridian Power Cross
            PowerCrossView(
              sphere: minusSphere,
              cylinder: minusCylinder,
              axis: minusAxis,
              workingDistance: _workingDistance,
            ),
            const SizedBox(height: 16),

            // Step-by-Step Clinical Calculation Walkthrough
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.format_list_numbered, color: Colors.blueAccent, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Step-by-Step Retinoscopy Solution',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '1. Gross Neutralization:\n'
                    '   • Meridian 1 (${m1Axis.toInt()}°): ${grossM1 > 0 ? '+' : ''}${grossM1.toStringAsFixed(2)} D\n'
                    '   • Meridian 2 (${m2Axis.toInt()}°): ${grossM2 > 0 ? '+' : ''}${grossM2.toStringAsFixed(2)} D\n\n'
                    '2. Deduct Working Distance (${_workingDistance.toStringAsFixed(2)} D):\n'
                    '   • Net M1 = (${grossM1 > 0 ? '+' : ''}${grossM1.toStringAsFixed(2)}) − ${_workingDistance.toStringAsFixed(2)} = ${netM1 > 0 ? '+' : ''}${netM1.toStringAsFixed(2)} D @ ${m1Axis.toInt()}°\n'
                    '   • Net M2 = (${grossM2 > 0 ? '+' : ''}${grossM2.toStringAsFixed(2)}) − ${_workingDistance.toStringAsFixed(2)} = ${netM2 > 0 ? '+' : ''}${netM2.toStringAsFixed(2)} D @ ${m2Axis.toInt()}°\n\n'
                    '3. Plus-Cylinder Prescription (+Cyl Form):\n'
                    '   • Select more negative / least positive meridian as base sphere:\n'
                    '     Base Sphere = ${plusSphere > 0 ? '+' : ''}${plusSphere.toStringAsFixed(2)} DS (@ ${plusAxis.toInt()}°)\n'
                    '   • Add positive difference as cylinder along base axis:\n'
                    '     Cylinder = ${plusCylinder > 0 ? '+' : ''}${plusCylinder.toStringAsFixed(2)} DC × ${plusAxis.toInt()}°\n'
                    '   • Prescription: ${plusSphere > 0 ? '+' : ''}${plusSphere.toStringAsFixed(2)} DS / ${plusCylinder > 0 ? '+' : ''}${plusCylinder.toStringAsFixed(2)} DC × ${plusAxis.toInt()}°\n\n'
                    '4. Minus-Cylinder Prescription (-Cyl Form):\n'
                    '   • Select more positive / least negative meridian as base sphere:\n'
                    '     Base Sphere = ${minusSphere > 0 ? '+' : ''}${minusSphere.toStringAsFixed(2)} DS (@ ${minusAxis.toInt()}°)\n'
                    '   • Subtract difference as negative cylinder along base axis:\n'
                    '     Cylinder = ${minusCylinder.toStringAsFixed(2)} DC × ${minusAxis.toInt()}°\n'
                    '   • Prescription: ${minusSphere > 0 ? '+' : ''}${minusSphere.toStringAsFixed(2)} DS / ${minusCylinder.toStringAsFixed(2)} DC × ${minusAxis.toInt()}°',
                    style: TextStyle(fontSize: 12.5, height: 1.5, color: isDark ? Colors.white70 : Colors.black87),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Keratometry (K-Readings) & Javal's Rule Calculator ─────────
            _buildKeratometryCard(),
            const SizedBox(height: 16),

            // ── Zernike Wavefront & Optical Quality (Strehl Ratio) ─────────
            _buildZernikeAberrationCard(sphericalEquivalent, minusCylinder),
            const SizedBox(height: 16),
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
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: colorScheme.onSurface)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
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

  Widget _buildKeratometryCard() {
    final double deltaK = _k2 - _k1;
    final double radius1 = 337.5 / _k1;
    final double radius2 = 337.5 / _k2;
    // Javal's Rule: Total Astigmatism = 1.25 * DeltaK - 0.50 D ATR
    final double javalsAstigmatism = 1.25 * deltaK - 0.50;
    final double steepAxis = (_k1Axis + 90.0) > 180.0 ? _k1Axis - 90.0 : _k1Axis + 90.0;

    String astigmatismClass = 'Spherical Cornea';
    Color badgeColor = Colors.teal;
    if (deltaK.abs() > 0.12) {
      if ((_k1Axis <= 30 || _k1Axis >= 150) && deltaK > 0) {
        astigmatismClass = 'With-The-Rule (WTR)';
        badgeColor = Colors.green;
      } else if ((_k1Axis >= 60 && _k1Axis <= 120) && deltaK > 0) {
        astigmatismClass = 'Against-The-Rule (ATR)';
        badgeColor = Colors.red;
      } else {
        astigmatismClass = 'Oblique Astigmatism';
        badgeColor = Colors.purple;
      }
    }

    return Card(
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
                const Row(
                  children: [
                    Icon(Icons.remove_red_eye_outlined, color: Colors.teal),
                    SizedBox(width: 8),
                    Text(
                      'Corneal Keratometry (K-Readings)',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: badgeColor.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    astigmatismClass,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: badgeColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSlider(
              label: 'K1 (Flat Meridian Power)',
              value: _k1,
              min: 38.0,
              max: 52.0,
              divisions: 56,
              color: Colors.teal,
              onChanged: (v) => setState(() => _k1 = (v * 4).round() / 4),
            ),
            _buildSlider(
              label: 'K1 Axis (Flat Meridian)',
              value: _k1Axis,
              min: 1.0,
              max: 180.0,
              divisions: 179,
              color: Colors.teal,
              isDegree: true,
              onChanged: (v) => setState(() => _k1Axis = v.roundToDouble()),
            ),
            _buildSlider(
              label: 'K2 (Steep Meridian Power)',
              value: _k2,
              min: 38.0,
              max: 52.0,
              divisions: 56,
              color: Colors.cyan,
              onChanged: (v) => setState(() => _k2 = (v * 4).round() / 4),
            ),
            const SizedBox(height: 12),
            _buildResultRow(
              'K1 Reading',
              '${_k1.toStringAsFixed(2)} D @ ${_k1Axis.toInt()}° (${radius1.toStringAsFixed(2)} mm)',
              Colors.teal,
            ),
            const Divider(height: 14),
            _buildResultRow(
              'K2 Reading',
              '${_k2.toStringAsFixed(2)} D @ ${steepAxis.toInt()}° (${radius2.toStringAsFixed(2)} mm)',
              Colors.cyan[700]!,
            ),
            const Divider(height: 14),
            _buildResultRow(
              'Corneal Cylinder (ΔK)',
              '${deltaK >= 0 ? '+' : ''}${deltaK.toStringAsFixed(2)} DC',
              Colors.indigo,
            ),
            const Divider(height: 14),
            _buildResultRow(
              'Javal\'s Rule Predicted Astigmatism',
              '${javalsAstigmatism >= 0 ? '+' : ''}${javalsAstigmatism.toStringAsFixed(2)} DC × ${_k1Axis.toInt()}°',
              Colors.deepOrange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZernikeAberrationCard(double sphericalEquivalent, double cylinder) {
    // Defocus RMS in µm: RMS_defocus = (pupil^2 / (16 * sqrt(3))) * |SE|
    final double rmsDefocus = (_pupilDiameter * _pupilDiameter / (16.0 * math.sqrt(3))) * sphericalEquivalent.abs();
    // Astigmatism RMS in µm: RMS_astig = (pupil^2 / (16 * sqrt(6))) * cylinder.abs()
    final double rmsAstig = (_pupilDiameter * _pupilDiameter / (16.0 * math.sqrt(6))) * cylinder.abs();
    // Total Wavefront Error RMS in µm:
    final double totalRms = math.sqrt((rmsDefocus * rmsDefocus) + (rmsAstig * rmsAstig) + (_sphericalAberrationZ40 * _sphericalAberrationZ40));
    // Strehl Ratio using Maréchal approximation (for green light λ = 0.55 µm):
    final double phaseVariance = (2.0 * math.pi * totalRms / 0.55);
    final double strehlRatio = math.exp(-phaseVariance * phaseVariance).clamp(0.01, 1.00);

    String qualityText;
    Color qualityColor;
    if (strehlRatio >= 0.80) {
      qualityText = 'Diffraction-Limited (20/15 Acuity)';
      qualityColor = Colors.green;
    } else if (strehlRatio >= 0.40) {
      qualityText = 'Good Visual Acuity (20/20 - 20/25)';
      qualityColor = Colors.teal;
    } else if (strehlRatio >= 0.15) {
      qualityText = 'Moderate Wavefront Blur (20/30 - 20/50)';
      qualityColor = Colors.amber.shade800;
    } else {
      qualityText = 'Significant Optical Blur (Neutralization Required)';
      qualityColor = Colors.red;
    }

    return Card(
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
                const Row(
                  children: [
                    Icon(Icons.blur_on, color: Colors.purple),
                    SizedBox(width: 8),
                    Text(
                      'Wavefront Aberrations & Strehl Ratio',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: qualityColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: qualityColor.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    'Strehl ${(strehlRatio * 100).toStringAsFixed(1)}%',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: qualityColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildSlider(
              label: 'Pupil Diameter (Entrance Pupil)',
              value: _pupilDiameter,
              min: 2.0,
              max: 8.0,
              divisions: 24,
              color: Colors.purple,
              onChanged: (v) => setState(() => _pupilDiameter = (v * 4).round() / 4),
            ),
            _buildSlider(
              label: 'Spherical Aberration Z(4,0) HOA',
              value: _sphericalAberrationZ40,
              min: 0.0,
              max: 0.50,
              divisions: 50,
              color: Colors.deepPurple,
              onChanged: (v) => setState(() => _sphericalAberrationZ40 = (v * 100).round() / 100),
            ),
            const SizedBox(height: 10),
            _buildResultRow(
              'Total Wavefront RMS Error',
              '${totalRms.toStringAsFixed(3)} µm',
              Colors.purple,
            ),
            const Divider(height: 14),
            _buildResultRow(
              'Lower-Order Defocus RMS (Z2,0)',
              '${rmsDefocus.toStringAsFixed(3)} µm',
              Colors.indigo,
            ),
            const Divider(height: 14),
            _buildResultRow(
              'Astigmatic RMS (Z2,±2)',
              '${rmsAstig.toStringAsFixed(3)} µm',
              Colors.teal,
            ),
            const Divider(height: 14),
            _buildResultRow(
              'Optical Quality Index',
              qualityText,
              qualityColor,
            ),
          ],
        ),
      ),
    );
  }
}

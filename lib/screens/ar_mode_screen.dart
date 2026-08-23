import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// AR Mode Screen — JMR Technologies Retinoscopy Simulator
///
/// Camera overlay concept screen for retinoscope training.
/// Shows live camera feed with a retinoscopy teaching overlay grid.
/// On devices where camera is unavailable, shows a detailed diagram.
///
/// Note: Full AR integration requires camera permissions in AndroidManifest.xml
/// and entitlements on iOS. This screen provides the UX framework and
/// a clinical overlay system ready for camera integration.
class ARModeScreen extends StatefulWidget {
  const ARModeScreen({super.key});

  @override
  State<ARModeScreen> createState() => _ARModeScreenState();
}

class _ARModeScreenState extends State<ARModeScreen>
    with TickerProviderStateMixin {
  bool _overlayEnabled = true;
  bool _gridEnabled = true;
  bool _reticleEnabled = true;
  double _streakAngle = 0.0;
  String _selectedGuide = 'Neutrality';
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late Animation<double> _pulseAnim;

  final List<String> _guides = [
    'Neutrality',
    'With Motion',
    'Against Motion',
    'Scissors',
    'Astigmatism',
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    // Lock to landscape for AR view
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    // Restore orientations
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Camera Feed Placeholder ─────────────────────────────────────
          _buildCameraBackground(),

          // ── AR Overlay ──────────────────────────────────────────────────
          if (_overlayEnabled) _buildAROverlay(),

          // ── Top Controls Bar ────────────────────────────────────────────
          SafeArea(child: _buildTopBar()),

          // ── Bottom Panel ────────────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 0.8,
          colors: [Color(0xFF1A1A2E), Color(0xFF0D0D0D)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_outlined, size: 48, color: Colors.white.withValues(alpha: 0.2)),
            const SizedBox(height: 12),
            Text(
              'CAMERA FEED',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.15),
                letterSpacing: 4,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Point retinoscope at patient\'s eye',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.1),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAROverlay() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cx = constraints.maxWidth / 2;
        final cy = constraints.maxHeight / 2;
        return Stack(
          children: [
            // Crosshair grid
            if (_gridEnabled) CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: _ARGridPainter(),
            ),

            // Pupil reticle (animated pulse)
            if (_reticleEnabled) Positioned(
              left: cx - 75,
              top: cy - 75,
              child: ScaleTransition(
                scale: _pulseAnim,
                child: CustomPaint(
                  size: const Size(150, 150),
                  painter: _PupilReticlePainter(guideType: _selectedGuide),
                ),
              ),
            ),

            // Rotating streak indicator
            Positioned(
              left: cx - 40,
              top: cy - 40,
              child: RotationTransition(
                turns: Tween<double>(begin: 0, end: 1).animate(_rotateController),
                child: Opacity(
                  opacity: 0.6,
                  child: CustomPaint(
                    size: const Size(80, 80),
                    painter: _StreakPainter(angle: _streakAngle),
                  ),
                ),
              ),
            ),

            // Guide label (top right of reticle)
            Positioned(
              left: cx + 80,
              top: cy - 90,
              child: _buildGuideLabel(),
            ),

            // Measurement annotations
            Positioned(
              left: 20,
              top: cy - 20,
              child: _buildAnnotation('← AXIS ${_streakAngle.toStringAsFixed(0)}°'),
            ),
            Positioned(
              right: 20,
              top: cy - 20,
              child: _buildAnnotation('WD 0.67m →'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGuideLabel() {
    final Map<String, Color> guideColors = {
      'Neutrality': Colors.green,
      'With Motion': Colors.blue,
      'Against Motion': Colors.red,
      'Scissors': Colors.orange,
      'Astigmatism': Colors.purple,
    };
    final Color color = guideColors[_selectedGuide] ?? Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Text(
        _selectedGuide,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildAnnotation(String text) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.5),
        fontSize: 11,
        fontFamily: 'monospace',
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Back button
          _buildIconChip(Icons.arrow_back, () => Navigator.of(context).pop()),
          const SizedBox(width: 8),
          // Title
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(Icons.fiber_manual_record, color: Colors.red, size: 8),
                SizedBox(width: 6),
                Text('AR TRAINER', style: TextStyle(color: Colors.white, fontSize: 12, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Spacer(),
          // Overlay toggle
          _buildToggleChip('Overlay', _overlayEnabled, (v) => setState(() => _overlayEnabled = v)),
          const SizedBox(width: 8),
          _buildToggleChip('Grid', _gridEnabled, (v) => setState(() => _gridEnabled = v)),
          const SizedBox(width: 8),
          _buildToggleChip('Reticle', _reticleEnabled, (v) => setState(() => _reticleEnabled = v)),
        ],
      ),
    );
  }

  Widget _buildIconChip(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(19),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  Widget _buildToggleChip(String label, bool value, ValueChanged<bool> onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: value ? Colors.blue.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: value ? Colors.blue : Colors.white.withValues(alpha: 0.2)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: value ? Colors.blue[300] : Colors.white.withValues(alpha: 0.5),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomPanel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black.withValues(alpha: 0.9), Colors.transparent],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Guide selector
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _guides.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final selected = _guides[i] == _selectedGuide;
                return GestureDetector(
                  onTap: () => setState(() => _selectedGuide = _guides[i]),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected ? Colors.blue.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: selected ? Colors.blue : Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Text(
                      _guides[i],
                      style: TextStyle(
                        color: selected ? Colors.white : Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          // Streak angle slider
          Row(
            children: [
              Text('Streak', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11)),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: Colors.blue,
                    thumbColor: Colors.white,
                    inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
                    trackHeight: 2,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  ),
                  child: Slider(
                    value: _streakAngle,
                    min: 0,
                    max: 180,
                    onChanged: (v) => setState(() => _streakAngle = v),
                  ),
                ),
              ),
              Text('${_streakAngle.toStringAsFixed(0)}°',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11, fontFamily: 'monospace')),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom Painters
// ─────────────────────────────────────────────────────────────────────────────

class _ARGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 0.5;

    // Vertical lines
    for (double x = 0; x < size.width; x += 60) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    // Horizontal lines
    for (double y = 0; y < size.height; y += 60) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Center crosshair (brighter)
    final crossPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(size.width / 2, 0), Offset(size.width / 2, size.height), crossPaint);
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), crossPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PupilReticlePainter extends CustomPainter {
  final String guideType;
  _PupilReticlePainter({required this.guideType});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final Map<String, Color> guideColors = {
      'Neutrality': Colors.green,
      'With Motion': Colors.blue,
      'Against Motion': Colors.red,
      'Scissors': Colors.orange,
      'Astigmatism': Colors.purple,
    };
    final Color color = guideColors[guideType] ?? Colors.white;

    // Outer ring
    canvas.drawCircle(center, radius - 2, Paint()
      ..color = color.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0);

    // Inner ring
    canvas.drawCircle(center, radius * 0.6, Paint()
      ..color = color.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0);

    // Center dot
    canvas.drawCircle(center, 4, Paint()..color = color.withValues(alpha: 0.8));

    // Cardinal tick marks
    final tickPaint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..strokeWidth = 1.5;
    for (int i = 0; i < 4; i++) {
      final angle = i * 3.14159 / 2;
      final x1 = center.dx + (radius - 12) * _cos(angle);
      final y1 = center.dy + (radius - 12) * _sin(angle);
      final x2 = center.dx + radius * _cos(angle);
      final y2 = center.dy + radius * _sin(angle);
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), tickPaint);
    }
  }

  double _cos(double r) => r == 0 ? 1 : r == 3.14159 ? -1 : r == 1.5708 ? 0 : r == 4.7124 ? 0 : _cosCalc(r);
  double _sin(double r) => r == 0 ? 0 : r == 3.14159 ? 0 : r == 1.5708 ? 1 : r == 4.7124 ? -1 : _sinCalc(r);
  double _cosCalc(double r) { double s = 0, t = 1; for (int i = 1; i <= 10; i++) { t *= -r * r / (2 * i * (2 * i - 1)); s += t; } return 1 + s; }
  double _sinCalc(double r) { double s = r, t = r; for (int i = 1; i <= 10; i++) { t *= -r * r / ((2 * i + 1) * 2 * i); s += t; } return s; }

  @override
  bool shouldRepaint(covariant _PupilReticlePainter old) => old.guideType != guideType;
}

class _StreakPainter extends CustomPainter {
  final double angle;
  _StreakPainter({required this.angle});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = Colors.yellow.withValues(alpha: 0.7)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(center.dx, 0),
      Offset(center.dx, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _StreakPainter old) => old.angle != angle;
}

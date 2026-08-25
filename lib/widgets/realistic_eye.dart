import 'dart:math' as math;
import 'package:flutter/material.dart';

class RealisticEye extends StatefulWidget {
  final double beamPosition;
  final double streakAngle;
  final double reflexWidth;
  final double reflexAngle;
  final double retinaOpacity;
  final double reflectionOpacity;
  final String reflexMotion;
  final bool pupilDilated;
  final bool scissorsMotionActive;
  final double cataractDensity;
  final double cornealOpacity;
  final double breakDisplacementAngle;
  final double velocityFactor;
  final double illuminance;

  final double pupilApertureRatio;
  final double fundusLuminanceMultiplier;

  const RealisticEye({
    super.key,
    required this.beamPosition,
    required this.streakAngle,
    required this.reflexWidth,
    required this.reflexAngle,
    required this.retinaOpacity,
    required this.reflectionOpacity,
    required this.reflexMotion,
    required this.pupilDilated,
    required this.scissorsMotionActive,
    this.cataractDensity = 0.0,
    this.cornealOpacity = 0.0,
    this.breakDisplacementAngle = 0.0,
    this.velocityFactor = 1.0,
    this.illuminance = 1.0,
    this.pupilApertureRatio = 0.52,
    this.fundusLuminanceMultiplier = 1.0,
  });

  @override
  State<RealisticEye> createState() => _RealisticEyeState();
}

class _RealisticEyeState extends State<RealisticEye> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _smoothSweepController;
  double _currentRenderedBeam = 0.0;

  @override
  void initState() {
    super.initState();
    _currentRenderedBeam = widget.beamPosition;

    // Physiological pupil oscillation (hippus)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    // Continuous 60/120 FPS high-refresh physics interpolation for silky-smooth beam sweep
    _smoothSweepController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(_updatePhysicsSmoothing);

    _smoothSweepController.repeat();
  }

  void _updatePhysicsSmoothing() {
    final double target = widget.beamPosition;
    final double diff = target - _currentRenderedBeam;
    if (diff.abs() > 0.01) {
      setState(() {
        // Smooth exponential damping for physical optical beam momentum
        _currentRenderedBeam += diff * 0.42;
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _smoothSweepController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(300, 300),
          painter: EyePainter(
            beamPosition: _currentRenderedBeam,
            streakAngle: widget.streakAngle,
            reflexWidth: widget.reflexWidth,
            reflexAngle: widget.reflexAngle,
            retinaOpacity: widget.retinaOpacity,
            reflectionOpacity: widget.reflectionOpacity,
            reflexMotion: widget.reflexMotion,
            hippusFactor: 0.95 + (0.1 * _pulseController.value),
            pupilDilated: widget.pupilDilated,
            scissorsMotionActive: widget.scissorsMotionActive,
            cataractDensity: widget.cataractDensity,
            cornealOpacity: widget.cornealOpacity,
            breakDisplacementAngle: widget.breakDisplacementAngle,
            velocityFactor: widget.velocityFactor,
            illuminance: widget.illuminance,
            pupilApertureRatio: widget.pupilApertureRatio,
            fundusLuminanceMultiplier: widget.fundusLuminanceMultiplier,
          ),
        );
      },
    );
  }
}

class EyePainter extends CustomPainter {
  final double beamPosition;
  final double streakAngle;
  final double reflexWidth;
  final double reflexAngle;
  final double retinaOpacity;
  final double reflectionOpacity;
  final String reflexMotion;
  final double hippusFactor;
  final bool pupilDilated;
  final bool scissorsMotionActive;
  final double cataractDensity;
  final double cornealOpacity;
  final double breakDisplacementAngle;
  final double velocityFactor;
  final double illuminance;
  final double pupilApertureRatio;
  final double fundusLuminanceMultiplier;

  EyePainter({
    required this.beamPosition,
    required this.streakAngle,
    required this.reflexWidth,
    required this.reflexAngle,
    required this.retinaOpacity,
    required this.reflectionOpacity,
    required this.reflexMotion,
    required this.hippusFactor,
    required this.pupilDilated,
    required this.scissorsMotionActive,
    this.cataractDensity = 0.0,
    this.cornealOpacity = 0.0,
    this.breakDisplacementAngle = 0.0,
    this.velocityFactor = 1.0,
    this.illuminance = 1.0,
    this.pupilApertureRatio = 0.52,
    this.fundusLuminanceMultiplier = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.min(size.width, size.height) / 2;

    // 1. Draw Sclera (White of the eye with realistic spherical shading & subtle capillaries)
    final scleraPaint = Paint()
      ..shader = RadialGradient(
        colors: const [
          Color(0xFFFCFDFD),
          Color(0xFFEBEFF2),
          Color(0xFFCBD5E1),
        ],
        stops: const [0.65, 0.88, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: maxRadius));
    canvas.drawCircle(center, maxRadius, scleraPaint);

    final capillaryPaint = Paint()
      ..color = const Color(0xFFEF9A9A).withValues(alpha: 0.28)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 6; i++) {
      double a = (i * 60.0 + 20) * math.pi / 180;
      canvas.drawLine(
        Offset(center.dx + maxRadius * 0.72 * math.cos(a), center.dy + maxRadius * 0.72 * math.sin(a)),
        Offset(center.dx + maxRadius * 0.96 * math.cos(a + 0.1), center.dy + maxRadius * 0.96 * math.sin(a + 0.1)),
        capillaryPaint,
      );
    }

    // 2. Draw Iris (Detailed crypts, collarette & radial trabecular fibers)
    final irisRadius = maxRadius * 0.65;
    final irisPaint = Paint()
      ..shader = RadialGradient(
        colors: const [
          Color(0xFF1E3A8A),
          Color(0xFF1E40AF),
          Color(0xFF0F172A), // Limbal ring shadow
        ],
        stops: const [0.0, 0.85, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: irisRadius));
    canvas.drawCircle(center, irisRadius, irisPaint);

    final fiberPaint = Paint()
      ..color = const Color(0xFF93C5FD).withValues(alpha: 0.16)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 36; i++) {
      double rad = (i * 10) * math.pi / 180;
      canvas.drawLine(
        Offset(center.dx + irisRadius * 0.42 * math.cos(rad), center.dy + irisRadius * 0.42 * math.sin(rad)),
        Offset(center.dx + irisRadius * 0.95 * math.cos(rad), center.dy + irisRadius * 0.95 * math.sin(rad)),
        fiberPaint,
      );
    }

    // 3. Draw Pupil (Black aperture) with physiological light reflex constriction
    final double pupilRadius;
    if (pupilDilated) {
      pupilRadius = irisRadius * (pupilApertureRatio * 1.55).clamp(0.75, 0.94);
    } else {
      double plrIntensity = (1.0 - (beamPosition.abs() / 55.0)).clamp(0.0, 1.0);
      double plrConstriction = 1.0 - 0.14 * plrIntensity;
      pupilRadius = irisRadius * pupilApertureRatio * hippusFactor * plrConstriction;
    }

    final pupilBgPaint = Paint()..color = const Color(0xFF0A0A0A);
    canvas.drawCircle(center, pupilRadius, pupilBgPaint);

    // Save canvas state and clip all fundus reflex rendering to the pupil aperture
    canvas.save();
    final pupilPath = Path()..addOval(Rect.fromCircle(center: center, radius: pupilRadius));
    canvas.clipPath(pupilPath);

    // 4. Draw Choroidal Backscatter Base Glow (Deep Red-Orange Retro-Illumination)
    // Backscatter intensifies when the retinoscope beam aligns centrally over the pupil
    double beamProximity = (1.0 - (beamPosition.abs() / (pupilRadius * 1.6))).clamp(0.0, 1.0);
    double dynamicChoroidGlow = (retinaOpacity * fundusLuminanceMultiplier * (0.92 + 0.45 * beamProximity)).clamp(0.15, 1.0);

    final retinaGlowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFF5722).withValues(alpha: dynamicChoroidGlow), // Brilliant incandescent scarlet
          const Color(0xFFE53935).withValues(alpha: dynamicChoroidGlow * 0.95),
          const Color(0xFFC62828).withValues(alpha: dynamicChoroidGlow * 0.85),
          const Color(0xFF880E4F).withValues(alpha: dynamicChoroidGlow * 0.55),
          const Color(0xFF311B92).withValues(alpha: dynamicChoroidGlow * 0.20),
          Colors.black,
        ],
        stops: const [0.0, 0.35, 0.60, 0.80, 0.94, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: pupilRadius));
    canvas.drawCircle(center, pupilRadius, retinaGlowPaint);

    // 5. Advanced Shader-Based Fundus Reflex Dynamics
    if (reflexMotion == "neutral") {
      // 🌟 FULL PUPILLARY CAVITY NEUTRALITY FLASH (100% Aperture Fill)
      final double peakLuminance = (reflectionOpacity * illuminance * fundusLuminanceMultiplier * 1.25).clamp(0.30, 1.0);
      final neutralFlashPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFFFFF).withValues(alpha: peakLuminance), // Incandescent white-hot center
            const Color(0xFFFFF59D).withValues(alpha: peakLuminance),
            const Color(0xFFFFD54F).withValues(alpha: (peakLuminance * 0.96).clamp(0.0, 1.0)),
            const Color(0xFFFF9800).withValues(alpha: (peakLuminance * 0.88).clamp(0.0, 1.0)),
            const Color(0xFFE64A19).withValues(alpha: (peakLuminance * 0.68).clamp(0.0, 1.0)),
            const Color(0xFFC62828).withValues(alpha: (peakLuminance * 0.35).clamp(0.0, 1.0)),
          ],
          stops: const [0.0, 0.22, 0.45, 0.68, 0.88, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: pupilRadius));
      canvas.drawCircle(center, pupilRadius, neutralFlashPaint);
    } else {
      double motionDirection = reflexMotion == "against" ? -1.0 : 1.0;
      double sweepAngleRad = (streakAngle - 90) * math.pi / 180;

      // Physically simulated non-linear velocity displacement
      double reflexOffset = beamPosition * motionDirection * (0.34 * velocityFactor);

      final reflexCenter = Offset(
        center.dx + reflexOffset * math.cos(sweepAngleRad),
        center.dy + reflexOffset * math.sin(sweepAngleRad),
      );

      final double peakOpacity = (reflectionOpacity * illuminance * fundusLuminanceMultiplier * 1.35).clamp(0.20, 1.0);
      double rWidth = reflexWidth.abs().clamp(5.0, pupilRadius * 2.8);

      // Multi-Stop Optical Gaussian Beam Profile Shader (Vivid Gold-Orange-White Filament with High Radiance)
      final reflexPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            const Color(0xFFC62828).withValues(alpha: 0.0),
            const Color(0xFFE64A19).withValues(alpha: (peakOpacity * 0.45).clamp(0.0, 1.0)),
            const Color(0xFFFF6D00).withValues(alpha: (peakOpacity * 0.80).clamp(0.0, 1.0)),
            const Color(0xFFFFD54F).withValues(alpha: (peakOpacity * 0.96).clamp(0.0, 1.0)),
            const Color(0xFFFFFFFF).withValues(alpha: peakOpacity), // Incandescent white filament core
            const Color(0xFFFFD54F).withValues(alpha: (peakOpacity * 0.96).clamp(0.0, 1.0)),
            const Color(0xFFFF6D00).withValues(alpha: (peakOpacity * 0.80).clamp(0.0, 1.0)),
            const Color(0xFFE64A19).withValues(alpha: (peakOpacity * 0.45).clamp(0.0, 1.0)),
            const Color(0xFFC62828).withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.10, 0.26, 0.42, 0.50, 0.58, 0.74, 0.90, 1.0],
        ).createShader(Rect.fromCenter(center: Offset.zero, width: rWidth, height: pupilRadius * 3.5));

      if (scissorsMotionActive) {
        // Scissors Blade 1 (Dynamic dual-split aberration)
        double angle1 = (reflexAngle - 90) + breakDisplacementAngle + (beamPosition * 0.22);
        canvas.save();
        canvas.translate(reflexCenter.dx, reflexCenter.dy);
        canvas.rotate(angle1 * math.pi / 180);
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: rWidth, height: pupilRadius * 3.5),
          reflexPaint,
        );
        canvas.restore();

        // Scissors Blade 2 (Opposing blade crossing toward center)
        double angle2 = (reflexAngle - 90) + breakDisplacementAngle - (beamPosition * 0.22);
        final reflexCenter2 = Offset(
          center.dx - reflexOffset * math.cos(sweepAngleRad),
          center.dy - reflexOffset * math.sin(sweepAngleRad),
        );
        canvas.save();
        canvas.translate(reflexCenter2.dx, reflexCenter2.dy);
        canvas.rotate(angle2 * math.pi / 180);
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: rWidth, height: pupilRadius * 3.5),
          reflexPaint,
        );
        canvas.restore();
      } else {
        // Standard streak reflex with physical Break Phenomenon meridional tilt
        double effectiveAngle = (reflexAngle - 90) + breakDisplacementAngle;
        canvas.save();
        canvas.translate(reflexCenter.dx, reflexCenter.dy);
        canvas.rotate(effectiveAngle * math.pi / 180);
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: rWidth, height: pupilRadius * 3.5),
          reflexPaint,
        );
        canvas.restore();
      }
    }

    // 6. Draw Media Opacities (Cataract & Corneal Scars within aperture)
    if (cataractDensity > 0.0) {
      final cataractPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF4E342E).withValues(alpha: cataractDensity * 0.85),
            const Color(0xFFFF8F00).withValues(alpha: cataractDensity * 0.60),
            const Color(0xFFE65100).withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.65, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: pupilRadius * 0.95));
      canvas.drawCircle(center, pupilRadius * 0.95, cataractPaint);
    }

    canvas.restore(); // Restore from pupil clipping mask

    // 7. Anterior Corneal Scar (if simulated)
    if (cornealOpacity > 0.0) {
      final scarPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: cornealOpacity * 0.78),
            const Color(0xFFEEEEEE).withValues(alpha: cornealOpacity * 0.45),
            Colors.white.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromCircle(
          center: Offset(center.dx + pupilRadius * 0.25, center.dy - pupilRadius * 0.2),
          radius: pupilRadius * 0.8,
        ));
      canvas.drawCircle(
        Offset(center.dx + pupilRadius * 0.25, center.dy - pupilRadius * 0.2),
        pupilRadius * 0.8,
        scarPaint,
      );
    }

    // 8. Dynamic 3D Purkinje Corneal Highlight with subtle sweep parallax
    double parallaxOffset = (beamPosition / (pupilRadius * 2.0)).clamp(-0.15, 0.15);
    final highlightCenter = Offset(
      center.dx - pupilRadius * (0.4 - parallaxOffset),
      center.dy - pupilRadius * (0.4 - parallaxOffset),
    );

    final highlightPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.88),
          Colors.white.withValues(alpha: 0.22),
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(
        center: highlightCenter,
        radius: pupilRadius * 0.35,
      ));

    canvas.drawCircle(
      highlightCenter,
      pupilRadius * 0.35,
      highlightPaint,
    );

    // 9. 🌟 Optical Conjugacy Limbus Ring (Glows softly when Neutral Point is achieved)
    if (reflexMotion == "neutral") {
      final limbusRingPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..shader = SweepGradient(
          colors: [
            const Color(0xFFFFD54F).withValues(alpha: 0.0),
            const Color(0xFFFFE082).withValues(alpha: 0.85),
            const Color(0xFFFFF9C4).withValues(alpha: 0.95),
            const Color(0xFFFFE082).withValues(alpha: 0.85),
            const Color(0xFFFFD54F).withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.25, 0.50, 0.75, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: irisRadius * 1.03));
      canvas.drawCircle(center, irisRadius * 1.03, limbusRingPaint);
    }
  }

  @override
  bool shouldRepaint(covariant EyePainter oldDelegate) {
    return oldDelegate.beamPosition != beamPosition ||
        oldDelegate.streakAngle != streakAngle ||
        oldDelegate.reflexWidth != reflexWidth ||
        oldDelegate.reflexAngle != reflexAngle ||
        oldDelegate.retinaOpacity != retinaOpacity ||
        oldDelegate.reflectionOpacity != reflectionOpacity ||
        oldDelegate.reflexMotion != reflexMotion ||
        oldDelegate.hippusFactor != hippusFactor ||
        oldDelegate.pupilDilated != pupilDilated ||
        oldDelegate.scissorsMotionActive != scissorsMotionActive ||
        oldDelegate.cataractDensity != cataractDensity ||
        oldDelegate.cornealOpacity != cornealOpacity ||
        oldDelegate.breakDisplacementAngle != breakDisplacementAngle ||
        oldDelegate.velocityFactor != velocityFactor ||
        oldDelegate.illuminance != illuminance;
  }
}


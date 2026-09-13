import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

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
  final double skewShearFactor;
  final double velocityFactor;
  final double illuminance;
  final double pupilFillRatio;

  final double pupilApertureRatio;
  final double fundusLuminanceMultiplier;
  final Color streakColor;

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
    this.skewShearFactor = 0.0,
    this.velocityFactor = 1.0,
    this.illuminance = 1.0,
    this.pupilFillRatio = 0.35,
    this.pupilApertureRatio = 0.52,
    this.fundusLuminanceMultiplier = 1.0,
    this.streakColor = Colors.deepOrangeAccent,
    this.enableAccelerometerTilt = false,
  });

  final bool enableAccelerometerTilt;

  @override
  State<RealisticEye> createState() => _RealisticEyeState();
}

class _RealisticEyeState extends State<RealisticEye> with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _pulseController;
  late AnimationController _smoothSweepController;
  double _currentRenderedBeam = 0.0;

  StreamSubscription<AccelerometerEvent>? _accelSubscription;
  double _tiltX = 0.0;
  double _tiltY = 0.0;
  bool _isAppActive = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentRenderedBeam = widget.beamPosition;

    if (widget.enableAccelerometerTilt) {
      _startSensors();
    }

    // Physiological pupil oscillation (hippus)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    // Continuous physics interpolation for silky-smooth beam sweep
    _smoothSweepController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(_updatePhysicsSmoothing);

    _smoothSweepController.repeat();
  }

  @override
  void didUpdateWidget(RealisticEye oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enableAccelerometerTilt != oldWidget.enableAccelerometerTilt) {
      if (widget.enableAccelerometerTilt) {
        _startSensors();
      } else {
        _stopSensors();
        if (_tiltX != 0.0 || _tiltY != 0.0) {
          setState(() {
            _tiltX = 0.0;
            _tiltY = 0.0;
          });
        }
      }
    }
  }

  void _startSensors() {
    _stopSensors();
    if (!widget.enableAccelerometerTilt) return;
    _accelSubscription = accelerometerEventStream().listen((AccelerometerEvent event) {
      if (!mounted || !_isAppActive || !widget.enableAccelerometerTilt) return;
      // Accelerometer X is left/right tilt, Y is up/down tilt.
      final double targetTiltX = _tiltX + (event.x.clamp(-3.0, 3.0) - _tiltX) * 0.1;
      final double targetTiltY = _tiltY + (event.y.clamp(-3.0, 3.0) - _tiltY) * 0.1;

      // Throttle sensor updates: only trigger UI rebuild if angular change is clinically perceptible
      if ((targetTiltX - _tiltX).abs() > 0.015 || (targetTiltY - _tiltY).abs() > 0.015) {
        setState(() {
          _tiltX = targetTiltX;
          _tiltY = targetTiltY;
        });
      }
    });
  }

  void _stopSensors() {
    _accelSubscription?.cancel();
    _accelSubscription = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _isAppActive = true;
      _startSensors();
      if (!_pulseController.isAnimating) _pulseController.repeat(reverse: true);
      if (!_smoothSweepController.isAnimating) _smoothSweepController.repeat();
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive || state == AppLifecycleState.hidden) {
      _isAppActive = false;
      _stopSensors();
      if (_pulseController.isAnimating) _pulseController.stop();
      if (_smoothSweepController.isAnimating) _smoothSweepController.stop();
    }
  }

  void _updatePhysicsSmoothing() {
    if (!mounted || !_isAppActive) return;
    final double target = widget.beamPosition;
    final double diff = target - _currentRenderedBeam;
    if (diff.abs() > 0.005) {
      setState(() {
        // Smooth exponential damping for physical optical beam momentum
        _currentRenderedBeam += diff * 0.42;
      });
    } else if (_currentRenderedBeam != target) {
      setState(() {
        _currentRenderedBeam = target;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopSensors();
    _pulseController.dispose();
    _smoothSweepController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Transform(
          alignment: FractionalOffset.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001) // perspective
            ..rotateX(-_tiltY * 0.1) // tilt up/down (inverted)
            ..rotateY(_tiltX * 0.1), // tilt left/right
          child: CustomPaint(
            size: const Size(300, 300),
            painter: EyePainter(
            streakColor: widget.streakColor,
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
            skewShearFactor: widget.skewShearFactor,
            velocityFactor: widget.velocityFactor,
            illuminance: widget.illuminance,
            pupilFillRatio: widget.pupilFillRatio,
            pupilApertureRatio: widget.pupilApertureRatio,
            fundusLuminanceMultiplier: widget.fundusLuminanceMultiplier,
          ),
        ));
      },
    );
  }
}

class EyePainter extends CustomPainter {
  final Color streakColor;
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
  final double skewShearFactor;
  final double velocityFactor;
  final double illuminance;
  final double pupilFillRatio;
  final double pupilApertureRatio;
  final double fundusLuminanceMultiplier;

  EyePainter({
    required this.streakColor,
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
    this.skewShearFactor = 0.0,
    this.velocityFactor = 1.0,
    this.illuminance = 1.0,
    this.pupilFillRatio = 0.35,
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

    // Outer Protractor Ticks (Subtle clinical degree ticks at 10° intervals)
    final tickPaint = Paint()
      ..color = const Color(0xFF64748B).withValues(alpha: 0.35)
      ..strokeWidth = 1.0;
    final cardinalTickPaint = Paint()
      ..color = const Color(0xFF3B82F6).withValues(alpha: 0.65)
      ..strokeWidth = 1.8;

    for (int deg = 0; deg < 180; deg += 10) {
      double rad = deg * math.pi / 180;
      bool isCardinal = deg % 30 == 0;
      double tickLen = isCardinal ? 8.0 : 4.0;
      canvas.drawLine(
        Offset(center.dx + (maxRadius - tickLen) * math.cos(rad), center.dy - (maxRadius - tickLen) * math.sin(rad)),
        Offset(center.dx + maxRadius * math.cos(rad), center.dy - maxRadius * math.sin(rad)),
        isCardinal ? cardinalTickPaint : tickPaint,
      );
      canvas.drawLine(
        Offset(center.dx - (maxRadius - tickLen) * math.cos(rad), center.dy + (maxRadius - tickLen) * math.sin(rad)),
        Offset(center.dx - maxRadius * math.cos(rad), center.dy + maxRadius * math.sin(rad)),
        isCardinal ? cardinalTickPaint : tickPaint,
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

    // 3. Draw External Facial Streak across Sclera and Iris (The Projected Physical Light Band)
    double sweepAngleRad = (streakAngle - 90) * math.pi / 180;
    final facialStreakCenter = Offset(
      center.dx + beamPosition * math.cos(sweepAngleRad),
      center.dy + beamPosition * math.sin(sweepAngleRad),
    );

    canvas.save();
    canvas.translate(facialStreakCenter.dx, facialStreakCenter.dy);
    canvas.rotate((streakAngle - 90) * math.pi / 180);

    final facialStreakPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0x00FFD54F),
          const Color(0x44FFE082),
          const Color(0xAAFFF59D),
          const Color(0xEEFFFFFF),
          const Color(0xAAFFF59D),
          const Color(0x44FFE082),
          const Color(0x00FFD54F),
        ],
        stops: const [0.0, 0.20, 0.38, 0.50, 0.62, 0.80, 1.0],
      ).createShader(Rect.fromCenter(center: Offset.zero, width: 22, height: maxRadius * 2.8));

    canvas.drawRect(
      Rect.fromCenter(center: Offset.zero, width: 22, height: maxRadius * 2.8),
      facialStreakPaint,
    );
    canvas.restore();

    // 4. Draw Pupil (Black aperture) with physiological light reflex constriction
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

    // 5. Draw Choroidal Backscatter Base Glow (Deep Red-Orange Retro-Illumination)
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

    // 6. Advanced Shader-Based Fundus Reflex Dynamics
    if (reflexMotion == "neutral") {
      // 🌟 FULL PUPILLARY CAVITY NEUTRALITY FLASH (100% Aperture Fill)
      final double peakLuminance = (reflectionOpacity * illuminance * fundusLuminanceMultiplier * 1.28).clamp(0.35, 1.0);
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

      // Physically simulated non-linear velocity displacement & Skew shear translation
      double reflexOffset = beamPosition * motionDirection * (0.34 * velocityFactor);
      double skewDisplacement = skewShearFactor * 18.0;

      final reflexCenter = Offset(
        center.dx + reflexOffset * math.cos(sweepAngleRad) + skewDisplacement * math.sin(sweepAngleRad),
        center.dy + reflexOffset * math.sin(sweepAngleRad) - skewDisplacement * math.cos(sweepAngleRad),
      );

      final double peakOpacity = (reflectionOpacity * illuminance * fundusLuminanceMultiplier * 1.35).clamp(0.20, 1.0);
      double dynamicFillWidth = pupilRadius * 2.0 * pupilFillRatio;
      double rWidth = math.max(reflexWidth.abs(), dynamicFillWidth).clamp(6.0, pupilRadius * 2.8);

      // Multi-Stop Optical Gaussian Beam Profile Shader (Vivid Gold-Orange-White Filament)
      final reflexPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            streakColor.withValues(alpha: 0.0),
            streakColor.withValues(alpha: (peakOpacity * 0.45).clamp(0.0, 1.0)),
            streakColor.withValues(alpha: (peakOpacity * 0.80).clamp(0.0, 1.0)),
            streakColor.withValues(alpha: (peakOpacity * 0.96).clamp(0.0, 1.0)),
            const Color(0xFFFFFFFF).withValues(alpha: peakOpacity), // Incandescent white filament core
            streakColor.withValues(alpha: (peakOpacity * 0.96).clamp(0.0, 1.0)),
            streakColor.withValues(alpha: (peakOpacity * 0.80).clamp(0.0, 1.0)),
            streakColor.withValues(alpha: (peakOpacity * 0.45).clamp(0.0, 1.0)),
            streakColor.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.10, 0.26, 0.42, 0.50, 0.58, 0.74, 0.90, 1.0],
        ).createShader(Rect.fromCenter(center: Offset.zero, width: rWidth, height: pupilRadius * 3.5));

      if (scissorsMotionActive) {
        // Scissors Blade 1 (Dynamic dual-split aberration with parabolic curvature)
        double angle1 = (reflexAngle - 90) + breakDisplacementAngle + (beamPosition * 0.26);
        canvas.save();
        canvas.translate(reflexCenter.dx, reflexCenter.dy);
        canvas.rotate(angle1 * math.pi / 180);
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: rWidth, height: pupilRadius * 3.5),
          reflexPaint,
        );
        canvas.restore();

        // Scissors Blade 2 (Opposing blade crossing toward center)
        double angle2 = (reflexAngle - 90) + breakDisplacementAngle - (beamPosition * 0.26);
        final reflexCenter2 = Offset(
          center.dx - reflexOffset * math.cos(sweepAngleRad) - skewDisplacement * math.sin(sweepAngleRad),
          center.dy - reflexOffset * math.sin(sweepAngleRad) + skewDisplacement * math.cos(sweepAngleRad),
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

    // 7. Draw Media Opacities (Cataract & Corneal Scars within aperture)
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

    // 8. Anterior Corneal Scar (if simulated)
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

    // 9. Dynamic 3D Purkinje Corneal Highlight with subtle sweep parallax
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

    // 10. 🌟 Optical Conjugacy Limbus Ring (Glows softly when Neutral Point is achieved)
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
        oldDelegate.skewShearFactor != skewShearFactor ||
        oldDelegate.velocityFactor != velocityFactor ||
        oldDelegate.illuminance != illuminance ||
        oldDelegate.pupilFillRatio != pupilFillRatio ||
        oldDelegate.pupilApertureRatio != pupilApertureRatio ||
        oldDelegate.fundusLuminanceMultiplier != fundusLuminanceMultiplier;
  }
}


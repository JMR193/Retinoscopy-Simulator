import 'dart:math';
import 'package:flutter/material.dart';

/// Interactive Optical Ray-Tracing Cross-Section
/// Shows real-time ray refraction through trial lenses, cornea, crystalline lens,
/// and convergence relative to the retinal plane.
class OpticalRayDiagram extends StatelessWidget {
  final double netSphericalEquivalent;
  final double cylinderPower;
  final double cylinderAngle;
  final double streakAngle;
  final double workingDistance;
  final double grossTrialPower;

  const OpticalRayDiagram({
    super.key,
    required this.netSphericalEquivalent,
    required this.cylinderPower,
    required this.cylinderAngle,
    required this.streakAngle,
    required this.workingDistance,
    required this.grossTrialPower,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.auto_graph, color: Colors.cyanAccent, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Optical Ray Tracing & Focal Conjugates',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _getRefractionColor().withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _getRefractionColor(), width: 1),
                  ),
                  child: Text(
                    _getRefractionLabel(),
                    style: TextStyle(
                      color: _getRefractionColor(),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFF1E293B)),
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              child: CustomPaint(
                painter: _RayTracingPainter(
                  netRefraction: netSphericalEquivalent,
                  cylinderPower: cylinderPower,
                  grossTrial: grossTrialPower,
                  workingDistance: workingDistance,
                ),
                child: Container(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRefractionColor() {
    if (netSphericalEquivalent.abs() < 0.25) return Colors.greenAccent;
    if (netSphericalEquivalent < 0) return Colors.redAccent;
    return Colors.amberAccent;
  }

  String _getRefractionLabel() {
    if (netSphericalEquivalent.abs() < 0.25) return 'EMMETROPIA / NEUTRAL';
    if (netSphericalEquivalent < 0) return 'MYOPIA (${netSphericalEquivalent.toStringAsFixed(2)} D)';
    return 'HYPEROPIA (+${netSphericalEquivalent.toStringAsFixed(2)} D)';
  }
}

class _RayTracingPainter extends CustomPainter {
  final double netRefraction;
  final double cylinderPower;
  final double grossTrial;
  final double workingDistance;

  _RayTracingPainter({
    required this.netRefraction,
    required this.cylinderPower,
    required this.grossTrial,
    required this.workingDistance,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double midY = h / 2;

    // Positions along horizontal optical axis
    final double retinoscopeX = w * 0.08;
    final double trialLensX = w * 0.32;
    final double corneaX = w * 0.55;
    final double lensX = w * 0.65;
    final double retinaX = w * 0.88;

    // Draw Optical Axis (dashed centerline)
    final axisPaint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    _drawDashedLine(canvas, Offset(0, midY), Offset(w, midY), axisPaint);

    // Draw Retinoscope Source Node
    final sourcePaint = Paint()..color = Colors.cyanAccent;
    canvas.drawCircle(Offset(retinoscopeX, midY), 5, sourcePaint);
    final sourceGlow = Paint()
      ..color = Colors.cyanAccent.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset(retinoscopeX, midY), 10, sourceGlow);

    _drawLabel(canvas, Offset(retinoscopeX, midY + 16), 'Retinoscope', Colors.cyanAccent);

    // Draw Trial Lens
    if (grossTrial.abs() > 0.05) {
      final lensPaint = Paint()
        ..color = grossTrial > 0 ? Colors.greenAccent : Colors.redAccent
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        Offset(trialLensX, midY - h * 0.35),
        Offset(trialLensX, midY + h * 0.35),
        lensPaint,
      );
      _drawLabel(
        canvas,
        Offset(trialLensX, midY - h * 0.38),
        'Trial ${grossTrial > 0 ? '+' : ''}${grossTrial.toStringAsFixed(2)} D',
        grossTrial > 0 ? Colors.greenAccent : Colors.redAccent,
      );
    }

    // Draw Anatomical Eye Cross-Section Outline
    final eyePaint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final Path eyePath = Path();
    // Cornea curve
    eyePath.moveTo(corneaX, midY - h * 0.28);
    eyePath.quadraticBezierTo(corneaX - 14, midY, corneaX, midY + h * 0.28);
    // Scleral coat upper
    eyePath.lineTo(retinaX, midY + h * 0.28);
    // Retinal back curve
    eyePath.quadraticBezierTo(retinaX + 12, midY, retinaX, midY - h * 0.28);
    eyePath.close();

    final eyeFill = Paint()..color = const Color(0xFF1E293B).withValues(alpha: 0.6);
    canvas.drawPath(eyePath, eyeFill);
    canvas.drawPath(eyePath, eyePaint);

    // Draw Retina Plane (Red concave arc)
    final retinaPaint = Paint()
      ..color = Colors.amber
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;
    final Path retinaArc = Path();
    retinaArc.moveTo(retinaX, midY - h * 0.25);
    retinaArc.quadraticBezierTo(retinaX + 10, midY, retinaX, midY + h * 0.25);
    canvas.drawPath(retinaArc, retinaPaint);
    _drawLabel(canvas, Offset(retinaX, midY + h * 0.30), 'Retina', Colors.amber);

    // Draw Crystalline Lens
    final lensFill = Paint()
      ..color = Colors.lightBlueAccent.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    final lensBorder = Paint()
      ..color = Colors.lightBlueAccent
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final Rect crystallineRect = Rect.fromCenter(
      center: Offset(lensX, midY),
      width: 14,
      height: h * 0.40,
    );
    canvas.drawOval(crystallineRect, lensFill);
    canvas.drawOval(crystallineRect, lensBorder);
    _drawLabel(canvas, Offset(corneaX, midY - h * 0.32), 'Cornea', const Color(0xFF38BDF8));

    // Calculate Real Conjugate Focal Position (Focal Point X)
    final double focalShift = (netRefraction * 7.5).clamp(-w * 0.25, w * 0.25);
    final double focalX = retinaX + focalShift;

    // Draw Incoming Refracted Ray Traces
    final rayPaint = Paint()
      ..color = Colors.amberAccent.withValues(alpha: 0.85)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    final rayGlow = Paint()
      ..color = Colors.amberAccent.withValues(alpha: 0.25)
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    final List<double> rayOffsets = [-h * 0.20, -h * 0.10, 0, h * 0.10, h * 0.20];

    for (final dy in rayOffsets) {
      final Path rayPath = Path();
      rayPath.moveTo(retinoscopeX, midY);

      if (grossTrial.abs() > 0.05) {
        final double trialDy = dy * 0.8;
        rayPath.lineTo(trialLensX, midY + trialDy);
        rayPath.lineTo(corneaX, midY + dy * 0.9);
      } else {
        rayPath.lineTo(corneaX, midY + dy * 0.9);
      }

      rayPath.lineTo(lensX, midY + dy * 0.8);
      rayPath.lineTo(focalX, midY);

      canvas.drawPath(rayPath, rayGlow);
      canvas.drawPath(rayPath, rayPaint);
    }

    // Draw Focal Point Marker
    final focalPaint = Paint()..color = (focalX - retinaX).abs() < 2 ? Colors.greenAccent : Colors.redAccent;
    canvas.drawCircle(Offset(focalX, midY), 4, focalPaint);

    final String focalTag = (focalX - retinaX).abs() < 2
        ? 'Conjugate (Neutral)'
        : focalX > retinaX
            ? 'Far Point Behind'
            : 'Far Point In Front';
    _drawLabel(canvas, Offset(focalX, midY - 14), focalTag, focalPaint.color);
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const double dashWidth = 5;
    const double dashSpace = 4;
    double startX = p1.dx;
    while (startX < p2.dx) {
      canvas.drawLine(
        Offset(startX, p1.dy),
        Offset(min(startX + dashWidth, p2.dx), p1.dy),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  void _drawLabel(Canvas canvas, Offset offset, String text, Color color) {
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontSize: 9,
        fontWeight: FontWeight.bold,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(offset.dx - textPainter.width / 2, offset.dy),
    );
  }

  @override
  bool shouldRepaint(covariant _RayTracingPainter oldDelegate) {
    return oldDelegate.netRefraction != netRefraction ||
        oldDelegate.cylinderPower != cylinderPower ||
        oldDelegate.grossTrial != grossTrial ||
        oldDelegate.workingDistance != workingDistance;
  }
}
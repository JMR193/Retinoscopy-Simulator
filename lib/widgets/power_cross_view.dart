import 'dart:math';
import 'package:flutter/material.dart';

/// Dynamic 2-Meridian Optical Power Cross
/// Illustrates power along orthogonal principal meridians based on Euler's relation.
class PowerCrossView extends StatelessWidget {
  final double sphere;
  final double cylinder;
  final double axis;

  const PowerCrossView({
    super.key,
    required this.sphere,
    required this.cylinder,
    required this.axis,
  });

  @override
  Widget build(BuildContext context) {
    final double power1 = sphere;
    final double angle1 = axis;
    final double power2 = sphere + cylinder;
    final double angle2 = (axis + 90) > 180 ? axis - 90 : axis + 90;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
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
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.close, color: Colors.cyanAccent, size: 18),
                  SizedBox(width: 8),
                  Text(
                    '2-Meridian Optical Power Cross',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: CustomPaint(
              painter: _PowerCrossPainter(
                power1: power1,
                angle1: angle1,
                power2: power2,
                angle2: angle2,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMeridianBadge('Meridian 1', power1, angle1, Colors.greenAccent),
              _buildMeridianBadge('Meridian 2', power2, angle2, Colors.amberAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMeridianBadge(String title, double power, double angle, Color color) {
    final String sign = power > 0 ? '+' : '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Text(title, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(
            '$sign${power.toStringAsFixed(2)} D @ ${angle.toStringAsFixed(0)}°',
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _PowerCrossPainter extends CustomPainter {
  final double power1;
  final double angle1;
  final double power2;
  final double angle2;

  _PowerCrossPainter({
    required this.power1,
    required this.angle1,
    required this.power2,
    required this.angle2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double radius = min(cx, cy) * 0.78;

    // Outer Protractor Compass Circle
    final circlePaint = Paint()
      ..color = Colors.white12
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(Offset(cx, cy), radius, circlePaint);

    // Cardinal tick marks
    for (int deg = 0; deg < 180; deg += 30) {
      final double rad = deg * pi / 180;
      final double x1 = cx + (radius - 5) * cos(rad);
      final double y1 = cy - (radius - 5) * sin(rad);
      final double x2 = cx + radius * cos(rad);
      final double y2 = cy - radius * sin(rad);
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), circlePaint);
    }

    // Meridian 1 Line (Green)
    final double rad1 = angle1 * pi / 180;
    final linePaint1 = Paint()
      ..color = Colors.greenAccent
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(cx - radius * cos(rad1), cy + radius * sin(rad1)),
      Offset(cx + radius * cos(rad1), cy - radius * sin(rad1)),
      linePaint1,
    );

    // Meridian 2 Line (Amber)
    final double rad2 = angle2 * pi / 180;
    final linePaint2 = Paint()
      ..color = Colors.amberAccent
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(cx - radius * cos(rad2), cy + radius * sin(rad2)),
      Offset(cx + radius * cos(rad2), cy - radius * sin(rad2)),
      linePaint2,
    );

    // Center pivot point
    final centerPaint = Paint()..color = Colors.cyanAccent;
    canvas.drawCircle(Offset(cx, cy), 4, centerPaint);

    // Labels at terminal ends
    final String p1Str = '${power1 > 0 ? '+' : ''}${power1.toStringAsFixed(2)} D';
    final String p2Str = '${power2 > 0 ? '+' : ''}${power2.toStringAsFixed(2)} D';

    _drawLabel(canvas, Offset(cx + (radius + 18) * cos(rad1), cy - (radius + 18) * sin(rad1)), '$p1Str\n${angle1.toInt()}°', Colors.greenAccent);
    _drawLabel(canvas, Offset(cx + (radius + 18) * cos(rad2), cy - (radius + 18) * sin(rad2)), '$p2Str\n${angle2.toInt()}°', Colors.amberAccent);
  }

  void _drawLabel(Canvas canvas, Offset offset, String text, Color color) {
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(offset.dx - textPainter.width / 2, offset.dy - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _PowerCrossPainter oldDelegate) {
    return oldDelegate.power1 != power1 ||
        oldDelegate.angle1 != angle1 ||
        oldDelegate.power2 != power2 ||
        oldDelegate.angle2 != angle2;
  }
}
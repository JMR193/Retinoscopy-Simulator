import 'dart:math';
import 'package:flutter/material.dart';

/// Thibos Power Vector 2D Visualizer
/// Plots J0 (Horizontal/Vertical) vs J45 (Oblique) Jackson Cross-Cylinder components
/// with Dioptric Blur (B) contour rings.
class ThibosVectorPlot extends StatelessWidget {
  final double patientM;
  final double patientJ0;
  final double patientJ45;
  final double trialM;
  final double trialJ0;
  final double trialJ45;

  const ThibosVectorPlot({
    super.key,
    required this.patientM,
    required this.patientJ0,
    required this.patientJ45,
    required this.trialM,
    required this.trialJ0,
    required this.trialJ45,
  });

  @override
  Widget build(BuildContext context) {
    final double errorM = trialM - patientM;
    final double errorJ0 = trialJ0 - patientJ0;
    final double errorJ45 = trialJ45 - patientJ45;
    final double totalBlur = sqrt(errorM * errorM + errorJ0 * errorJ0 + errorJ45 * errorJ45);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.scatter_plot, color: Colors.purpleAccent, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Thibos (J₀, J₄₅) 2D Power Vector Space',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: totalBlur < 0.25 ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: totalBlur < 0.25 ? Colors.greenAccent : Colors.redAccent),
                ),
                child: Text(
                  'Blur Metric B = ${totalBlur.toStringAsFixed(2)} D',
                  style: TextStyle(
                    color: totalBlur < 0.25 ? Colors.greenAccent : Colors.redAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: CustomPaint(
              painter: _ThibosPlotPainter(
                patientJ0: patientJ0,
                patientJ45: patientJ45,
                trialJ0: trialJ0,
                trialJ45: trialJ45,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLegendItem('Patient Error', Colors.amber),
              _buildLegendItem('Trial Lens Rx', Colors.cyanAccent),
              _buildLegendItem('Origin (0,0)', Colors.white54),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
      ],
    );
  }
}

class _ThibosPlotPainter extends CustomPainter {
  final double patientJ0;
  final double patientJ45;
  final double trialJ0;
  final double trialJ45;

  _ThibosPlotPainter({
    required this.patientJ0,
    required this.patientJ45,
    required this.trialJ0,
    required this.trialJ45,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double scale = size.height / 6.0; // 6 Diopters span (-3 to +3)

    // Grid circles (1D, 2D, 3D concentric rings)
    final gridPaint = Paint()
      ..color = Colors.white10
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (int r = 1; r <= 3; r++) {
      canvas.drawCircle(Offset(cx, cy), r * scale, gridPaint);
    }

    // Axes
    final axisPaint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(0, cy), Offset(size.width, cy), axisPaint);
    canvas.drawLine(Offset(cx, 0), Offset(cx, size.height), axisPaint);

    // Axis Labels
    _drawText(canvas, Offset(size.width - 24, cy + 4), '+J₀ (90/180°)', Colors.white38);
    _drawText(canvas, Offset(cx + 4, 4), '+J₄₅ (45/135°)', Colors.white38);

    // Plot Patient Vector Point (Amber)
    final double patX = cx + (patientJ0 * scale);
    final double patY = cy - (patientJ45 * scale);
    final patPaint = Paint()..color = Colors.amber;
    canvas.drawCircle(Offset(patX, patY), 5, patPaint);

    // Plot Trial Vector Point (Cyan)
    final double trX = cx + (trialJ0 * scale);
    final double trY = cy - (trialJ45 * scale);
    final trPaint = Paint()..color = Colors.cyanAccent;
    canvas.drawCircle(Offset(trX, trY), 5, trPaint);

    // Draw Vector connecting Trial to Patient (Residual astigmatic error vector)
    final linePaint = Paint()
      ..color = Colors.redAccent.withValues(alpha: 0.7)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(patX, patY), Offset(trX, trY), linePaint);
  }

  void _drawText(Canvas canvas, Offset offset, String text, Color color) {
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _ThibosPlotPainter oldDelegate) {
    return oldDelegate.patientJ0 != patientJ0 ||
        oldDelegate.patientJ45 != patientJ45 ||
        oldDelegate.trialJ0 != trialJ0 ||
        oldDelegate.trialJ45 != trialJ45;
  }
}
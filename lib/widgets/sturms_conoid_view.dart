import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Interactive 3D Perspective Visualizer for Sturm's Conoid (Conoid of Sturm)
///
/// Models the refraction of light through an astigmatic optical system, illustrating
/// the anterior focal line, posterior focal line, Circle of Least Confusion (COLC),
/// the Interval of Sturm, and their relationship with the retinal plane.
class SturmsConoidView extends StatefulWidget {
  final double sphere;
  final double cylinder;
  final double axis;
  final double workingDistance;
  final VoidCallback? onClose;

  const SturmsConoidView({
    super.key,
    required this.sphere,
    required this.cylinder,
    required this.axis,
    this.workingDistance = 0.0,
    this.onClose,
  });

  @override
  State<SturmsConoidView> createState() => _SturmsConoidViewState();
}

class _SturmsConoidViewState extends State<SturmsConoidView> {
  double _viewAngle = 35.0; // Degrees of tilt (0 = flat cross-section, 45 = isometric 3D)

  String _classifyAstigmatism(double netP1, double netP2) {
    if (widget.cylinder.abs() < 0.25) {
      if (netP1.abs() < 0.25) return 'Emmetropia (Stigmatic Focus)';
      return netP1 > 0 ? 'Simple Myopia' : 'Simple Hyperopia';
    }

    final double minP = math.min(netP1, netP2);
    final double maxP = math.max(netP1, netP2);

    if (maxP < -0.20) {
      return 'Compound Hyperopic Astigmatism (CHA)';
    } else if (maxP.abs() <= 0.20 && minP < -0.20) {
      return 'Simple Hyperopic Astigmatism (SHA)';
    } else if (minP < -0.20 && maxP > 0.20) {
      return 'Mixed Astigmatism (MA)';
    } else if (minP.abs() <= 0.20 && maxP > 0.20) {
      return 'Simple Myopic Astigmatism (SMA)';
    } else if (minP > 0.20) {
      return 'Compound Myopic Astigmatism (CMA)';
    }
    return 'Astigmatic Refractive State';
  }

  Color _getClassificationColor(String classification) {
    if (classification.contains('Compound Myopic')) return const Color(0xFF38BDF8); // Cyan
    if (classification.contains('Simple Myopic')) return const Color(0xFF60A5FA); // Blue
    if (classification.contains('Mixed')) return const Color(0xFFF59E0B); // Amber
    if (classification.contains('Simple Hyperopic')) return const Color(0xFFFB923C); // Orange
    if (classification.contains('Compound Hyperopic')) return const Color(0xFFF87171); // Red
    return const Color(0xFF34D399); // Emerald
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    final double netP1 = widget.sphere;
    final double netP2 = widget.sphere + widget.cylinder;
    final double se = widget.sphere + (widget.cylinder / 2.0);
    final double intervalOfSturm = widget.cylinder.abs();
    final String classification = _classifyAstigmatism(netP1, netP2);
    final Color badgeColor = _getClassificationColor(classification);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.blue.withValues(alpha: 0.3) : Colors.blue.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
            blurRadius: 12,
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
                        color: Colors.cyan.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.auto_graph_rounded, color: Colors.cyanAccent, size: 18),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Sturm’s Conoid 3D Ray Conoid',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: badgeColor.withValues(alpha: 0.6), width: 1),
                      ),
                      child: Text(
                        classification,
                        style: TextStyle(
                          color: badgeColor,
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (widget.onClose != null) ...[
                      const SizedBox(width: 6),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: widget.onClose,
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Close Diagram',
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Interactive 3D Canvas
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: SizedBox(
              height: 220,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CustomPaint(
                  painter: _SturmsConoidPainter(
                    netP1: netP1,
                    netP2: netP2,
                    axis: widget.axis,
                    isDark: isDark,
                    viewAngleDeg: _viewAngle,
                  ),
                  size: Size.infinite,
                ),
              ),
            ),
          ),

          // 3D Angle Scrub Control & Optical Metrics
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.threed_rotation, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      '3D Perspective: ${_viewAngle.toInt()}°',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 2.5,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        ),
                        child: Slider(
                          value: _viewAngle,
                          min: 0.0,
                          max: 60.0,
                          onChanged: (val) => setState(() => _viewAngle = val),
                        ),
                      ),
                    ),
                  ],
                ),
                // Optical Metrics Chips
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildMetricChip(
                      label: 'Focal Line 1 (Axis ${widget.axis.toInt()}°)',
                      value: '${netP1 >= 0 ? '+' : ''}${netP1.toStringAsFixed(2)} D',
                      color: const Color(0xFF38BDF8),
                      isDark: isDark,
                    ),
                    _buildMetricChip(
                      label: 'Focal Line 2 (Axis ${((widget.axis + 90) % 180).toInt()}°)',
                      value: '${netP2 >= 0 ? '+' : ''}${netP2.toStringAsFixed(2)} D',
                      color: const Color(0xFFF472B6),
                      isDark: isDark,
                    ),
                    _buildMetricChip(
                      label: 'Circle of Least Confusion (COLC)',
                      value: '${se >= 0 ? '+' : ''}${se.toStringAsFixed(2)} D',
                      color: const Color(0xFFFBBF24),
                      isDark: isDark,
                    ),
                    _buildMetricChip(
                      label: 'Interval of Sturm',
                      value: '${intervalOfSturm.toStringAsFixed(2)} D',
                      color: const Color(0xFFA78BFA),
                      isDark: isDark,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildMetricChip({
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 5),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 10,
              color: isDark ? Colors.white70 : Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 10.5,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _SturmsConoidPainter extends CustomPainter {
  final double netP1;
  final double netP2;
  final double axis;
  final bool isDark;
  final double viewAngleDeg;

  _SturmsConoidPainter({
    required this.netP1,
    required this.netP2,
    required this.axis,
    required this.isDark,
    required this.viewAngleDeg,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double centerY = h * 0.48;

    // Background Canvas Fill
    final bgPaint = Paint()..color = isDark ? const Color(0xFF0B1329) : const Color(0xFFF8FAFC);
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    // Grid lines
    final gridPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04)
      ..strokeWidth = 1;
    for (double x = 0; x < w; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), gridPaint);
    }
    for (double y = 0; y < h; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    // Optical Axis
    final axisPaint = Paint()
      ..color = (isDark ? Colors.white38 : Colors.black38)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(20, centerY), Offset(w - 20, centerY), axisPaint);

    // Optical Center / Lens plane
    final double lensX = 40.0;
    final lensPaint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.7)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(lensX, centerY - 55), Offset(lensX, centerY + 55), lensPaint);

    // Retina Plane position (fixed reference at w * 0.65)
    final double retinaX = w * 0.65;
    final retinaPaint = Paint()
      ..color = Colors.amber.withValues(alpha: 0.8)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(retinaX, centerY - 65), Offset(retinaX, centerY + 65), retinaPaint);

    // Draw "Retina Plane" label
    final retinaTextPainter = TextPainter(
      text: const TextSpan(
        text: 'RETINA',
        style: TextStyle(
          color: Colors.amber,
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    retinaTextPainter.paint(canvas, Offset(retinaX - 18, centerY - 78));

    // Calculate focal positions based on net dioptric vergence
    // If P = 0, focus is at retinaX. If P > 0 (myopic), focus is in front of retina (to the left).
    // If P < 0 (hyperopic), focus is behind retina (to the right).
    const double pxPerDiopter = 22.0;
    final double f1X = (retinaX - (netP1 * pxPerDiopter)).clamp(lensX + 25.0, w - 25.0);
    final double f2X = (retinaX - (netP2 * pxPerDiopter)).clamp(lensX + 25.0, w - 25.0);
    final double colcX = (f1X + f2X) / 2.0;

    // View Angle Projection (Tilt Factor)
    final double tilt = math.sin(viewAngleDeg * math.pi / 180.0) * 0.45;

    // Draw Interval of Sturm shaded zone
    final double minF = math.min(f1X, f2X);
    final double maxF = math.max(f1X, f2X);
    if ((maxF - minF) > 4) {
      final sturmZonePaint = Paint()
        ..shader = LinearGradient(
          colors: [
            const Color(0xFF38BDF8).withValues(alpha: 0.15),
            const Color(0xFFF472B6).withValues(alpha: 0.15),
          ],
        ).createShader(Rect.fromLTRB(minF, centerY - 45, maxF, centerY + 45));
      canvas.drawRect(Rect.fromLTRB(minF, centerY - 40, maxF, centerY + 40), sturmZonePaint);
    }

    // Ray Bundles from Lens to Focal Lines
    final ray1Paint = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.55)
      ..strokeWidth = 1.5;
    final ray2Paint = Paint()
      ..color = const Color(0xFFF472B6).withValues(alpha: 0.55)
      ..strokeWidth = 1.5;

    // Vertical Meridian Rays (P1)
    canvas.drawLine(Offset(lensX, centerY - 45), Offset(f1X, centerY), ray1Paint);
    canvas.drawLine(Offset(lensX, centerY + 45), Offset(f1X, centerY), ray1Paint);
    // Continue rays past focus
    canvas.drawLine(Offset(f1X, centerY), Offset(f1X + 45, centerY - 25), ray1Paint);
    canvas.drawLine(Offset(f1X, centerY), Offset(f1X + 45, centerY + 25), ray1Paint);

    // Horizontal Meridian Rays (P2)
    canvas.drawLine(Offset(lensX, centerY - 20), Offset(f2X, centerY), ray2Paint);
    canvas.drawLine(Offset(lensX, centerY + 20), Offset(f2X, centerY), ray2Paint);
    canvas.drawLine(Offset(f2X, centerY), Offset(f2X + 45, centerY - 12), ray2Paint);
    canvas.drawLine(Offset(f2X, centerY), Offset(f2X + 45, centerY + 12), ray2Paint);

    // Draw Focal Line 1 (Vertical / Primary)
    final f1Paint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    final double f1HalfLength = 34.0;
    canvas.drawLine(
      Offset(f1X, centerY - f1HalfLength * (1.0 - tilt * 0.4)),
      Offset(f1X, centerY + f1HalfLength * (1.0 - tilt * 0.4)),
      f1Paint,
    );

    // Draw Focal Line 2 (Horizontal / Orthogonal)
    final f2Paint = Paint()
      ..color = const Color(0xFFF472B6)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    final double f2HalfWidth = 34.0 * (0.6 + tilt * 0.6);
    canvas.drawLine(
      Offset(f2X - f2HalfWidth, centerY),
      Offset(f2X + f2HalfWidth, centerY),
      f2Paint,
    );

    // Draw Circle of Least Confusion (COLC)
    final colcPaint = Paint()
      ..color = const Color(0xFFFBBF24)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    final double colcRadius = 14.0 * (1.0 + tilt * 0.2);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(colcX, centerY),
        width: colcRadius * 2.0 * (0.8 + tilt * 0.4),
        height: colcRadius * 2.0 * (1.0 - tilt * 0.3),
      ),
      colcPaint,
    );

    // Labels for F1, F2, COLC
    _drawCanvasLabel(canvas, 'F1', Offset(f1X - 7, centerY + 40), const Color(0xFF38BDF8));
    _drawCanvasLabel(canvas, 'COLC', Offset(colcX - 12, centerY - 32), const Color(0xFFFBBF24));
    _drawCanvasLabel(canvas, 'F2', Offset(f2X - 7, centerY + 12), const Color(0xFFF472B6));
  }

  void _drawCanvasLabel(Canvas canvas, String text, Offset offset, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _SturmsConoidPainter oldDelegate) {
    return oldDelegate.netP1 != netP1 ||
        oldDelegate.netP2 != netP2 ||
        oldDelegate.axis != axis ||
        oldDelegate.isDark != isDark ||
        oldDelegate.viewAngleDeg != viewAngleDeg;
  }
}

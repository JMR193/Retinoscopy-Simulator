import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr/qr.dart';
import '../models/patient_profile.dart';

/// Shows a QR Code modal for sharing a patient case in classrooms
class QrCodeDialog extends StatelessWidget {
  final PatientProfile profile;

  const QrCodeDialog({super.key, required this.profile});

  static void show(BuildContext context, PatientProfile profile) {
    showDialog<void>(
      context: context,
      builder: (ctx) => QrCodeDialog(profile: profile),
    );
  }

  @override
  Widget build(BuildContext context) {
    final payload = profile.toQrPayload();
    final theme = Theme.of(context);

    // Generate QR Code matrix
    final qrCode = QrCode.fromData(
      data: payload,
      errorCorrectLevel: QrErrorCorrectLevel.M,
    );
    final qrImage = QrImage(qrCode);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.qr_code_2, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          const Text('Classroom Case QR'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              profile.name,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              profile.formattedRx,
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            // QR Code rendering box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[300]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: SizedBox(
                width: 200,
                height: 200,
                child: CustomPaint(
                  painter: _QrMatrixPainter(qrImage: qrImage, color: Colors.black),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Other students or supervisors can import this case by pasting the case link or scanning this QR.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: payload));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Case payload copied to clipboard!')),
            );
          },
          icon: const Icon(Icons.copy, size: 18),
          label: const Text('Copy Link'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Done'),
        ),
      ],
    );
  }
}

/// Custom vector painter for the QR code squares
class _QrMatrixPainter extends CustomPainter {
  final QrImage qrImage;
  final Color color;

  _QrMatrixPainter({required this.qrImage, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final moduleCount = qrImage.moduleCount;
    final moduleSize = size.width / moduleCount;

    for (int x = 0; x < moduleCount; x++) {
      for (int y = 0; y < moduleCount; y++) {
        if (qrImage.isDark(y, x)) {
          final rect = Rect.fromLTWH(
            x * moduleSize,
            y * moduleSize,
            moduleSize,
            moduleSize,
          );
          canvas.drawRect(rect, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _QrMatrixPainter oldDelegate) =>
      oldDelegate.qrImage != qrImage || oldDelegate.color != color;
}

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

/// Clinical Certificate of Competency Generator — JMR Technologies
class CertificateService {
  /// Generate and present/share a certificate of competency in PDF format
  static Future<void> generateAndShare({
    required String candidateName,
    required int score,
    required int totalCases,
  }) async {
    final doc = pw.Document();

    final dateStr = DateFormat('MMMM dd, yyyy').format(DateTime.now());
    final percent = ((score / totalCases) * 100).round();
    final certId = 'JMR-RET-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
    final displayName = candidateName.trim().isEmpty ? 'Clinical Practitioner' : candidateName.trim();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.indigo900, width: 4),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            padding: const pw.EdgeInsets.all(24),
            child: pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.amber700, width: 2),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  // Top branding
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'JMR TECHNOLOGIES',
                        style: pw.TextStyle(
                          color: PdfColors.indigo900,
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      pw.Text(
                        'VERIFICATION: $certId',
                        style: const pw.TextStyle(
                          color: PdfColors.grey700,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 8),

                  // Title
                  pw.Text(
                    'CERTIFICATE OF CLINICAL COMPETENCY',
                    style: pw.TextStyle(
                      color: PdfColors.indigo900,
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  pw.Text(
                    'STREAK RETINOSCOPY & REFRACTIVE ASSESSMENT',
                    style: pw.TextStyle(
                      color: PdfColors.amber800,
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  pw.SizedBox(height: 12),

                  // Body
                  pw.Text(
                    'This certifies that',
                    style: const pw.TextStyle(
                      color: PdfColors.grey800,
                      fontSize: 12,
                      fontStyle: pw.FontStyle.italic,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    displayName,
                    style: pw.TextStyle(
                      color: PdfColors.indigo900,
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Container(
                    width: 280,
                    height: 1.5,
                    color: PdfColors.amber700,
                    margin: const pw.EdgeInsets.only(top: 4, bottom: 8),
                  ),
                  pw.Text(
                    'has successfully completed the Clinical Retinoscopy Examination with a score of $score/$totalCases ($percent%), demonstrating proficient optical neutralization and astigmatic axis orientation skills.',
                    textAlign: pw.TextAlign.center,
                    style: const pw.TextStyle(
                      color: PdfColors.grey900,
                      fontSize: 11,
                      lineSpacing: 2,
                    ),
                  ),
                  pw.SizedBox(height: 16),

                  // Footer Row
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            dateStr,
                            style: pw.TextStyle(
                              color: PdfColors.indigo900,
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Container(width: 120, height: 1, color: PdfColors.grey500),
                          pw.SizedBox(height: 2),
                          pw.Text('Date of Examination', style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 8)),
                        ],
                      ),
                      // Seal badge
                      pw.Container(
                        width: 50,
                        height: 50,
                        decoration: pw.BoxDecoration(
                          shape: pw.BoxShape.circle,
                          border: pw.Border.all(color: PdfColors.amber800, width: 2),
                          color: PdfColors.amber50,
                        ),
                        child: pw.Center(
                          child: pw.Text(
                            'JMR\nPASS',
                            textAlign: pw.TextAlign.center,
                            style: pw.TextStyle(
                              color: PdfColors.amber900,
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            'Retinoscopy Clinical AI Engine',
                            style: pw.TextStyle(
                              color: PdfColors.indigo900,
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Container(width: 160, height: 1, color: PdfColors.grey500),
                          pw.SizedBox(height: 2),
                          pw.Text('Evaluator / Verification System', style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 8)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    // Share / Print document
    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: 'Retinoscopy_Certificate_${score}_of_$totalCases.pdf',
    );
  }
}

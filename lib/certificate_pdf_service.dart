import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:typed_data';
import 'package:intl/intl.dart';

class CertificatePDF {
  static Future<Uint8List> generateOfficialCertificate({
    required String recipientName,
    required String courseTitle,
    required String organization,
    required DateTime issueDate,
    DateTime? expiryDate,
    Uint8List? logoBytes,
    String? status,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Stack(
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  if (logoBytes != null)
                    pw.Image(
                      pw.MemoryImage(logoBytes),
                      height: 80,
                    ),
                  pw.SizedBox(height: 30),
                  pw.Text(
                    'OFFICIAL CERTIFICATE',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Divider(),
                  pw.SizedBox(height: 40),
                  pw.Text(
                    'This certifies that',
                    style: pw.TextStyle(fontSize: 16),
                  ),
                  pw.SizedBox(height: 15),
                  pw.Text(
                    recipientName,
                    style: pw.TextStyle(
                      fontSize: 28,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Text(
                    'has successfully completed the course',
                    style: pw.TextStyle(fontSize: 16),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    courseTitle,
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 40),
                  pw.Text(
                    'Issued by $organization',
                    style: pw.TextStyle(fontSize: 14),
                  ),
                  pw.Text(
                    'on ${DateFormat('yyyy-MM-dd').format(issueDate)}',
                    style: pw.TextStyle(fontSize: 14),
                  ),
                  if (expiryDate != null)
                    pw.Text(
                      'Expires on ${DateFormat('yyyy-MM-dd').format(expiryDate)}',
                      style: pw.TextStyle(fontSize: 14),
                    ),
                ],
              ),
              if (status == 'approved')
                pw.Positioned(
                  bottom: 20,
                  right: 20,
                  child: pw.Text(
                    'APPROVED',
                    style: pw.TextStyle(
                      color: PdfColors.green400,
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }
}
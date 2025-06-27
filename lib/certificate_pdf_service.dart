import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class CertificatePDF {
  static Future<Uint8List> generateEnhancedCertificate({
    required String recipientName,
    required String courseName,
    required DateTime issueDate,
    Uint8List? logoBytes,
  }) async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              if (logoBytes != null) pw.Image(pw.MemoryImage(logoBytes), width: 100, height: 100),
              pw.Header(
                level: 0,
                text: 'CERTIFICATE',
                textStyle: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 30),
              pw.Text('This certifies that', style: const pw.TextStyle(fontSize: 18)),
              pw.SizedBox(height: 20),
              pw.Text(recipientName, style: pw.TextStyle(fontSize: 30, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Text('has successfully completed', style: const pw.TextStyle(fontSize: 18)),
              pw.Text(courseName, style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 40),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Column(children: [pw.Text('_____________'), pw.Text('Signature')]),
                  pw.Column(children: [pw.Text('_____________'), pw.Text('Date')]),
                ],
              ),
            ],
          );
        },
      ),
    );
    
    return pdf.save();
  }
}
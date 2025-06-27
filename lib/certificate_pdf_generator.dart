import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;

class CertificatePDF {
  static Future<Uint8List> generateBasicCertificate(String recipientName) async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Text('Certificate for $recipientName', 
              style: const pw.TextStyle(fontSize: 24)),
          );
        },
      ),
    );
    
    return pdf.save();
  }
}
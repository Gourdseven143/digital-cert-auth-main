import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:encrypt/encrypt.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'certificate_model.dart';

class CertificateGenerator {
  // RSA key pair (store securely in production)
  static final keyPair = RSAKeyParser().parse(_privateKey) as RSAPrivateKey;
  static final signer = Signer(RSA(privateKey: keyPair) as SignerAlgorithm);

  static Future<File> generateCertificate(Certificate cert) async {
    final pdf = pw.Document();

    pdf.addPage(pw.Page(
      build: (context) => pw.Center(
        child: pw.Column(
          children: [
            pw.Text('Certificate of Achievement', style: pw.TextStyle(fontSize: 24)),
            pw.SizedBox(height: 30),
            pw.Text('This certifies that'),
            pw.Text(cert.fullName, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.Text('has completed ${cert.title}'),
            pw.SizedBox(height: 20),
            pw.Text('Issued by ${cert.issuer} on ${cert.issueDate.toLocal()}'),
            pw.SizedBox(height: 20),
            pw.Text('Signature: ${cert.signature.substring(0, 20)}...', style: pw.TextStyle(fontSize: 10))
          ],
        ),
      ),
    ));

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/${cert.id}.pdf");
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  static String signCertificate(String data) {
    final signature = signer.sign(data.codeUnits as String);
    return signature.base64;
  }

  static const _privateKey = '''-----BEGIN RSA PRIVATE KEY-----
MIICWwIBAAKBgQDEkY4nYLu9N+aC...
-----END RSA PRIVATE KEY-----''';
}

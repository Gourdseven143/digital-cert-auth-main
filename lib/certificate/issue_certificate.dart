import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'certificate_model.dart';
import 'certificate_generator.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';


Future<void> issueCertificate(String userId, String fullName, String courseTitle) async {
  final id = const Uuid().v4();
  final cert = Certificate(
    id: id,
    fullName: fullName,
    title: courseTitle,
    issuer: 'Digital Certificate Repository',
    issueDate: DateTime.now(),
    signature: '',
  );

  final dataToSign = '${cert.fullName}|${cert.title}|${cert.issueDate.toIso8601String()}';
  final signature = CertificateGenerator.signCertificate(dataToSign);
  final signedCert = cert.copyWith(signature: signature);

  // Generate PDF
  final pdfFile = await CertificateGenerator.generateCertificate(signedCert);

  // Upload to Firebase Storage
  final storageRef = FirebaseStorage.instance.ref().child('certificates/$userId/$id.pdf');
  await storageRef.putFile(pdfFile);
  final pdfUrl = await storageRef.getDownloadURL();

  // Save metadata to Firestore
  await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('certificates')
      .doc(id)
      .set({
    ...signedCert.toMap(),
    'pdfUrl': pdfUrl,
  });
}

//issue and upload to firebase
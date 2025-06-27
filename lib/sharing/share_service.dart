import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class ShareService {
  static Future<String> createSecureShare(String userId, String certId) async {
    final token = const Uuid().v4().substring(0, 6); // 6-digit token
    final expiresAt = DateTime.now().add(const Duration(hours: 24)); // Expires in 24h

    final docId = const Uuid().v4();
    await FirebaseFirestore.instance.collection('shared_certs').doc(docId).set({
      'userId': userId,
      'certId': certId,
      'token': token,
      'expiresAt': expiresAt.toIso8601String(),
    });

    // Shareable link (simulate with route like /verify/:docId)
    return 'https://yourapp.com/view/$docId'; // You can use dynamic links or in-app navigation
  }

  static Future<bool> verifyToken(String docId, String inputToken) async {
    final doc = await FirebaseFirestore.instance.collection('shared_certs').doc(docId).get();

    if (!doc.exists) return false;

    final data = doc.data()!;
    final token = data['token'];
    final expiry = DateTime.parse(data['expiresAt']);

    if (inputToken == token && DateTime.now().isBefore(expiry)) {
      return true;
    }

    return false;
  }

  static Future<Map<String, dynamic>?> getCertificateMetadata(String docId) async {
    final doc = await FirebaseFirestore.instance.collection('shared_certs').doc(docId).get();

    if (!doc.exists) return null;

    final userId = doc['userId'];
    final certId = doc['certId'];

    final certDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('certificates')
        .doc(certId)
        .get();

    return certDoc.data();
  }
}
//
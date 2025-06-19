import 'package:flutter/material.dart';
import '../sharing/share_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ShareCertificatePage extends StatefulWidget {
  const ShareCertificatePage({super.key});

  @override
  State<ShareCertificatePage> createState() => _ShareCertificatePageState();
}

class _ShareCertificatePageState extends State<ShareCertificatePage> {
  final certIdController = TextEditingController();
  String? shareLink;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Share Certificate')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: certIdController,
              decoration: const InputDecoration(labelText: 'Certificate ID'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              child: const Text('Generate Secure Link'),
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  final link = await ShareService.createSecureShare(user.uid, certIdController.text);
                  setState(() {
                    shareLink = link;
                  });
                }
              },
            ),
            const SizedBox(height: 20),
            if (shareLink != null)
              SelectableText('Secure Link:\n$shareLink', textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

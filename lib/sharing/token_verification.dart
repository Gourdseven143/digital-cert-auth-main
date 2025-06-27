import 'package:flutter/material.dart';
import 'share_service.dart';
import 'viewer_certificate_screen.dart';

class TokenVerificationPage extends StatefulWidget {
  final String docId;
  const TokenVerificationPage({required this.docId, super.key});

  @override
  State<TokenVerificationPage> createState() => _TokenVerificationPageState();
}

class _TokenVerificationPageState extends State<TokenVerificationPage> {
  final tokenController = TextEditingController();
  String? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enter Access Token')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: tokenController,
              decoration: InputDecoration(
                labelText: 'Token',
                errorText: error,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final success = await ShareService.verifyToken(widget.docId, tokenController.text.trim());

                if (success) {
                  final certData = await ShareService.getCertificateMetadata(widget.docId);
                  if (certData != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ViewerCertificateScreen(data: certData),
                      ),
                    );
                  }
                } else {
                  setState(() {
                    error = 'Invalid or expired token';
                  });
                }
              },
              child: const Text('Verify'),
            ),
          ],
        ),
      ),
    );
  }
}
//
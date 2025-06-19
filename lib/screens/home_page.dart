import 'package:flutter/material.dart';
import 'issue_certificate_page.dart';
import 'share_certificate_page.dart';
import '../sharing/token_verification.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Digital Certificate Repository')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              child: const Text('Issue Certificate'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const IssueCertificatePage()),
                );
              },
            ),
            ElevatedButton(
              child: const Text('Share Certificate'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ShareCertificatePage()),
                );
              },
            ),
            ElevatedButton(
              child: const Text('Viewer Access (Test)'),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) {
                    final controller = TextEditingController();
                    return AlertDialog(
                      title: const Text('Enter Shared Link ID'),
                      content: TextField(controller: controller),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TokenVerificationPage(docId: controller.text),
                              ),
                            );
                          },
                          child: const Text('Open'),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
//
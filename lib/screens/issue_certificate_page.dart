import 'package:flutter/material.dart';
import '../certificate/issue_certificate.dart';
import 'package:firebase_auth/firebase_auth.dart';

class IssueCertificatePage extends StatefulWidget {
  const IssueCertificatePage({super.key});

  @override
  State<IssueCertificatePage> createState() => _IssueCertificatePageState();
}

class _IssueCertificatePageState extends State<IssueCertificatePage> {
  final nameController = TextEditingController();
  final courseController = TextEditingController();
  String? message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Issue Certificate')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Full Name'),
            ),
            TextField(
              controller: courseController,
              decoration: const InputDecoration(labelText: 'Certificate Title'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              child: const Text('Generate & Issue'),
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  await issueCertificate(
                    user.uid,
                    nameController.text,
                    courseController.text,
                  );
                  setState(() {
                    message = 'Certificate issued successfully.';
                  });
                }
              },
            ),
            if (message != null) ...[
              const SizedBox(height: 10),
              Text(message!, style: const TextStyle(color: Colors.green)),
            ]
          ],
        ),
      ),
    );
  }
}
//
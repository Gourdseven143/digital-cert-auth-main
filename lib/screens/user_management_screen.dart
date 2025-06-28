import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../ca_home_page.dart';

import '../recipient_home_page.dart';

class RoleSelectionPage extends StatelessWidget {
  final User user;

  const RoleSelectionPage({Key? key, required this.user}) : super(key: key);

  void setRole(BuildContext context, String role) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set({'email': user.email, 'role': role});

    if (role == 'CA') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const CAHomePage()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const RecipientHomePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Role')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Please select your role:',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => setRole(context, 'CA'),
              child: const Text('Certificate Authority (CA)'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => setRole(context, 'Recipient'),
              child: const Text('Recipient'),
            ),
          ],
        ),
      ),
    );
  }
}

// ✅ 新增这个类
class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('用户管理')),
      body: const Center(
        child: Text('这里是用户管理页面'),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ca_home_page.dart';
import 'recipient_home_page.dart';
import 'check_user_role_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  Future<String> _getUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'guest';

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    return doc.data()?['role'] ?? 'unknown';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _getUserRole(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: Text('Can not select role')),
          );
        }

        final role = snapshot.data!.toLowerCase().trim();
        debugPrint('Current role: $role');

        return Scaffold(
          appBar: AppBar(title: const Text('Dashboard - CA')),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Welcome! Your role is: ${role.toUpperCase()}'),
                const SizedBox(height: 20),
                // CA 用户按钮
                if (role == 'ca')
                  ElevatedButton(
                    onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const CAHomePage()),
                    ),
                    child: const Text('Enter the CA controller'),
                  ),
                // Recipient 用户按钮
                if (role == 'recipient')
                  ElevatedButton(
                    onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const RecipientHomePage()),
                    ),
                    child: const Text('Enter Recipient home page'),
                  ),
                // 其他角色或无角色用户
                if (role != 'ca' && role != 'recipient')
                  const Text('Please contact with Admin to set a role'),
              ],
            ),
          ),
        );
      },
    );
  }
}
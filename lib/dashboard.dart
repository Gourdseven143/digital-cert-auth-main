import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  Future<String> getUserRole() async {
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
      future: getUserRole(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();
        final role = snapshot.data!;

        if (role == 'recipient') {
          return const RecipientDashboard();
        } else {
          return Scaffold(
            appBar: AppBar(title: Text('Dashboard - $role')),
            body: Center(child: Text('Welcome! Your role is: $role')),
          );
        }
      },
    );
  }
}

class RecipientDashboard extends StatelessWidget {
  const RecipientDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Certificates'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.popUntil(context, (route) => route.isFirst);
            },
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('certificates')
            .where('recipientEmail', isEqualTo: user!.email)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const CircularProgressIndicator();

          final certs = snapshot.data!.docs;

          if (certs.isEmpty) {
            return const Center(child: Text('No certificates found.'));
          }

          return ListView.builder(
            itemCount: certs.length,
            itemBuilder: (context, index) {
              final cert = certs[index];
              return ListTile(
                title: Text(cert['title'] ?? 'Untitled Certificate'),
                subtitle: Text('Issued by: ${cert['issuer'] ?? 'N/A'}'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  // Optional: open certificate detail page
                },
              );
            },
          );
        },
      ),
    );
  }
}

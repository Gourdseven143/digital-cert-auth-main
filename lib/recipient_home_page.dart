import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'login_page.dart';
import 'models/certificate.dart';

class RecipientHomePage extends StatefulWidget {
  const RecipientHomePage({super.key});

  @override
  State<RecipientHomePage> createState() => _RecipientHomePageState();
}

class _RecipientHomePageState extends State<RecipientHomePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _hasUnreadNotifications = false;

  @override
  void initState() {
    super.initState();
    _checkUnreadNotifications();
  }

  Future<void> _checkUnreadNotifications() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final snapshot = await _firestore
        .collection('notifications')
        .where('recipient_id', isEqualTo: userId)
        .where('is_read', isEqualTo: false)
        .limit(1)
        .get();

    if (mounted) {
      setState(() {
        _hasUnreadNotifications = snapshot.docs.isNotEmpty;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text('Please login first')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Certificates'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _confirmLogout(context),
          ),
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications),
                if (_hasUnreadNotifications)
                  Positioned(
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () => _showNotifications(context, userId),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCertificateRequestDialog(context, userId),
        child: const Icon(Icons.add),
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: 'Approved'),
                Tab(text: 'Pending'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildCertificatesList(userId, 'approved'),
                  _buildCertificatesList(userId, 'pending'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCertificatesList(String userId, String status) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('certificates')
          .where('recipient_uid', isEqualTo: userId)
          .where('status', isEqualTo: status)
          .snapshots(), // 先移除orderBy测试
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('Certificate without $status status'));
        }

        // 直接使用docs，不过滤
        final docs = snapshot.data!.docs;

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            try {
              final cert = Certificate.fromFirestore(doc);
              return CertificateCard(
                cert: cert,
                onDownload: () => _downloadCertificate(context, cert),
              );
            } catch (e) {
              debugPrint('Certificate parsing error: $e');
              return ListTile(
                title: Text('Broken certificate'),
                subtitle: Text('ID: ${doc.id}'),
              );
            }
          },
        );
      },
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await _performLogout(context);
    }
  }

  Future<void> _performLogout(BuildContext context) async {
    try {
      await _auth.signOut();
      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: ${e.toString()}')),
      );
    }
  }

  Future<void> _showCertificateRequestDialog(BuildContext context, String userId) async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request New Certificate'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Certificate Title*'),
            ),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (titleController.text.isEmpty) return;

              try {
                await _firestore.collection('certificates').add({
                  'title': titleController.text,
                  'description': descriptionController.text,
                  'recipient_uid': userId,
                  'recipient_email': _auth.currentUser!.email!,
                  'status': 'pending',
                  'type': 'user_requested',
                  'created_at': FieldValue.serverTimestamp(),
                  'storage_path': 'certificates/pending/${DateTime.now().millisecondsSinceEpoch}',
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Request submitted successfully!')),
                );
                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: ${e.toString()}')),
                );
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Future<void> _showNotifications(BuildContext context, String userId) async {
    final snapshot = await _firestore
        .collection('notifications')
        .where('recipient_id', isEqualTo: userId)
        .orderBy('created_at', descending: true)
        .get();

    for (final doc in snapshot.docs) {
      await doc.reference.update({'is_read': true});
    }

    if (mounted) {
      setState(() {
        _hasUnreadNotifications = false;
      });
    }

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notifications'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: snapshot.docs.length,
            itemBuilder: (context, index) {
              final notification = snapshot.docs[index];
              return ListTile(
                title: Text(notification['title']),
                subtitle: Text(notification['message']),
                trailing: Text(
                  notification['created_at'].toDate().toString().split(' ')[0],
                  style: const TextStyle(fontSize: 12),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadCertificate(BuildContext context, Certificate cert) async {
    try {
      final url = cert.pdfUrl;
      if (url == null) throw Exception('No PDF URL available');
      debugPrint('Downloading certificate: ${cert.title}');
      // 这里加下载逻辑
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download failed: $e')),
      );
    }
  }
}


class CertificateCard extends StatelessWidget {
  final Certificate cert;
  final VoidCallback onDownload;

  const CertificateCard({
    super.key,
    required this.cert,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              cert.title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text('Issuer: ${cert.issuerUid ?? 'Pending approval'}'),
            Text('Created: ${_formatDate(cert.createdAt)}'),
            if (cert.approvedAt != null)
              Text('Approved: ${_formatDate(cert.approvedAt!)}'),
            const SizedBox(height: 8),
            Row(
              children: [
                Chip(
                  label: Text(cert.status.toUpperCase()),
                  backgroundColor: _getStatusColor(cert.status),
                ),
                const Spacer(),
                if (cert.pdfUrl != null) ...[
                  IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: () => _shareCertificate(
                      context,
                      {
                        'title': cert.title,
                        'pdf_url': cert.pdfUrl,
                        'issuer': cert.issuerUid,
                        'date': _formatDate(cert.approvedAt ?? cert.createdAt),
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.download),
                    onPressed: onDownload,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _shareCertificate(BuildContext context, Map<String, dynamic> data) {
    final shareContent = 'Check out my certificate: ${data['title']}\n'
        'Download link: ${data['pdf_url'] ?? 'Not available'}';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share Certificate'),
        content: SelectableText(shareContent),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Clipboard.setData(ClipboardData(text: shareContent));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copied to clipboard')),
              );
            },
            child: const Text('Copy'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green[100]!;
      case 'pending':
        return Colors.orange[100]!;
      case 'rejected':
        return Colors.red[100]!;
      default:
        return Colors.grey[200]!;
    }
  }
}

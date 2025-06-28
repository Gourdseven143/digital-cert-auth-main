import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'certificate_pdf_service.dart';
import 'models/certificate.dart';

class CAApprovalPage extends StatelessWidget {
  const CAApprovalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pending Approvals')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('certificates')
            .where('status', isEqualTo: 'pending')
            .where('type', isEqualTo: 'user_requested')
            .orderBy('created_at')
            .snapshots().handleError((error) => debugPrint('Firestore 查询错误: $error')),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final cert = Certificate.fromFirestore(snapshot.data!.docs[index]);
              return CertificateApprovalCard(cert: cert);
            },
          );
        },
      ),
    );
  }
}

class CertificateApprovalCard extends StatelessWidget {
  final Certificate cert;

  const CertificateApprovalCard({super.key, required this.cert});

  Future<void> _approveCertificate(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final storage = FirebaseStorage.instance;

      // 1. 生成带批准水印的PDF
      final pdfBytes = await CertificatePDF.generateOfficialCertificate(
        recipientName: cert.recipientEmail.split('@').first,
        courseTitle: cert.title,
        organization: 'Approved by ${user.email?.split('@').first ?? 'Admin'}',
        issueDate: DateTime.now(),
        status: 'approved',
      );

      // 2. 上传到approved目录
      final newPath = cert.storagePath.replaceAll('pending', 'approved');
      await storage.ref(newPath).putData(pdfBytes);
      final downloadUrl = await storage.ref(newPath).getDownloadURL();

      // 3. 更新数据库
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        transaction.update(
          FirebaseFirestore.instance.collection('certificates').doc(cert.id),
          {
            'status': 'approved',
            'issuer_uid': user.uid,
            'approver_uid': user.uid,
            'approved_at': FieldValue.serverTimestamp(),
            'pdf_url': downloadUrl,
            'storage_path': newPath,
          },
        );
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Certificate approved!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Approval failed: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _rejectCertificate(BuildContext context) async {
    try {
      await FirebaseFirestore.instance.collection('certificates').doc(cert.id).update({
        'status': 'rejected',
        'rejected_at': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Certificate rejected')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rejection failed: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: ListTile(
        title: Text(cert.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(cert.recipientEmail),
            Text('Requested: ${_formatDate(cert.createdAt)}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.check, color: Colors.green),
              onPressed: () => _approveCertificate(context),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: () => _rejectCertificate(context),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day}';
  }
}

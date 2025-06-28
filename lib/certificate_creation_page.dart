import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'certificate_pdf_service.dart';
import 'user_search_delegate.dart';

class CertificateCreationPage extends StatefulWidget {
  const CertificateCreationPage({super.key});

  @override
  State<CertificateCreationPage> createState() => _CertificateCreationPageState();
}

class _CertificateCreationPageState extends State<CertificateCreationPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _organizationController = TextEditingController();
  DocumentSnapshot? _recipient;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create a certificate')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Card(
                child: ListTile(
                  title: const Text('Recipient'),
                  subtitle: Text(_recipient?['email'] ?? 'Not selected'),
                  trailing: const Icon(Icons.search),
                  onTap: () async {
                    final result = await showSearch(
                      context: context,
                      delegate: UserSearchDelegate(),
                    );
                    if (result != null) {
                      setState(() => _recipient = result);
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Certificate Title*',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'describe',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _organizationController,
                decoration: const InputDecoration(
                  labelText: 'Issuing Authority*',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitCertificate,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator()
                    : const Text('Create a certificate'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitCertificate() async {
    if (!_formKey.currentState!.validate()) return;
    if (_recipient == null || _recipient?['email'] == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a valid recipient')),
        );
      }
      return;
    }

    if (mounted) {
      setState(() => _isSubmitting = true);
    }

    try {
      final recipientName = _recipient!['name']?.toString() ??
          _recipient!['email'].toString().split('@').first;
      final title = _titleController.text.trim();
      final organization = _organizationController.text.trim();

      final pdfBytes = await CertificatePDF.generateOfficialCertificate(
        recipientName: recipientName,
        courseTitle: title,
        organization: organization,
        issueDate: DateTime.now(),
      ).timeout(const Duration(seconds: 10));

      final storagePath =
          'certificates/approved/${DateTime.now().millisecondsSinceEpoch}.pdf';
      final uploadTask =
      FirebaseStorage.instance.ref(storagePath).putData(pdfBytes);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('certificates').add({
        'title': title,
        'description': _descriptionController.text.trim(),
        'recipient_uid': _recipient!.id,
        'recipient_email': _recipient!['email'],
        'issuer_uid': FirebaseAuth.instance.currentUser!.uid,
        'status': 'approved',
        'type': 'ca_created',
        'pdf_url': downloadUrl,
        'storage_path': storagePath,
        'created_at': FieldValue.serverTimestamp(),
        'approved_at': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        // 在pop之前，先取消加载状态
        setState(() => _isSubmitting = false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('证书创建成功!')),
        );

        //Navigator.of(context).pop();
      }
    } on TimeoutException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Operation timeout，Please try again')),
        );
        setState(() => _isSubmitting = false);
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Database error: ${e.code}')),
        );
        setState(() => _isSubmitting = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred: ${e.toString()}')),
        );
        setState(() => _isSubmitting = false);
      }
    }
  }


  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _organizationController.dispose();
    super.dispose();
  }
}

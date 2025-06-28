import 'package:cloud_firestore/cloud_firestore.dart';

class Certificate {
  final String id;
  final String title;
  final String description;
  final String recipientUid;
  final String recipientEmail;
  final String? issuerUid;
  final String? approverUid;
  final String status; // draft/pending/approved/rejected/revoked
  final String? pdfUrl;
  final String storagePath;
  final DateTime createdAt;
  final DateTime? approvedAt;
  final DateTime? issueDate;
  final String type; // 'ca_created' or 'user_requested'

  Certificate({
    required this.id,
    required this.title,
    required this.description,
    required this.recipientUid,
    required this.recipientEmail,
    this.issuerUid,
    this.approverUid,
    required this.status,
    this.pdfUrl,
    required this.storagePath,
    required this.createdAt,
    this.approvedAt,
    this.issueDate,
    required this.type,
  });

  factory Certificate.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Certificate(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      recipientUid: data['recipient_uid'] ?? '',
      recipientEmail: data['recipient_email'] ?? data['email'] ?? '',
      issuerUid: data['issuer_uid'],
      approverUid: data['approver_uid'] ?? data['approve_r_uid'],
      status: data['status'] ?? 'draft',
      pdfUrl: data['pdf_url'],
      storagePath: data['storage_path'] ?? '',
      createdAt: (data['created_at'] as Timestamp).toDate(),
      approvedAt: data['approved_at']?.toDate(),
      issueDate: data['issue_date']?.toDate(),
      type: data['type'] ?? 'user_requested',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'recipient_uid': recipientUid,
      'recipient_email': recipientEmail,
      if (issuerUid != null) 'issuer_uid': issuerUid,
      if (approverUid != null) 'approver_uid': approverUid,
      'status': status,
      if (pdfUrl != null) 'pdf_url': pdfUrl,
      'storage_path': storagePath,
      'created_at': Timestamp.fromDate(createdAt),
      if (approvedAt != null) 'approved_at': Timestamp.fromDate(approvedAt!),
      if (issueDate != null) 'issue_date': Timestamp.fromDate(issueDate!),
      'type': type,
    };
  }
}
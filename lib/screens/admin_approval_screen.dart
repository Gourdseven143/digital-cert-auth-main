import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminApprovalScreen extends StatefulWidget {
  const AdminApprovalScreen({super.key});

  @override
  State<AdminApprovalScreen> createState() => _AdminApprovalScreenState();
}

class _AdminApprovalScreenState extends State<AdminApprovalScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<String> _selectedRules = [];

  // 元数据验证规则
  final List<Map<String, dynamic>> _metadataRules = [
    {'name': '必须包含证书编号', 'key': 'cert_id', 'required': true},
    {'name': '必须包含颁发日期', 'key': 'issue_date', 'required': true},
    {'name': '必须包含机构名称', 'key': 'issuing_org', 'required': true},
    {'name': '文件大小需小于5MB', 'key': 'file_size', 'max': 5 * 1024 * 1024},
  ];

  Future<void> _approveDocument(String docId) async {
    await _firestore.collection('true_copies').doc(docId).update({
      'status': 'approved',
      'approved_by': FirebaseAuth.instance.currentUser!.uid,
      'approved_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _rejectDocument(String docId) async {
    await _firestore.collection('true_copies').doc(docId).update({
      'status': 'rejected',
      'rejected_by': FirebaseAuth.instance.currentUser!.uid,
      'rejected_at': FieldValue.serverTimestamp(),
    });
  }

  bool _validateMetadata(Map<String, dynamic> metadata) {
    for (final rule in _metadataRules) {
      if (rule['required'] == true && !_selectedRules.contains(rule['name'])) {
        continue; // 跳过未选择的规则
      }

      if (rule['required'] == true) {
        final content = metadata['detected_content'] as List?;
        if (content == null || !content.any((item) => item.contains(rule['key']))) {
          return false;
        }
      }

      if (rule.containsKey('max') && metadata['file_size'] > rule['max']) {
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('证书审批面板'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showRuleSettings(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // 规则选择区域
          if (_selectedRules.isNotEmpty) 
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Wrap(
                spacing: 8,
                children: _selectedRules.map((rule) => Chip(
                  label: Text(rule),
                  onDeleted: () => setState(() => _selectedRules.remove(rule)),
                )).toList(),
              ),
            ),
          
          // 待审批文件列表
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('true_copies')
                  .where('status', isEqualTo: 'pending')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('没有待审批的文件'));
                }
                
                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final isValid = _validateMetadata(data['metadata'] ?? {});
                    
                    return Card(
                      margin: const EdgeInsets.all(8),
                      color: isValid ? null : Colors.orange[50],
                      child: ListTile(
                        title: Text(data['file_name'] ?? '未命名文件'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('上传时间: ${(data['uploaded_at'] as Timestamp).toDate()}'),
                            if (data['metadata'] != null) ...[
                              const SizedBox(height: 4),
                              Text('检测到: ${(data['metadata']['detected_content'] as List).join(', ')}'),
                            ],
                            if (!isValid) const Text('❌ 不符合元数据规则', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.visibility, color: Colors.blue),
                              onPressed: () async {
                                final url = data['download_url'];
                                if (url != null && await canLaunchUrl(Uri.parse(url))) {
                                  await launchUrl(Uri.parse(url));
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.check, color: Colors.green),
                              onPressed: () => _approveDocument(doc.id),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () => _rejectDocument(doc.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showRuleSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('元数据验证规则'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: _metadataRules.map((rule) => CheckboxListTile(
                title: Text(rule['name']),
                value: _selectedRules.contains(rule['name']),
                onChanged: (value) => setState(() {
                  if (value == true) {
                    _selectedRules.add(rule['name']);
                  } else {
                    _selectedRules.remove(rule['name']);
                  }
                }),
              )).toList(),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}
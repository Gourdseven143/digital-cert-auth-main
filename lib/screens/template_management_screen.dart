import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TemplateManagementScreen extends StatefulWidget {
  const TemplateManagementScreen({super.key});

  @override
  State<TemplateManagementScreen> createState() => _TemplateManagementScreenState();
}

class _TemplateManagementScreenState extends State<TemplateManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<Map<String, dynamic>> _templates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    try {
      final snapshot = await _firestore.collection('certificate_templates').get();
      setState(() {
        _templates.clear();
        for (var doc in snapshot.docs) {
          _templates.add({
            'id': doc.id,
            ...doc.data(),
          });
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('证书模板管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addNewTemplate,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _templates.isEmpty
              ? const Center(child: Text('没有模板数据'))
              : ListView.builder(
                  itemCount: _templates.length,
                  itemBuilder: (context, index) {
                    final template = _templates[index];
                    return ListTile(
                      leading: const Icon(Icons.design_services, size: 36), // 修复的图标
                      title: Text(template['name'] ?? '未命名模板'),
                      subtitle: Text(template['description'] ?? '无描述'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _editTemplate(template),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deleteTemplate(template['id']),
                          ),
                        ],
                      ),
                      onTap: () => _viewTemplateDetails(template),
                    );
                  },
                ),
    );
  }

  void _addNewTemplate() {
    _showTemplateForm();
  }

  void _editTemplate(Map<String, dynamic> template) {
    _showTemplateForm(template: template);
  }

  void _viewTemplateDetails(Map<String, dynamic> template) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(template['name'] ?? '模板详情'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTemplateDetail('名称', template['name']),
              _buildTemplateDetail('描述', template['description']),
              _buildTemplateDetail('背景色', template['backgroundColor']),
              _buildTemplateDetail('字体', template['fontFamily']),
              _buildTemplateDetail('水印', template['hasWatermark'] == true ? '是' : '否'),
              _buildTemplateDetail('创建时间', template['createdAt']?.toDate().toString() ?? '未知'),
            ],
          ),
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

  Widget _buildTemplateDetail(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value ?? '无')),
        ],
      ),
    );
  }

  void _showTemplateForm({Map<String, dynamic>? template}) {
    final nameController = TextEditingController(text: template?['name']);
    final descController = TextEditingController(text: template?['description']);
    final bgColorController = TextEditingController(text: template?['backgroundColor']);
    final fontController = TextEditingController(text: template?['fontFamily']);
    bool hasWatermark = template?['hasWatermark'] ?? true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(template == null ? '添加新模板' : '编辑模板'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: '模板名称',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(
                      labelText: '模板描述',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: bgColorController,
                    decoration: const InputDecoration(
                      labelText: '背景颜色 (十六进制)',
                      border: OutlineInputBorder(),
                      prefixText: '#',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: fontController,
                    decoration: const InputDecoration(
                      labelText: '字体',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    title: const Text('包含水印'),
                    value: hasWatermark,
                    onChanged: (value) => setState(() => hasWatermark = value ?? true),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              ElevatedButton(
                onPressed: () async {
                  await _saveTemplate(
                    id: template?['id'],
                    name: nameController.text,
                    description: descController.text,
                    backgroundColor: bgColorController.text,
                    fontFamily: fontController.text,
                    hasWatermark: hasWatermark,
                  );
                  Navigator.pop(context);
                },
                child: const Text('保存'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _saveTemplate({
    String? id,
    required String name,
    required String description,
    required String backgroundColor,
    required String fontFamily,
    required bool hasWatermark,
  }) async {
    try {
      final templateData = {
        'name': name,
        'description': description,
        'backgroundColor': backgroundColor,
        'fontFamily': fontFamily,
        'hasWatermark': hasWatermark,
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      if (id == null) {
        templateData['createdAt'] = FieldValue.serverTimestamp();
        await _firestore.collection('certificate_templates').add(templateData);
      } else {
        await _firestore.collection('certificate_templates').doc(id).update(templateData);
      }

      _loadTemplates(); // 刷新列表
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('模板已${id == null ? '添加' : '更新'}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('操作失败: $e')),
      );
    }
  }

  Future<void> _deleteTemplate(String id) async {
    final confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除此模板吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _firestore.collection('certificate_templates').doc(id).delete();
        _loadTemplates(); // 刷新列表
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('模板已删除')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败: $e')),
        );
      }
    }
  }
}
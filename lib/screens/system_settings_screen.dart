import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SystemSettingsScreen extends StatefulWidget {
  const SystemSettingsScreen({super.key});

  @override
  State<SystemSettingsScreen> createState() => _SystemSettingsScreenState();
}

class _SystemSettingsScreenState extends State<SystemSettingsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _metadataRules = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMetadataRules();
  }

  Future<void> _loadMetadataRules() async {
    try {
      final doc = await _firestore.collection('system_settings').doc('metadata_rules').get();
      if (doc.exists) {
        setState(() {
          final data = doc.data();
          if (data != null && data.containsKey('rules')) {
            _metadataRules = List<Map<String, dynamic>>.from(data['rules']);
          }
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print("Error loading metadata rules: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('系统配置')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    '元数据验证规则',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                ..._metadataRules.map((rule) => _buildRuleItem(rule)).toList(),
                const SizedBox(height: 32),
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    '系统参数',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                _buildSystemParameter('最大文件大小', '5 MB'),
                _buildSystemParameter('支持的文件类型', 'PDF, PNG, JPG'),
                _buildSystemParameter('证书有效期', '永久'),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewRule,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildRuleItem(Map<String, dynamic> rule) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: const Icon(Icons.rule),
        title: Text(rule['name'] ?? '未命名规则'),
        subtitle: Text(_getRuleDescription(rule)),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _deleteRule(rule),
        ),
        onTap: () => _editRule(rule),
      ),
    );
  }

  String _getRuleDescription(Map<String, dynamic> rule) {
    if (rule['required'] == true) {
      return '必填字段: ${rule['key']}';
    } else if (rule['max'] != null) {
      return '最大限制: ${rule['max']}';
    } else if (rule['min'] != null) {
      return '最小限制: ${rule['min']}';
    }
    return '自定义规则';
  }

  Widget _buildSystemParameter(String title, String value) {
    return ListTile(
      title: Text(title),
      trailing: Text(value, style: const TextStyle(color: Colors.grey)),
    );
  }

  void _addNewRule() {
    _showRuleForm();
  }

  void _editRule(Map<String, dynamic> rule) {
    _showRuleForm(rule: rule);
  }

  void _showRuleForm({Map<String, dynamic>? rule}) {
    final nameController = TextEditingController(text: rule?['name']);
    final keyController = TextEditingController(text: rule?['key']);
    bool isRequired = rule?['required'] ?? false;
    double? maxValue = rule?['max']?.toDouble();
    double? minValue = rule?['min']?.toDouble();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(rule == null ? '添加新规则' : '编辑规则'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: '规则名称',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: keyController,
                    decoration: const InputDecoration(
                      labelText: '元数据键名',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    title: const Text('必填字段'),
                    value: isRequired,
                    onChanged: (value) => setState(() {
                      isRequired = value ?? false;
                      if (isRequired) {
                        maxValue = null;
                        minValue = null;
                      }
                    }),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    enabled: !isRequired,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '最大值',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => maxValue = double.tryParse(value),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    enabled: !isRequired,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '最小值',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => minValue = double.tryParse(value),
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
                  await _saveRule(
                    rule: rule,
                    name: nameController.text,
                    key: keyController.text,
                    isRequired: isRequired,
                    maxValue: maxValue,
                    minValue: minValue,
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

  Future<void> _saveRule({
    Map<String, dynamic>? rule,
    required String name,
    required String key,
    required bool isRequired,
    double? maxValue,
    double? minValue,
  }) async {
    final newRule = {
      'name': name,
      'key': key,
      'required': isRequired,
    };

    if (!isRequired) {
      if (maxValue != null) newRule['max'] = maxValue;
      if (minValue != null) newRule['min'] = minValue;
    }

    List<Map<String, dynamic>> updatedRules;
    
    if (rule != null) {
      updatedRules = _metadataRules.map((r) => r['name'] == rule['name'] ? newRule : r).toList();
    } else {
      updatedRules = List.from(_metadataRules)..add(newRule);
    }

    try {
      await _firestore.collection('system_settings').doc('metadata_rules').set({
        'rules': updatedRules,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      setState(() {
        _metadataRules = updatedRules;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('规则已${rule == null ? '添加' : '更新'}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('操作失败: $e')),
      );
    }
  }

  Future<void> _deleteRule(Map<String, dynamic> rule) async {
    final confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除规则 "${rule['name']}" 吗？'),
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
      final updatedRules = _metadataRules.where((r) => r['name'] != rule['name']).toList();
      
      try {
        await _firestore.collection('system_settings').doc('metadata_rules').update({
          'rules': updatedRules,
        });
        setState(() => _metadataRules = updatedRules);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败: $e')),
        );
      }
    }
  }
}
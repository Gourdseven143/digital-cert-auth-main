import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('用户管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => showSearchDialog(context),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('没有用户数据'));
          }
          
          var users = snapshot.data!.docs;
          
          // 应用搜索过滤
          if (_searchQuery.isNotEmpty) {
            users = users.where((user) {
              final data = user.data() as Map<String, dynamic>;
              final email = data['email']?.toString().toLowerCase() ?? '';
              final name = data['displayName']?.toString().toLowerCase() ?? '';
              return email.contains(_searchQuery.toLowerCase()) || 
                     name.contains(_searchQuery.toLowerCase());
            }).toList();
          }
          
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final userDoc = users[index];
              final userData = userDoc.data() as Map<String, dynamic>;
              
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blueGrey,
                  child: Text(userData['displayName']?.toString().substring(0,1) ?? 'U'),
                ),
                title: Text(userData['displayName'] ?? '未命名用户'),
                subtitle: Text(userData['email'] ?? '无邮箱'),
                trailing: Switch(
                  value: userData['isActive'] ?? true,
                  onChanged: (value) => _toggleUserStatus(userDoc.id, value),
                ),
                onTap: () => _showUserDetails(userData),
              );
            },
          );
        },
      ),
    );
  }
  
  void showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('搜索用户'),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: '输入邮箱或姓名',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _searchQuery = _searchController.text;
              });
              Navigator.pop(context);
            },
            child: const Text('搜索'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _toggleUserStatus(String userId, bool isActive) async {
    await _firestore.collection('users').doc(userId).update({
      'isActive': isActive,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }
  
  void _showUserDetails(Map<String, dynamic> userData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(userData['displayName'] ?? '用户详情'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailItem('用户ID', userData['uid']),
            _buildDetailItem('邮箱', userData['email']),
            _buildDetailItem('状态', userData['isActive'] == true ? '激活' : '禁用'),
            _buildDetailItem('注册时间', 
              (userData['createdAt'] as Timestamp).toDate().toString()),
          ],
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
  
  Widget _buildDetailItem(String label, String value) {
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
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
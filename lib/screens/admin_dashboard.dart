import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'admin_approval_screen.dart';
import 'user_management_screen.dart';
import 'template_management_screen.dart';
import 'system_settings_screen.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('管理仪表板'),
        backgroundColor: Colors.blueGrey[800],
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        childAspectRatio: 1.0,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          _buildDashboardCard(
            context,
            icon: Icons.pending_actions,
            title: '待审批文件',
            subtitle: '查看并审批上传的证书',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminApprovalScreen()),
            ),
          ),
          _buildDashboardCard(
            context,
            icon: Icons.analytics,
            title: '系统统计',
            subtitle: '查看使用数据',
            onTap: () => _showStatistics(context),
          ),
          _buildDashboardCard(
            context,
            icon: Icons.people,
            title: '用户管理',
            subtitle: '管理用户账户',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UserManagementScreen()),
            ),
          ),
          // 修复: 使用正确的图标 Icons.design_services
          _buildDashboardCard(
            context,
            icon: Icons.design_services, // 修复这里
            title: '模板管理',
            subtitle: '管理证书模板',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TemplateManagementScreen()),
            ),
          ),
          _buildDashboardCard(
            context,
            icon: Icons.settings,
            title: '系统配置',
            subtitle: '调整系统设置',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SystemSettingsScreen()),
            ),
          ),
          _buildDashboardCard(
            context,
            icon: Icons.history,
            title: '操作日志',
            subtitle: '查看系统操作记录',
            onTap: () => _showComingSoon(context),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCard(BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 36, color: Theme.of(context).primaryColor),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showStatistics(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('系统统计'),
        content: FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance.collection('true_copies').get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Text('暂无数据');
            }
            
            final docs = snapshot.data!.docs;
            final total = docs.length;
            final approved = docs.where((doc) => 
              (doc.data() as Map)['status'] == 'approved').length;
            final pending = docs.where((doc) => 
              (doc.data() as Map)['status'] == 'pending').length;
            final rejected = docs.where((doc) => 
              (doc.data() as Map)['status'] == 'rejected').length;
            
            return SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildStatItem('总文件数', total.toString()),
                  _buildStatItem('已批准', '$approved (${(approved/total*100).toStringAsFixed(1)}%)'),
                  _buildStatItem('待审批', '$pending (${(pending/total*100).toStringAsFixed(1)}%)'),
                  _buildStatItem('已拒绝', '$rejected (${(rejected/total*100).toStringAsFixed(1)}%)'),
                  const SizedBox(height: 16),
                  _buildStatItem('活跃用户数', '${_getActiveUsers(docs)}'),
                  const SizedBox(height: 16),
                  _buildStatItem('今日审批', '${_getTodayApprovals(docs)}'),
                ],
              ),
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

  int _getActiveUsers(List<QueryDocumentSnapshot> docs) {
    final userSet = <String>{};
    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      if (data.containsKey('uploaded_by')) {
        userSet.add(data['uploaded_by']);
      }
    }
    return userSet.length;
  }

  int _getTodayApprovals(List<QueryDocumentSnapshot> docs) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['approved_at'] != null) {
        final approvedAt = (data['approved_at'] as Timestamp).toDate();
        return approvedAt.isAfter(today);
      }
      return false;
    }).length;
  }

  Widget _buildStatItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('即将推出'),
        content: const Text('此功能正在开发中，将在下一版本推出'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}
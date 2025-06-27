import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:firebase_auth/firebase_auth.dart';
import 'issue_certificate_page.dart';
import 'share_certificate_page.dart';
import '../sharing/token_verification.dart';
import 'admin_approval_screen.dart';
import 'admin_dashboard.dart';

class CertificatePDF {
  static Future<Uint8List> generateEnhancedCertificate({
    required String recipientName,
    required String courseName,
    required DateTime issueDate,
    Uint8List? logoBytes,
  }) async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              if (logoBytes != null) 
                pw.Image(pw.MemoryImage(logoBytes)), // 修复这里
              pw.SizedBox(height: 20), // 正确使用SizedBox
              pw.Header(
                level: 0,
                text: 'CERTIFICATE OF ACHIEVEMENT',
                textStyle: pw.TextStyle(
                  fontSize: 24, 
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue800
                ),
              ),
              pw.SizedBox(height: 30), // 正确使用SizedBox
              pw.Text('This certifies that', style: const pw.TextStyle(fontSize: 18)),
              pw.SizedBox(height: 20), // 正确使用SizedBox
              pw.Text(
                recipientName, 
                style: pw.TextStyle(
                  fontSize: 30, 
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900
                )
              ),
              pw.SizedBox(height: 20), // 正确使用SizedBox
              pw.Text('has successfully completed', style: const pw.TextStyle(fontSize: 18)),
              pw.SizedBox(height: 10), // 正确使用SizedBox
              pw.Text(
                courseName, 
                style: pw.TextStyle(
                  fontSize: 22, 
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue700
                )
              ),
              pw.SizedBox(height: 40), // 正确使用SizedBox
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Column(children: [
                    pw.Text('_____________'), 
                    pw.Text('Signature', style: const pw.TextStyle(fontSize: 14))
                  ]),
                  pw.Column(children: [
                    pw.Text('_____________'), 
                    pw.Text('Date: ${issueDate.toLocal().toString().split(' ')[0]}', 
                      style: const pw.TextStyle(fontSize: 14))
                  ]),
                ],
              ),
            ],
          );
        },
      ),
    );
    
    return pdf.save();
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Uint8List? _selectedLogo;
  bool _isAdmin = false;
  
  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }
  
  void _checkAdminStatus() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      setState(() {
        // 更精确的管理员检测逻辑
        _isAdmin = user.email!.endsWith('@admin.com') || 
                   user.email!.contains('admin@') ||
                   user.email!.toLowerCase().contains('admin');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('数字证书仓库'),
        backgroundColor: Colors.blueGrey[800],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 普通用户功能
              _buildSectionTitle('证书管理'),
              _buildActionButton(
                icon: Icons.picture_as_pdf,
                label: '生成PDF证书',
                color: Colors.blue[700]!,
                onPressed: () async {
                  try {
                    final pdfBytes = await CertificatePDF.generateEnhancedCertificate(
                      recipientName: "测试用户",
                      courseName: "数字证书管理系统", 
                      issueDate: DateTime.now(),
                    );
                    final tempDir = await getTemporaryDirectory();
                    final file = File('${tempDir.path}/certificate.pdf');
                    await file.writeAsBytes(pdfBytes);
                    await OpenFilex.open(file.path);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('生成失败: $e')),
                    );
                  }
                },
              ),
              _buildActionButton(
                icon: Icons.upload_file,
                label: '上传证书',
                color: Colors.green[700]!,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const UploadPage()),
                  );
                },
              ),
              _buildActionButton(
                icon: Icons.share,
                label: '分享证书',
                color: Colors.teal[700]!,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ShareCertificatePage()),
                  );
                },
              ),
              
              // 管理员专属功能
              if (_isAdmin) ...[
                const SizedBox(height: 30),
                _buildSectionTitle('管理员功能'),
                _buildActionButton(
                  icon: Icons.verified_user,
                  label: '证书审批',
                  color: Colors.orange[700]!,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AdminApprovalScreen()),
                    );
                  },
                ),
                _buildActionButton(
                  icon: Icons.dashboard,
                  label: '管理仪表板',
                  color: Colors.purple[700]!,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AdminDashboard()),
                    );
                  },
                ),
              ],
              
              // 其他通用功能
              const SizedBox(height: 30),
              _buildSectionTitle('其他功能'),
              _buildActionButton(
                icon: Icons.verified,
                label: '签发证书',
                color: Colors.indigo[700]!,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const IssueCertificatePage()),
                  );
                },
              ),
              _buildActionButton(
                icon: Icons.remove_red_eye,
                label: '查看证书(测试)',
                color: Colors.deepOrange[700]!,
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) {
                      final controller = TextEditingController();
                      return AlertDialog(
                        title: const Text('输入分享链接ID'),
                        content: TextField(
                          controller: controller,
                          decoration: const InputDecoration(
                            hintText: '请输入证书ID',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('取消'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              if (controller.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('请输入证书ID')),
                                );
                                return;
                              }
                              
                              Navigator.pop(ctx);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TokenVerificationPage(docId: controller.text),
                                ),
                              );
                            },
                            child: const Text('打开'),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
              
              // 用户信息
              const SizedBox(height: 30),
              _buildUserInfoCard(),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: Colors.grey[600], 
              thickness: 1,
              height: 2,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[800],
                shadows: [
                  Shadow(
                    color: Colors.grey.withOpacity(0.3),
                    blurRadius: 2,
                    offset: const Offset(1, 1),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Divider(
              color: Colors.grey[600], 
              thickness: 1,
              height: 2,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 28),
        label: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            label, 
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white, 
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shadowColor: color.withOpacity(0.4),
        ),
        onPressed: onPressed,
      ),
    );
  }
  
  Widget _buildUserInfoCard() {
    final user = FirebaseAuth.instance.currentUser;
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '用户信息',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
          const SizedBox(height: 10),
          if (user != null) ...[
            if (user.displayName != null)
              _buildUserInfoItem('姓名', user.displayName!),
            if (user.email != null)
              _buildUserInfoItem('邮箱', user.email!),
            _buildUserInfoItem('用户ID', user.uid),
            _buildUserInfoItem('角色', _isAdmin ? '管理员' : '普通用户'),
          ] else 
            const Text('未登录', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
  
  Widget _buildUserInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }
}

// 简化版上传页面（仅用于导航）
class UploadPage extends StatelessWidget {
  const UploadPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('上传证书'),
        backgroundColor: Colors.blueGrey[800],
      ),
      body: const Center(
        child: Text('文件上传功能已单独实现', style: TextStyle(fontSize: 20)),
      ),
    );
  }
}
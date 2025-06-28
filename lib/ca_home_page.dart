import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'ca_approval_page.dart';  // 将审批逻辑移到这里
import 'certificate_creation_page.dart';
import 'user_management_page.dart';
import 'login_page.dart';
class CAHomePage extends StatefulWidget {
  const CAHomePage({Key? key}) : super(key: key);

  @override
  State<CAHomePage> createState() => _CAHomePageState();
}

class _CAHomePageState extends State<CAHomePage> {
  int _selectedIndex = 0;
  Future<void> _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      if (!context.mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()), // 替换为你的登录页
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed: $e')),
        );
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    Widget page;
    switch (_selectedIndex) {
      case 0:
        page = CAApprovalPage();
        break;
      case 1:
        page = CertificateCreationPage();
        break;
      case 2:
        page = UserManagementPage();
        break;
      default:
        page = Container();
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('CA Controller'),
        actions: [
          // 新增登出按钮
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _signOut(context),
          ),
        ],
      ),

      body: page,
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.approval),
            label: 'Approval',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.note_add),
            label: 'Create Certificate',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'User Management',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue[800],
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}
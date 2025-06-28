import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({Key? key}) : super(key: key);

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for users...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          Expanded(
            child: _buildUserList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddUserDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildUserList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .orderBy('name')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No user data'));
        }

        final users = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name = data['name']?.toString().toLowerCase() ?? '';
          final email = data['email']?.toString().toLowerCase() ?? '';
          return name.contains(_searchQuery.toLowerCase()) ||
              email.contains(_searchQuery.toLowerCase());
        }).toList();

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return _buildUserItem(user);
          },
        );
      },
    );
  }

  Widget _buildUserItem(DocumentSnapshot userDoc) {
    final user = userDoc.data() as Map<String, dynamic>;
    final screenWidth = MediaQuery.of(context).size.width;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          radius: 22,
          backgroundImage: user['photoUrl'] != null
              ? NetworkImage(user['photoUrl'])
              : null,
          child: user['photoUrl'] == null
              ? Text(user['name']?.substring(0, 1) ?? '?')
              : null,
        ),
        title: Text(
          user['name'] ?? 'Unnamed User',
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          user['email'] ?? 'No email',
          overflow: TextOverflow.ellipsis,
        ),
        trailing: SizedBox(
          width: screenWidth * 0.28, // 动态宽度
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Chip(
                    label: Text(
                      user['role'] ?? 'Not set',
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                    backgroundColor: _getRoleColor(user['role']),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => _showEditUserDialog(userDoc),
              ),
            ],
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      ),
    );
  }

  Color _getRoleColor(String? role) {
    switch (role) {
      case 'CA':
        return Colors.blue[100]!;
      case 'Recipient':
        return Colors.green[100]!;
      default:
        return Colors.grey[200]!;
    }
  }

  void _showAddUserDialog() {
    showDialog(
      context: context,
      builder: (context) => _UserEditDialog(
        onSave: (email, role) async {
          try {
            // 实际项目中应通过邮件邀请用户
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('User invitation sent')));
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Add failed: $e')));
          }
        },
      ),
    );
  }

  void _showEditUserDialog(DocumentSnapshot userDoc) {
    final user = userDoc.data() as Map<String, dynamic>;

    showDialog(
      context: context,
      builder: (context) => _UserEditDialog(
        initialEmail: user['email'],
        initialRole: user['role'],
        onSave: (email, role) async {
          try {
            await userDoc.reference.update({
              'role': role,
              'lastUpdated': FieldValue.serverTimestamp(),
            });

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('User information updated')));
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Update Failed: $e')));
            }
          }
        },
      ),
    );
  }
}

class _UserEditDialog extends StatefulWidget {
  final String? initialEmail;
  final String? initialRole;
  final Function(String email, String role) onSave;

  const _UserEditDialog({
    Key? key,
    this.initialEmail,
    this.initialRole,
    required this.onSave,
  }) : super(key: key);

  @override
  State<_UserEditDialog> createState() => _UserEditDialogState();
}

class _UserEditDialogState extends State<_UserEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _email;
  late String _role;
  final List<String> _availableRoles = ['CA', 'Recipient'];

  @override
  void initState() {
    super.initState();
    _email = widget.initialEmail ?? '';
    _role = widget.initialRole ?? 'Recipient';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialEmail == null ? 'Adding Users' : 'Edit User'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.initialEmail == null)
                TextFormField(
                  decoration: const InputDecoration(labelText: 'User mailbox'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email address';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                  onSaved: (value) => _email = value!,
                ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _role,
                items: _availableRoles
                    .map((role) => DropdownMenuItem(
                  value: role,
                  child: Text(role),
                ))
                    .toList(),
                onChanged: (value) => setState(() => _role = value!),
                decoration: const InputDecoration(labelText: 'User roles'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();
              widget.onSave(_email, _role);
              Navigator.pop(context);
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserSearchDelegate extends SearchDelegate<DocumentSnapshot?> { // 明确声明可返回null
  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null), // 明确返回null表示取消
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) => [
    IconButton(
      icon: const Icon(Icons.clear),
      onPressed: () => query = '',
    )
  ];

  @override
  Widget buildResults(BuildContext context) => _buildUserList();

  @override
  Widget buildSuggestions(BuildContext context) => _buildUserList();

  Widget _buildUserList() {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .where('name', isGreaterThanOrEqualTo: query)
          .limit(10)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();
        return ListView(
          children: snapshot.data!.docs.map((doc) => ListTile(
            title: Text(doc['name']),
            onTap: () => close(context, doc), // 返回选中的文档
          )).toList(),
        );
      },
    );
  }
}
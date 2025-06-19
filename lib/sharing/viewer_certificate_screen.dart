import 'package:flutter/material.dart';

class ViewerCertificateScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const ViewerCertificateScreen({required this.data, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Certificate Viewer')),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Name: ${data['fullName']}"),
            Text("Course: ${data['title']}"),
            Text("Issuer: ${data['issuer']}"),
            Text("Date: ${data['issueDate']}"),
            Text("Signature: ${data['signature'].toString().substring(0, 20)}..."),
          ],
        ),
      ),
    );
  }
}
//
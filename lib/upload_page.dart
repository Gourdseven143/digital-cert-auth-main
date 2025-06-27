import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pdf_text/pdf_text.dart'; // 确保这行存在

class UploadPage extends StatefulWidget {
  const UploadPage({super.key});

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  File? _selectedFile;
  String? _fileName;
  int? _fileSize;
  String? _fileType;
  bool _isUploading = false;
  double _uploadProgress = 0;
  String? _downloadURL;
  Map<String, dynamic> _extractedMetadata = {};

  Future<void> pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        withData: false,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'png', 'jpeg'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final fileName = result.files.single.name;
        final fileSize = await file.length();
        final fileType = result.files.single.extension ?? 'unknown';

        // 提取元数据
        final metadata = await _extractMetadata(file, fileType);
        
        setState(() {
          _selectedFile = file;
          _fileName = fileName;
          _fileSize = fileSize;
          _fileType = fileType;
          _extractedMetadata = metadata;
          _downloadURL = null; // 重置下载URL
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('文件选择错误: $e')),
        );
      }
    }
  }

  // 元数据提取方法（使用pdf_text）
  Future<Map<String, dynamic>> _extractMetadata(File file, String fileType) async {
    final metadata = <String, dynamic>{
      'file_type': fileType,
      'file_size': await file.length(),
      'detected_content': [],
    };

    try {
      if (fileType == 'pdf') {
        // PDF文本提取
        final pdfDoc = await PDFDoc.fromFile(file);
        final text = await pdfDoc.text;
        metadata['page_count'] = pdfDoc.length;
        metadata['detected_content'] = _analyzePdfText(text);
      } else if (['jpg', 'png', 'jpeg'].contains(fileType)) {
        // 图片元数据（实际项目中可用ML Kit OCR）
        metadata['detected_content'] = ['图像文件 - OCR功能需额外实现'];
      }
    } catch (e) {
      metadata['error'] = '元数据提取失败: $e';
    }
    
    return metadata;
  }

  List<String> _analyzePdfText(String text) {
    final results = <String>[];
    
    // 检测证书编号
    final certIdRegex = RegExp(r'[A-Z]{2,3}-\d{4,6}');
    final certIdMatches = certIdRegex.allMatches(text);
    if (certIdMatches.isNotEmpty) {
      results.add('证书编号: ${certIdMatches.first.group(0)}');
    }
    
    // 检测日期
    final dateRegex = RegExp(r'\d{4}-\d{2}-\d{2}');
    final dateMatches = dateRegex.allMatches(text);
    if (dateMatches.isNotEmpty) {
      results.add('颁发日期: ${dateMatches.first.group(0)}');
    }
    
    // 检测机构名称
    const orgKeywords = ['University', 'Institute', 'College', 'Organization', 'Certification', '机构', '学院', '大学', '证书'];
    for (final keyword in orgKeywords) {
      if (text.contains(keyword)) {
        results.add('颁发机构: $keyword');
        break;
      }
    }
    
    return results.isNotEmpty ? results : ['未检测到关键信息'];
  }

  Future<void> uploadFile() async {
    if (_selectedFile == null) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('用户未登录，请先登录');
      
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('true_copy/${user.uid}/${DateTime.now().millisecondsSinceEpoch}_$_fileName');

      // 添加上传进度监听
      final uploadTask = storageRef.putFile(_selectedFile!);
      
      uploadTask.snapshotEvents.listen((taskSnapshot) {
        if (mounted) {
          setState(() {
            _uploadProgress = taskSnapshot.bytesTransferred / taskSnapshot.totalBytes;
          });
        }
      });
      
      await uploadTask;
      final downloadURL = await storageRef.getDownloadURL();

      // 存储到Firestore
      await FirebaseFirestore.instance.collection('true_copies').add({
        'file_name': _fileName,
        'file_size': _fileSize,
        'file_type': _fileType,
        'uploaded_at': Timestamp.now(),
        'download_url': downloadURL,
        'user_id': user.uid,
        'status': 'pending', // 审批状态
        'metadata': _extractedMetadata, // 提取的元数据
      });

      if (mounted) {
        setState(() {
          _downloadURL = downloadURL;
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('上传成功! 等待管理员审批')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('上传失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('真实副本上传'),
        actions: [
          if (_downloadURL != null) IconButton(
            icon: const Icon(Icons.share),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: _downloadURL!));
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('下载链接已复制到剪贴板')),
                );
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // 文件选择区域
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: pickFile,
                      icon: const Icon(Icons.upload_file),
                      label: const Text('选择文件'),
                    ),
                    const SizedBox(height: 20),
                    if (_fileName != null) ...[
                      _buildInfoRow('文件名称:', _fileName!),
                      _buildInfoRow('文件大小:', '${(_fileSize! / 1024).toStringAsFixed(2)} KB'),
                      _buildInfoRow('文件类型:', _fileType!),
                    ] else
                      const Text('未选择文件', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
            
            // 元数据展示区域
            if (_extractedMetadata.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('提取的元数据:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      ..._extractedMetadata['detected_content'].map<Widget>((item) => 
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Text('• $item'),
                        )).toList(),
                      if (_extractedMetadata.containsKey('page_count'))
                        _buildInfoRow('总页数:', _extractedMetadata['page_count'].toString()),
                    ],
                  ),
                ),
              ),
            
            // 上传按钮区域
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Column(
                children: [
                  if (_isUploading) LinearProgressIndicator(value: _uploadProgress),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _selectedFile != null && !_isUploading ? uploadFile : null,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: _isUploading
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(color: Colors.white),
                              SizedBox(width: 10),
                              Text('上传中...'),
                            ],
                          )
                        : const Text('上传文件', style: TextStyle(fontSize: 18)),
                  ),
                ],
              ),
            ),
            
            // 下载链接区域
            if (_downloadURL != null)
              Card(
                color: Colors.green[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('上传成功!', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                      const SizedBox(height: 10),
                      const Text('下载链接:'),
                      const SizedBox(height: 5),
                      SelectableText(_downloadURL!, style: const TextStyle(fontSize: 14)),
                      const SizedBox(height: 10),
                      const Text('状态: 等待管理员审批', style: TextStyle(color: Colors.orange)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 10),
          Text(value),
        ],
      ),
    );
  }
}
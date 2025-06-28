import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


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

        final metadata = await _extractMetadata(file, fileType);

        setState(() {
          _selectedFile = file;
          _fileName = fileName;
          _fileSize = fileSize;
          _fileType = fileType;
          _extractedMetadata = metadata;
          _downloadURL = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed selecting role: $e')),
        );
      }
    }
  }

  // ✅ 不依赖 pdf_text / pdfx 的简化版本
  Future<Map<String, dynamic>> _extractMetadata(File file, String fileType) async {
    final metadata = <String, dynamic>{
      'file_type': fileType,
      'file_size': await file.length(),
      'detected_content': [],
    };

    try {
      if (fileType == 'pdf') {
        metadata['detected_content'] = ['PDF file (Does not enable file getting)'];
      } else if (['jpg', 'png', 'jpeg'].contains(fileType)) {
        metadata['detected_content'] = ['Image file (OCR function does not enable)'];
      } else {
        metadata['detected_content'] = ['Unknown file type'];
      }
    } catch (e) {
      metadata['error'] = 'Failed getting Metadata : $e';
    }

    return metadata;
  }

  Future<void> uploadFile() async {
    if (_selectedFile == null) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Please login first');

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('true_copy/${user.uid}/${DateTime.now().millisecondsSinceEpoch}_$_fileName');

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

      await FirebaseFirestore.instance.collection('true_copies').add({
        'file_name': _fileName,
        'file_size': _fileSize,
        'file_type': _fileType,
        'uploaded_at': Timestamp.now(),
        'download_url': downloadURL,
        'user_id': user.uid,
        'status': 'pending',
        'metadata': _extractedMetadata,
      });

      if (mounted) {
        setState(() {
          _downloadURL = downloadURL;
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload success! Wait for Admin approval')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed upload: $e')),
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
        title: const Text('True copy upload'),
        actions: [
          if (_downloadURL != null)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: _downloadURL!));
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Download link copied to clipboard')),
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
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: pickFile,
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Select File'),
                    ),
                    const SizedBox(height: 20),
                    if (_fileName != null) ...[
                      _buildInfoRow('File name:', _fileName!),
                      _buildInfoRow('File size:', '${(_fileSize! / 1024).toStringAsFixed(2)} KB'),
                      _buildInfoRow('File Type:', _fileType!),
                    ] else
                      const Text('No file selected', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
            if (_extractedMetadata.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Extracted metadata:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      ..._extractedMetadata['detected_content'].map<Widget>((item) =>
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Text('• $item'),
                          )).toList(),
                    ],
                  ),
                ),
              ),
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
                              Text('Uploading...'),
                            ],
                          )
                        : const Text('Upload files', style: TextStyle(fontSize: 18)),
                  ),
                ],
              ),
            ),
            if (_downloadURL != null)
              Card(
                color: Colors.green[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Upload Successfully!', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                      const SizedBox(height: 10),
                      const Text('Download Link:'),
                      const SizedBox(height: 5),
                      SelectableText(_downloadURL!, style: const TextStyle(fontSize: 14)),
                      const SizedBox(height: 10),
                      const Text('Status: Waiting for administrator approval', style: TextStyle(color: Colors.orange)),
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

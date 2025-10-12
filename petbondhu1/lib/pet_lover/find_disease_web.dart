// find_disease_web.dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class FindDiseasePage extends StatefulWidget {
  const FindDiseasePage({Key? key}) : super(key: key);

  @override
  State<FindDiseasePage> createState() => _FindDiseasePageState();
}

class _FindDiseasePageState extends State<FindDiseasePage> {
  XFile? _picked;
  Uint8List? _bytes;
  bool _uploading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    Firebase.initializeApp();
  }

  Future<void> _pickAndUpload() async {
    final p = await _picker.pickImage(source: ImageSource.gallery);
    if (p == null) return;
    final b = await p.readAsBytes();
    setState(() { _picked = p; _bytes = b; _uploading = true; });
    try {
      final base64Image = base64Encode(b);
      await FirebaseFirestore.instance.collection('disease_name').add({
        'image': base64Image,
        'disease': 'unknown (web)',
        'timestamp': FieldValue.serverTimestamp(),
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uploaded (web)')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    } finally {
      setState(() { _uploading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Find Disease (web)'), backgroundColor: Colors.deepPurple),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                child: _bytes == null ? const Center(child: Text('TFLite not supported on web. Choose an image to upload.')) : Image.memory(_bytes!, fit: BoxFit.contain),
              ),
            ),
            const SizedBox(height: 12),
            if (_uploading) const LinearProgressIndicator(),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.photo_library),
              label: const Text('Pick & Upload'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
              onPressed: _uploading ? null : _pickAndUpload,
            ),
            const SizedBox(height: 8),
            const Text('Note: model inference runs on mobile only.'),
          ],
        ),
      ),
    );
  }
}

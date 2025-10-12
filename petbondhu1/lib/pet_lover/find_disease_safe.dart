import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    setState(() { _picked = p; });
    final b = await p.readAsBytes();
    setState(() { _bytes = b; _uploading = true; });
    final base64Image = base64Encode(b);
    await FirebaseFirestore.instance.collection('disease_name').add({
      'image': base64Image,
      'disease': 'unknown (web-safe)',
      'timestamp': FieldValue.serverTimestamp(),
    });
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uploaded')));
    setState(() { _uploading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Find Disease (safe)'), backgroundColor: Colors.deepPurple),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
              child: _bytes == null ? const Center(child: Text('Model inference disabled in this build')) : Image.memory(_bytes!),
            ),
          ),
          const SizedBox(height: 12),
          if (_uploading) const LinearProgressIndicator(),
          const SizedBox(height: 12),
          ElevatedButton.icon(icon: const Icon(Icons.photo_library), label: const Text('Pick & Upload'), onPressed: _pickAndUpload, style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple)),
        ],),
      ),
    );
  }
}

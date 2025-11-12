import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class FindDiseasePage extends StatefulWidget {
  const FindDiseasePage({Key? key}) : super(key: key);
  @override
  State<FindDiseasePage> createState() => _FindDiseasePageState();
}

class _FindDiseasePageState extends State<FindDiseasePage> {
  final ImagePicker _picker = ImagePicker();
  Uint8List? _bytes;
  bool _loading = false;
  String? _status;
  Map<String, dynamic>? _backendResult;
  String? _predictedDisease;
  double? _predictedConfidence;

  Future<void> _pickImage() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _bytes = bytes;
      _status = null;
    });
  }

  Future<void> _predictBackend() async {
    if (!kIsWeb) {
      setState(() => _status = 'Backend prediction currently supported on Web only.');
      return;
    }
    if (_bytes == null) return;

    setState(() {
      _loading = true;
      _status = null;
    });

    try {
      final uri = Uri.parse('http://localhost:8000/predict');
      final request = http.MultipartRequest('POST', uri);
      request.files.add(http.MultipartFile.fromBytes('file', _bytes!, filename: 'upload.png', contentType: MediaType('image', 'png')));

      final streamed = await request.send();
      final resp = await http.Response.fromStream(streamed);
      if (resp.statusCode != 200) {
        setState(() => _status = 'Backend error: ${resp.statusCode}');
        return;
      }
      final decoded = jsonDecode(resp.body) as Map<String, dynamic>;

      // Extract common fields if available
      final pred = decoded['predicted_disease'] ?? decoded['prediction_class'] ?? decoded['label'] ?? null;
      double? conf;
      try {
        final c = decoded['confidence'] ?? decoded['score'] ?? decoded['probability'] ?? decoded['prob'];
        if (c is num) conf = c.toDouble();
        if (c is String) conf = double.tryParse(c);
      } catch (_) {
        conf = null;
      }

      // Prepare document with base64 image URL (data URL). Note: Firestore
      // documents have size limits (~1MB). Make sure images are reasonably
      // small. This stores the image directly in the `image_url` field.
      final dataUrl = 'data:image/png;base64,${base64Encode(_bytes!)}';
      final doc = <String, dynamic>{
        'image_url': dataUrl,
        'predicted_class': pred?.toString() ?? 'Unknown',
        'predicted_prob': conf ?? 0.0,
        'time': FieldValue.serverTimestamp(),
        'backend_result': decoded,
      };

      // Try to write to the root `prediction` collection first (this matches
      // your existing documents). If that fails due to rules, try a per-user
      // fallback when the user is authenticated. Otherwise surface a clear
      // message so the user can sign in or adjust rules.
      try {
        await FirebaseFirestore.instance.collection('prediction').add(doc);
        setState(() {
          _backendResult = decoded;
          _predictedDisease = pred?.toString();
          _predictedConfidence = conf;
          _status = 'Prediction saved';
        });
      } on FirebaseException catch (fe) {
        if (fe.code == 'permission-denied') {
          final currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser != null) {
            try {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(currentUser.uid)
                  .collection('predictions')
                  .add(doc);
              setState(() {
                _backendResult = decoded;
                _predictedDisease = pred?.toString();
                _predictedConfidence = conf;
                _status = 'Prediction saved to your profile (users/${currentUser.uid}/predictions)';
              });
            } on FirebaseException catch (fe2) {
              setState(() => _status = 'Failed to save prediction: ${fe2.code} — ${fe2.message ?? 'permission error'}');
            }
          } else {
            setState(() => _status = 'Request failed: [cloud_firestore/permission-denied] Missing or insufficient permissions. Sign in to save predictions.');
          }
        } else {
          setState(() => _status = 'Failed to save prediction: ${fe.message}');
        }
      }
    } catch (e) {
      setState(() => _status = 'Request failed: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Find Disease (Backend)')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Expanded(
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
                child: _bytes == null
                    ? const Text('Pick an image to predict')
                    : Image.memory(_bytes!),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Pick Image'),
                  onPressed: _pickImage,
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.cloud_upload),
                  label: const Text('Predict (backend)'),
                  onPressed: _loading ? null : _predictBackend,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_loading) const LinearProgressIndicator(),
            const SizedBox(height: 8),
            if (_status != null) Text(_status!, style: const TextStyle(color: Colors.black87)),
            if (_predictedDisease != null || _predictedConfidence != null)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: _ResultCard(
                  disease: _predictedDisease ?? 'Unknown',
                  confidence: _predictedConfidence ?? 0.0,
                  rawResult: _backendResult,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final String disease;
  final double confidence; // expected 0.0 - 1.0
  final Map<String, dynamic>? rawResult;

  const _ResultCard({Key? key, required this.disease, required this.confidence, this.rawResult}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final pct = (confidence * 100).clamp(0, 100).toDouble();
    final barColor = confidence >= 0.75
        ? Colors.green
        : confidence >= 0.5
            ? Colors.orange
            : Colors.red;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics, size: 20, color: Colors.blueAccent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(disease, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                Text('${pct.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Container(
                height: 12,
                color: Colors.grey.shade300,
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: (confidence.clamp(0.0, 1.0)),
                  child: Container(color: barColor),
                ),
              ),
            ),
            if (rawResult != null) ...[
              const SizedBox(height: 10),
              Text('Details:', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
              const SizedBox(height: 6),
              Text(rawResult.toString(), style: const TextStyle(fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }
}


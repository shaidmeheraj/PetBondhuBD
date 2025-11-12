import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite/tflite.dart';

class FindDiseasePage extends StatefulWidget {
  const FindDiseasePage({super.key});

  @override
  State<FindDiseasePage> createState() => _FindDiseasePageState();
}

class _FindDiseasePageState extends State<FindDiseasePage> {
  final ImagePicker _picker = ImagePicker();

  File? _image;
  bool _busy = false;
  String? _topLabel;
  double? _topConfidence; // 0..1
  List<Map<String, dynamic>> _topK = const []; // keep top results

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  Future<void> _loadModel() async {
    setState(() => _busy = true);
    try {
      await Tflite.close(); // clean any previous
      final res = await Tflite.loadModel(
        model: 'assets/disease_model.tflite',
        labels: 'assets/labels.txt',
      );
      // debug print: res should be "success"
      // print('TFLite loadModel: $res');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load model: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickFromGallery() async {
    final XFile? x = await _picker.pickImage(source: ImageSource.gallery);
    if (x == null) return;
    setState(() {
      _image = File(x.path);
      _topLabel = null;
      _topConfidence = null;
      _topK = const [];
    });
  }

  Future<void> _predict() async {
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload an image first.')),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      /// Most stable path: pass `path` to runModelOnImage.
      /// Adjust imageMean/imageStd only if you normalized differently during training.
      final results = await Tflite.runModelOnImage(
        path: _image!.path,
        numResults: 5,         // top-5
        threshold: 0.0,        // show even low-confidence; tweak if you want
        imageMean: 0.0,        // typical for models trained with /255
        imageStd: 255.0,       // -> arr/255.0 internally
        asynch: true,
      );

      // results is a List<Map>: [{index: 0, label: 'X', confidence: 0.93}, ...]
      if (!mounted) return;
      if (results != null && results.isNotEmpty) {
        // Sort by confidence desc just to be safe
        results.sort((a, b) =>
            (b['confidence'] as double).compareTo(a['confidence'] as double));

        final top = results.first;
        setState(() {
          _topLabel = (top['label'] as String?)?.trim();
          _topConfidence = (top['confidence'] as double?) ?? 0.0;
          _topK = results.cast<Map<String, dynamic>>();
        });
      } else {
        setState(() {
          _topLabel = 'No prediction';
          _topConfidence = 0.0;
          _topK = const [];
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Prediction failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    Tflite.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Find Disease')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Image preview
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.dividerColor),
                ),
                clipBehavior: Clip.antiAlias,
                child: _image == null
                    ? Center(
                        child: Text(
                          'No image selected',
                          style: theme.textTheme.bodyMedium,
                        ),
                      )
                    : Image.file(_image!, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 16),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _busy ? null : _pickFromGallery,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Upload'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _busy ? null : _predict,
                  icon: const Icon(Icons.science),
                  label: const Text('Predict'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Loader
            if (_busy) const CircularProgressIndicator(),

            // Top result
            if (!_busy && _topLabel != null) ...[
              Text(
                'Prediction',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: const Icon(Icons.pets),
                  title: Text(_topLabel!),
                  subtitle: Text(
                    _topConfidence == null
                        ? ''
                        : 'Confidence: ${(_topConfidence! * 100).toStringAsFixed(2)}%',
                  ),
                ),
              ),
            ],

            // Optional: show top-5
            if (!_busy && _topK.isNotEmpty) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Top matches',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 8),
              ..._topK.map((m) {
                final label = (m['label'] as String?)?.trim() ?? 'Unknown';
                final conf = (m['confidence'] as double?) ?? 0.0;
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.check_circle_outline),
                  title: Text(label, maxLines: 2, overflow: TextOverflow.ellipsis),
                  trailing: Text('${(conf * 100).toStringAsFixed(1)}%'),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

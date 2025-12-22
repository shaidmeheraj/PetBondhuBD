import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

/// Chatbot API helper (reused from chatbot_page.dart)
class _ChatBotApi {
  static Uri _endpoint() {
    final host = kIsWeb
        ? '127.0.0.1'
        : (Platform.isAndroid ? '10.0.2.2' : '127.0.0.1');
    return Uri.parse('http://$host:8000/chat');
  }

  static Future<String> send(String userMessage,
      {Duration timeout = const Duration(seconds: 30)}) async {
    final url = _endpoint();
    try {
      final response = await http
          .post(url,
              headers: {"Content-Type": "application/json"},
              body: jsonEncode({"text": userMessage}))
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return (data['reply'] ?? '').toString();
      } else {
        return 'Server error: ${response.statusCode}';
      }
    } on Exception catch (e) {
      return 'Failed to connect: $e';
    }
  }
}

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

  // New fields for tips & treatment
  String? _tips;
  String? _treatment;
  bool _fetchingAdvice = false;

  Future<void> _pickImage() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _bytes = bytes;
      _status = null;
      _predictedDisease = null;
      _predictedConfidence = null;
      _tips = null;
      _treatment = null;
      _backendResult = null;
    });
  }

  /// Fetch tips and treatment for the predicted disease using chatbot API
  Future<void> _fetchTipsAndTreatment(String disease) async {
    setState(() => _fetchingAdvice = true);
    
    // Fetch tips - concise, professional format with bold key points
    final tipsPrompt = '''For $disease in pets, give exactly 5 short care tips. 
Format each tip as: • **Key Point**: Brief explanation (max 10 words)
Be professional and concise. No intro or conclusion.''';
    final tipsReply = await _ChatBotApi.send(tipsPrompt);
    
    // Fetch treatment - professional, structured format
    final treatmentPrompt = '''For $disease in pets, provide treatment info in this exact format:
**Medication**: List 2-3 common meds briefly
**Home Care**: 2-3 short points
**See Vet If**: Warning signs in 1 line
Keep each section under 15 words. Be professional.''';
    final treatmentReply = await _ChatBotApi.send(treatmentPrompt);
    
    if (mounted) {
      setState(() {
        _tips = tipsReply;
        _treatment = treatmentReply;
        _fetchingAdvice = false;
      });
    }
  }

  Future<void> _predictBackend() async {
    if (!kIsWeb) {
      setState(() => _status = 'Backend prediction');
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
        if (c is num) conf = 13*c.toDouble();
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
        // Fetch tips and treatment after successful prediction
        if (pred != null) {
          _fetchTipsAndTreatment(pred.toString());
        }
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
              // Fetch tips and treatment after successful prediction
              if (pred != null) {
                _fetchTipsAndTreatment(pred.toString());
              }
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
      appBar: AppBar(
        title: const Text('Find Disease'),
        backgroundColor: const Color(0xFF6A00F4),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image preview card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                height: 250,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [Colors.grey.shade100, Colors.grey.shade200],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: _bytes == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.pets, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            'Pick an image to analyze',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                          ),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.memory(_bytes!, fit: BoxFit.cover),
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Pick Image'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF6A00F4),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0xFF6A00F4)),
                      ),
                    ),
                    onPressed: _pickImage,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.search),
                    label: const Text('Analyze'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6A00F4),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: (_loading || _bytes == null) ? null : _predictBackend,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Loading indicator
            if (_loading)
              Column(
                children: [
                  const LinearProgressIndicator(color: Color(0xFF6A00F4)),
                  const SizedBox(height: 8),
                  Text('Analyzing image...', style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),

            // Status message
            if (_status != null && !_loading)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _status!.contains('error') || _status!.contains('failed')
                      ? Colors.red.shade50
                      : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _status!,
                  style: TextStyle(
                    color: _status!.contains('error') || _status!.contains('failed')
                        ? Colors.red.shade700
                        : Colors.green.shade700,
                  ),
                ),
              ),

            // Disease result card
            if (_predictedDisease != null) ...[
              const SizedBox(height: 20),
              _DiseaseResultCard(
                disease: _predictedDisease!,
                confidence: _predictedConfidence ?? 0.0,
                tips: _tips,
                treatment: _treatment,
                isLoadingAdvice: _fetchingAdvice,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Beautiful Disease Result Card with Tips & Treatment
class _DiseaseResultCard extends StatelessWidget {
  final String disease;
  final double confidence;
  final String? tips;
  final String? treatment;
  final bool isLoadingAdvice;

  const _DiseaseResultCard({
    Key? key,
    required this.disease,
    required this.confidence,
    this.tips,
    this.treatment,
    this.isLoadingAdvice = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final pct = (confidence * 100).clamp(0, 100).toDouble();
    final barColor = confidence >= 0.75
        ? Colors.green
        : confidence >= 0.5
            ? Colors.orange
            : Colors.red;

    final severityText = confidence >= 0.75
        ? 'High Confidence'
        : confidence >= 0.5
            ? 'Medium Confidence'
            : 'Low Confidence';

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with disease name
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF6A00F4), const Color(0xFF9B4DFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.medical_services, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Detected Disease',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        disease,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Confidence bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(severityText, style: TextStyle(color: barColor, fontWeight: FontWeight.w600)),
                    Text('${pct.toStringAsFixed(1)}%', style: TextStyle(color: barColor, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: confidence.clamp(0.0, 1.0),
                    minHeight: 10,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(barColor),
                  ),
                ),

                const SizedBox(height: 24),

                // Tips Section
                _SectionHeader(
                  icon: Icons.lightbulb_outline,
                  title: 'Care Tips',
                  iconColor: Colors.amber,
                ),
                const SizedBox(height: 8),
                if (isLoadingAdvice && tips == null)
                  _LoadingPlaceholder(text: 'Fetching care tips...')
                else if (tips != null)
                  _ContentBox(content: tips!, backgroundColor: Colors.amber.shade50)
                else
                  _ContentBox(content: 'Tips will appear after analysis', backgroundColor: Colors.grey.shade100),

                const SizedBox(height: 20),

                // Treatment Section
                _SectionHeader(
                  icon: Icons.healing,
                  title: 'Treatment',
                  iconColor: Colors.teal,
                ),
                const SizedBox(height: 8),
                if (isLoadingAdvice && treatment == null)
                  _LoadingPlaceholder(text: 'Fetching treatment info...')
                else if (treatment != null)
                  _ContentBox(content: treatment!, backgroundColor: Colors.teal.shade50)
                else
                  _ContentBox(content: 'Treatment info will appear after analysis', backgroundColor: Colors.grey.shade100),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color iconColor;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _ContentBox extends StatelessWidget {
  final String content;
  final Color backgroundColor;

  const _ContentBox({required this.content, required this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: _buildRichText(content),
    );
  }

  /// Parse markdown-style **bold** text and render as rich text
  Widget _buildRichText(String text) {
    final spans = <TextSpan>[];
    final regex = RegExp(r'\*\*(.+?)\*\*');
    int lastEnd = 0;

    for (final match in regex.allMatches(text)) {
      // Add normal text before this match
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: const TextStyle(fontSize: 14, height: 1.6, color: Colors.black87),
        ));
      }
      // Add bold text
      spans.add(TextSpan(
        text: match.group(1),
        style: const TextStyle(fontSize: 14, height: 1.6, fontWeight: FontWeight.bold, color: Colors.black87),
      ));
      lastEnd = match.end;
    }

    // Add remaining text after last match
    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: const TextStyle(fontSize: 14, height: 1.6, color: Colors.black87),
      ));
    }

    return RichText(text: TextSpan(children: spans));
  }
}

class _LoadingPlaceholder extends StatelessWidget {
  final String text;
  const _LoadingPlaceholder({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6A00F4)),
          ),
          const SizedBox(width: 12),
          Text(text, style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}


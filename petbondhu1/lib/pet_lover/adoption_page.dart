import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AdoptionPage extends StatefulWidget {
  const AdoptionPage({super.key});

  @override
  State<AdoptionPage> createState() => _AdoptionPageState();
}

class _AdoptionPageState extends State<AdoptionPage> {
  final TextEditingController _petNameCtrl = TextEditingController();
  final TextEditingController _petTypeCtrl = TextEditingController();
  final TextEditingController _petDescCtrl = TextEditingController();
  final TextEditingController _petContactCtrl = TextEditingController();
  final TextEditingController _petImageCtrl = TextEditingController();

  final _adoptFormKey = GlobalKey<FormState>();
  String? _pickedImageBase64;
  bool _saving = false;
  // 0 = available pets listing, 1 = post for adoption form
  int _viewIndex = 0;

  Future<void> _addAdoptionPost() async {
    if (!(_adoptFormKey.currentState?.validate() ?? false)) return;
    try {
      setState(() => _saving = true);
      final imageValue = _pickedImageBase64 ?? _petImageCtrl.text.trim();
      await FirebaseFirestore.instance.collection('post').add({
        'petName': _petNameCtrl.text.trim(),
        'type': _petTypeCtrl.text.trim(),
        'desc': _petDescCtrl.text.trim(),
        'image': imageValue,
        'contact': _petContactCtrl.text.trim(),
        'status': 'available',
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Adoption post added!')));
      _adoptFormKey.currentState?.reset();
      _petNameCtrl.clear();
      _petTypeCtrl.clear();
      _petDescCtrl.clear();
      _petImageCtrl.clear();
      _petContactCtrl.clear();
      setState(() {
        _pickedImageBase64 = null;
        _viewIndex = 0; // return to listings
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _updateAdoptionStatus(DocumentReference ref, String status) async {
    try {
      await ref.update({
        'status': status,
        'statusUpdatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status updated to ${status == 'adopted' ? 'Adopted' : status == 'discussion' ? 'In Discussion' : 'Available'}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update status: $e')));
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? file = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1200, maxHeight: 1200, imageQuality: 80);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final b64 = base64Encode(bytes);
      setState(() {
        _pickedImageBase64 = 'data:image;base64,$b64';
        _petImageCtrl.text = _pickedImageBase64!;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Image pick failed: $e')));
    }
  }

  Widget _adoptPreview() {
    final imageStr = _pickedImageBase64 ?? _petImageCtrl.text.trim();
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 80,
                height: 80,
                color: Colors.grey.shade200,
                child: _buildImageFromString(imageStr, width: 80, height: 80),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _petNameCtrl.text.isEmpty ? 'Pet name' : _petNameCtrl.text,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _petDescCtrl.text.isEmpty ? 'Short description' : _petDescCtrl.text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _adoptionListings() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('post').orderBy('timestamp', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return const Center(child: Text('No pets available yet.'));
        return ListView.separated(
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final imageUrl = (data['image'] ?? '').toString();
            final petName = (data['petName'] ?? 'Pet').toString();
            final type = (data['type'] ?? '').toString();
            final desc = (data['desc'] ?? '').toString();
            final contact = (data['contact'] ?? '').toString();
            final status = (data['status'] ?? 'available').toString();

            Color chipColor;
            String chipLabel;
            switch (status) {
              case 'adopted':
                chipColor = Colors.redAccent;
                chipLabel = 'Adopted';
                break;
              case 'discussion':
                chipColor = Colors.amber;
                chipLabel = 'In Discussion';
                break;
              default:
                chipColor = Colors.green;
                chipLabel = 'Available';
            }

            return Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(children: [
                  ClipRRect(borderRadius: BorderRadius.circular(8), child: Container(width: 80, height: 80, color: Colors.grey.shade100, child: _buildImageFromString(imageUrl, width: 80, height: 80))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$petName ${type.isNotEmpty ? '· $type' : ''}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Chip(
                              label: Text(chipLabel),
                              backgroundColor: chipColor.withOpacity(0.15),
                              labelStyle: TextStyle(color: chipColor, fontWeight: FontWeight.w600),
                              side: BorderSide(color: chipColor.withOpacity(0.3)),
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(desc, maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _showContactDialog(contact),
                        icon: const Icon(Icons.call),
                        label: const Text('Contact'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                      ),
                      const SizedBox(height: 6),
                      PopupMenuButton<String>(
                        tooltip: 'Status',
                        onSelected: (v) => _updateAdoptionStatus(doc.reference, v),
                        itemBuilder: (c) => const [
                          PopupMenuItem(value: 'available', child: Text('Set Available')),
                          PopupMenuItem(value: 'discussion', child: Text('In Discussion')),
                          PopupMenuItem(value: 'adopted', child: Text('Mark Adopted')),
                        ],
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                          child: Text('Change Status'),
                        ),
                      ),
                    ],
                  )
                ]),
              ),
            );
          },
        );
      },
    );
  }

  void _showContactDialog(String contact) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact'),
        content: Text(contact.isEmpty ? 'No contact provided' : contact),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close'))],
      ),
    );
  }

  Widget _buildImageFromString(String? imageStr, {double? width, double? height}) {
    if (imageStr == null || imageStr.isEmpty) return const Icon(Icons.pets, size: 40, color: Colors.teal);
    try {
      if (imageStr.startsWith('data:image')) {
        final comma = imageStr.indexOf(',');
        final payload = comma >= 0 ? imageStr.substring(comma + 1) : imageStr;
        final bytes = base64Decode(payload);
        return Image.memory(bytes, width: width, height: height, fit: BoxFit.cover);
      }
      if (imageStr.startsWith('http') || imageStr.startsWith('https')) {
        return Image.network(imageStr, width: width, height: height, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.pets, size: 40, color: Colors.teal));
      }
      if (imageStr.length > 100) {
        final bytes = base64Decode(imageStr);
        return Image.memory(bytes, width: width, height: height, fit: BoxFit.cover);
      }
    } catch (_) {
      return const Icon(Icons.pets, size: 40, color: Colors.teal);
    }
    return const Icon(Icons.pets, size: 40, color: Colors.teal);
  }

  @override
  void dispose() {
    _petNameCtrl.dispose();
    _petTypeCtrl.dispose();
    _petDescCtrl.dispose();
    _petContactCtrl.dispose();
    _petImageCtrl.dispose();
    super.dispose();
  }

  Widget _buildFormView(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Post for Adoption', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Form(
            key: _adoptFormKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _petNameCtrl,
                  decoration: const InputDecoration(labelText: 'Pet Name'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter pet name' : null,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _petTypeCtrl,
                  decoration: const InputDecoration(labelText: 'Type (Dog/Cat/etc)'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _petDescCtrl,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _petContactCtrl,
                  decoration: const InputDecoration(labelText: 'Contact Number'),
                  keyboardType: TextInputType.phone,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter contact number' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Choose Image'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_pickedImageBase64 != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      height: 160,
                      color: Colors.grey.shade200,
                      child: _buildImageFromString(_pickedImageBase64, width: double.infinity, height: 160),
                    ),
                  ),
                const SizedBox(height: 16),
                _adoptPreview(),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _addAdoptionPost,
                    icon: const Icon(Icons.send),
                    label: Text(_saving ? 'Posting...' : 'Post for Adoption'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adoption'),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          // Toggle buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(12,12,12,0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _viewIndex == 0 ? null : () => setState(() => _viewIndex = 0),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _viewIndex == 0 ? Colors.teal : Colors.grey.shade300,
                      foregroundColor: _viewIndex == 0 ? Colors.white : Colors.black87,
                    ),
                    child: const Text('Available Pets'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _viewIndex == 1 ? null : () => setState(() => _viewIndex = 1),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _viewIndex == 1 ? Colors.blueGrey : Colors.grey.shade300,
                      foregroundColor: _viewIndex == 1 ? Colors.white : Colors.black87,
                    ),
                    child: const Text('Post for Adoption'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
              child: _viewIndex == 0
                  ? Padding(
                      key: const ValueKey('listing'),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: _adoptionListings(),
                    )
                  : Container(
                      key: const ValueKey('form'),
                      color: Colors.white,
                      child: _buildFormView(context),
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: _viewIndex == 0
          ? FloatingActionButton(
              backgroundColor: Colors.teal,
              onPressed: () => setState(() => _viewIndex = 1),
              tooltip: 'Post for Adoption',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

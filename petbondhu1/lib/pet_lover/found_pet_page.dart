import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

class FoundPetPage extends StatefulWidget {
  const FoundPetPage({super.key});

  @override
  State<FoundPetPage> createState() => _FoundPetPageState();
}

class _FoundPetPageState extends State<FoundPetPage> {
  final _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot<Map<String, dynamic>>> _foundPetsStream() {
    return _firestore
        .collection('found_pets')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  void _showAddFoundPetDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => const _AddFoundPetForm(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Found Pets'),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddFoundPetDialog,
        backgroundColor: Colors.green.shade600,
        icon: const Icon(Icons.add),
        label: const Text('Report Found Pet'),
      ),
      body: Column(
        children: [
          // Header banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade600, Colors.green.shade400],
              ),
            ),
            child: Column(
              children: [
                Icon(Icons.favorite, size: 48, color: Colors.white.withOpacity(0.9)),
                const SizedBox(height: 8),
                const Text(
                  'Found a Pet?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Help reunite pets with their owners',
                  style: TextStyle(color: Colors.white.withOpacity(0.85)),
                ),
              ],
            ),
          ),

          // List of found pets
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _foundPetsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          'No found pets reported',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data();
                    return _FoundPetCard(data: data, docId: doc.id);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FoundPetCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;

  const _FoundPetCard({required this.data, required this.docId});

  @override
  Widget build(BuildContext context) {
    final petType = (data['petType'] ?? 'Pet').toString();
    final description = (data['description'] ?? '').toString();
    final whereFound = (data['whereFound'] ?? 'Unknown').toString();
    final pickupAddress = (data['pickupAddress'] ?? '').toString();
    final foundDate = (data['foundDate'] ?? '').toString();
    final contactNumber = (data['contactNumber'] ?? '').toString();
    final image = (data['image'] ?? '').toString();
    final status = (data['status'] ?? 'found').toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            decoration: BoxDecoration(
              color: status == 'claimed' ? Colors.blue : Colors.green.shade600,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(
                  status == 'claimed' ? Icons.check_circle : Icons.pets,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  status == 'claimed' ? 'CLAIMED BY OWNER' : 'WAITING FOR OWNER',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pet image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 100,
                    height: 100,
                    color: Colors.grey.shade200,
                    child: _buildImage(image),
                  ),
                ),
                const SizedBox(width: 12),

                // Pet details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Found $petType',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (foundDate.isNotEmpty)
                        _InfoRow(icon: Icons.calendar_today, text: 'Found: $foundDate'),
                      _InfoRow(icon: Icons.location_on, text: whereFound),
                      if (pickupAddress.isNotEmpty)
                        _InfoRow(icon: Icons.home, text: 'Pickup: $pickupAddress'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Text(
                description,
                style: TextStyle(color: Colors.grey.shade700),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          // Contact button
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _showDetailsDialog(context);
                    },
                    icon: const Icon(Icons.info_outline),
                    label: const Text('Details'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green.shade600,
                      side: BorderSide(color: Colors.green.shade600),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Contact: $contactNumber')),
                      );
                    },
                    icon: const Icon(Icons.phone),
                    label: const Text('Contact'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(String img) {
    if (img.isEmpty) {
      return Icon(Icons.pets, size: 48, color: Colors.grey.shade400);
    }
    if (img.startsWith('data:')) {
      try {
        final bytes = base64Decode(img.split(',').last);
        return Image.memory(bytes, fit: BoxFit.cover);
      } catch (_) {
        return Icon(Icons.pets, size: 48, color: Colors.grey.shade400);
      }
    }
    return Image.network(img, fit: BoxFit.cover, errorBuilder: (_, __, ___) {
      return Icon(Icons.pets, size: 48, color: Colors.grey.shade400);
    });
  }

  void _showDetailsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Found ${data['petType'] ?? 'Pet'}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _DetailItem(label: 'Pet Type', value: data['petType'] ?? 'Unknown'),
              _DetailItem(label: 'Description', value: data['description'] ?? 'N/A'),
              _DetailItem(label: 'Where Found', value: data['whereFound'] ?? 'Unknown'),
              _DetailItem(label: 'Pickup Address', value: data['pickupAddress'] ?? 'N/A'),
              _DetailItem(label: 'Date Found', value: data['foundDate'] ?? 'Unknown'),
              _DetailItem(label: 'Contact', value: data['contactNumber'] ?? 'N/A'),
              _DetailItem(label: 'Reported By', value: data['finderName'] ?? 'Anonymous'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final String label;
  final String value;
  const _DetailItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}

// =================== ADD FOUND PET FORM ===================

class _AddFoundPetForm extends StatefulWidget {
  const _AddFoundPetForm();

  @override
  State<_AddFoundPetForm> createState() => _AddFoundPetFormState();
}

class _AddFoundPetFormState extends State<_AddFoundPetForm> {
  final _formKey = GlobalKey<FormState>();
  final _petTypeCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _whereFoundCtrl = TextEditingController();
  final _pickupAddressCtrl = TextEditingController();
  final _foundDateCtrl = TextEditingController();
  final _contactNumberCtrl = TextEditingController();

  Uint8List? _imageBytes;
  bool _isSubmitting = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() => _imageBytes = bytes);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      String imageData = '';
      if (_imageBytes != null) {
        imageData = 'data:image/png;base64,${base64Encode(_imageBytes!)}';
      }

      await FirebaseFirestore.instance.collection('found_pets').add({
        'petType': _petTypeCtrl.text.trim(),
        'description': _descriptionCtrl.text.trim(),
        'whereFound': _whereFoundCtrl.text.trim(),
        'pickupAddress': _pickupAddressCtrl.text.trim(),
        'foundDate': _foundDateCtrl.text.trim(),
        'contactNumber': _contactNumberCtrl.text.trim(),
        'image': imageData,
        'status': 'found',
        'finderId': user?.uid ?? 'anonymous',
        'finderName': user?.displayName ?? user?.email ?? 'Anonymous',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Found pet report submitted! Thank you!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _petTypeCtrl.dispose();
    _descriptionCtrl.dispose();
    _whereFoundCtrl.dispose();
    _pickupAddressCtrl.dispose();
    _foundDateCtrl.dispose();
    _contactNumberCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.favorite, color: Colors.green.shade600),
                  const SizedBox(width: 8),
                  const Text(
                    'Report Found Pet',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Image picker
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: _imageBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey.shade500),
                            const SizedBox(height: 8),
                            Text('Tap to add photo', style: TextStyle(color: Colors.grey.shade600)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _petTypeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Pet Type (Dog, Cat, etc.) *',
                  prefixIcon: Icon(Icons.category),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _descriptionCtrl,
                decoration: const InputDecoration(
                  labelText: 'Description (color, size, collar, etc.)',
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _whereFoundCtrl,
                decoration: const InputDecoration(
                  labelText: 'Where Found (location/area) *',
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _pickupAddressCtrl,
                decoration: const InputDecoration(
                  labelText: 'Pickup Address (where owner can collect)',
                  prefixIcon: Icon(Icons.home),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _foundDateCtrl,
                decoration: const InputDecoration(
                  labelText: 'Date Found (e.g., Dec 1, 2025)',
                  prefixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _contactNumberCtrl,
                decoration: const InputDecoration(
                  labelText: 'Your Contact Number *',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Submit Report', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

class LostPetPage extends StatefulWidget {
  const LostPetPage({super.key});

  @override
  State<LostPetPage> createState() => _LostPetPageState();
}

class _LostPetPageState extends State<LostPetPage> {
  final _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';

  Stream<QuerySnapshot<Map<String, dynamic>>> _lostPetsStream() {
    return _firestore
        .collection('lost_pets')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  void _showAddLostPetDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => const _AddLostPetForm(),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lost Pets'),
        backgroundColor: Colors.red.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Clear search',
            icon: const Icon(Icons.clear),
            onPressed: _searchTerm.isEmpty
                ? null
                : () {
                    _searchController.clear();
                    setState(() => _searchTerm = '');
                  },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddLostPetDialog,
        backgroundColor: Colors.red.shade600,
        icon: const Icon(Icons.add),
        label: const Text('Report Lost Pet'),
      ),
      body: Column(
        children: [
          // Header banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red.shade600, Colors.red.shade400],
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.pets,
                  size: 48,
                  color: Colors.white.withOpacity(0.9),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Help Find Lost Pets',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Report your lost pet or help reunite others',
                  style: TextStyle(color: Colors.white.withOpacity(0.85)),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (value) =>
                  setState(() => _searchTerm = value.trim().toLowerCase()),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchTerm.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchTerm = '');
                        },
                      ),
                hintText: 'Search by pet name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // List of lost pets
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _lostPetsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final docs = snapshot.data?.docs ?? [];
                final filtered = docs.where((doc) {
                  if (_searchTerm.isEmpty) return true;
                  final name = (doc.data()['petName'] ?? '')
                      .toString()
                      .toLowerCase();
                  return name.contains(_searchTerm);
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No lost pets reported',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final doc = filtered[index];
                    final data = doc.data();
                    return _LostPetCard(data: data, docId: doc.id);
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

class _LostPetCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;

  const _LostPetCard({required this.data, required this.docId});

  @override
  Widget build(BuildContext context) {
    final petName = (data['petName'] ?? 'Unknown').toString();
    final petType = (data['petType'] ?? 'Pet').toString();
    final description = (data['description'] ?? '').toString();
    final lastSeenLocation = (data['lastSeenLocation'] ?? 'Unknown').toString();
    final lastSeenDate = (data['lastSeenDate'] ?? '').toString();
    final contactNumber = (data['contactNumber'] ?? '').toString();
    final image = (data['image'] ?? '').toString();
    final status = (data['status'] ?? 'lost').toString();

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
              color: status == 'found' ? Colors.green : Colors.red.shade600,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  status == 'found' ? Icons.check_circle : Icons.warning,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  status == 'found' ? 'REUNITED' : 'STILL MISSING',
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
                        petName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _InfoRow(icon: Icons.category, text: petType),
                      if (lastSeenDate.isNotEmpty)
                        _InfoRow(
                          icon: Icons.calendar_today,
                          text: 'Lost: $lastSeenDate',
                        ),
                      _InfoRow(icon: Icons.location_on, text: lastSeenLocation),
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
                      foregroundColor: Colors.red.shade600,
                      side: BorderSide(color: Colors.red.shade600),
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
                      backgroundColor: Colors.red.shade600,
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
    return Image.network(
      img,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) {
        return Icon(Icons.pets, size: 48, color: Colors.grey.shade400);
      },
    );
  }

  void _showDetailsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(data['petName'] ?? 'Lost Pet'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _DetailItem(
                label: 'Pet Type',
                value: data['petType'] ?? 'Unknown',
              ),
              _DetailItem(
                label: 'Description',
                value: data['description'] ?? 'N/A',
              ),
              _DetailItem(
                label: 'Last Seen',
                value: data['lastSeenLocation'] ?? 'Unknown',
              ),
              _DetailItem(
                label: 'Date Lost',
                value: data['lastSeenDate'] ?? 'Unknown',
              ),
              _DetailItem(
                label: 'Contact',
                value: data['contactNumber'] ?? 'N/A',
              ),
              _DetailItem(
                label: 'Owner',
                value: data['ownerName'] ?? 'Anonymous',
              ),
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
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}

// =================== ADD LOST PET FORM ===================

class _AddLostPetForm extends StatefulWidget {
  const _AddLostPetForm();

  @override
  State<_AddLostPetForm> createState() => _AddLostPetFormState();
}

class _AddLostPetFormState extends State<_AddLostPetForm> {
  final _formKey = GlobalKey<FormState>();
  final _petNameCtrl = TextEditingController();
  final _petTypeCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _lastSeenLocationCtrl = TextEditingController();
  final _lastSeenDateCtrl = TextEditingController();
  final _contactNumberCtrl = TextEditingController();

  Uint8List? _imageBytes;
  bool _isSubmitting = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
    );
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

      await FirebaseFirestore.instance.collection('lost_pets').add({
        'petName': _petNameCtrl.text.trim(),
        'petType': _petTypeCtrl.text.trim(),
        'description': _descriptionCtrl.text.trim(),
        'lastSeenLocation': _lastSeenLocationCtrl.text.trim(),
        'lastSeenDate': _lastSeenDateCtrl.text.trim(),
        'contactNumber': _contactNumberCtrl.text.trim(),
        'image': imageData,
        'status': 'lost',
        'ownerId': user?.uid ?? 'anonymous',
        'ownerName': user?.displayName ?? user?.email ?? 'Anonymous',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lost pet report submitted!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _petNameCtrl.dispose();
    _petTypeCtrl.dispose();
    _descriptionCtrl.dispose();
    _lastSeenLocationCtrl.dispose();
    _lastSeenDateCtrl.dispose();
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
                  Icon(Icons.warning, color: Colors.red.shade600),
                  const SizedBox(width: 8),
                  const Text(
                    'Report Lost Pet',
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
                            Icon(
                              Icons.add_photo_alternate,
                              size: 40,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap to add photo',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _petNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Pet Name *',
                  prefixIcon: Icon(Icons.pets),
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _petTypeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Pet Type (Dog, Cat, etc.) *',
                  prefixIcon: Icon(Icons.category),
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _descriptionCtrl,
                decoration: const InputDecoration(
                  labelText: 'Description (color, size, distinctive marks)',
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _lastSeenLocationCtrl,
                decoration: const InputDecoration(
                  labelText: 'Last Seen Location *',
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _lastSeenDateCtrl,
                decoration: const InputDecoration(
                  labelText: 'Date Lost (e.g., Dec 1, 2025)',
                  prefixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _contactNumberCtrl,
                decoration: const InputDecoration(
                  labelText: 'Contact Number *',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
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
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Submit Report',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

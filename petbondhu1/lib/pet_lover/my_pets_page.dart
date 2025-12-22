import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';

class MyPetsPage extends StatefulWidget {
  const MyPetsPage({super.key});

  @override
  State<MyPetsPage> createState() => _MyPetsPageState();
}

class _MyPetsPageState extends State<MyPetsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  bool _saving = false;
  String? _pickedDataUrl; // data:<mime>;base64,<...>
  bool _vaccinatedNew = false; // flag when creating a pet

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  // Image picker is invoked inside dialog via StatefulBuilder

  Future<void> _showAddPetDialog() async {
    _nameCtrl.clear();
    _descCtrl.clear();
    _pickedDataUrl = null;
    _vaccinatedNew = false;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Pet'),
        content: StatefulBuilder(
          builder: (context, setLocal) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Pet name')),
                  const SizedBox(height: 8),
                  TextField(controller: _descCtrl, decoration: const InputDecoration(labelText: 'Description'), maxLines: 3),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundImage: _pickedDataUrl != null
                            ? MemoryImage(base64Decode(_pickedDataUrl!.split(',').last)) as ImageProvider
                            : null,
                        child: _pickedDataUrl == null ? const Icon(Icons.pets) : null,
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final ImagePicker picker = ImagePicker();
                          final XFile? file = await picker.pickImage(
                            source: ImageSource.gallery,
                            maxWidth: 1024,
                            maxHeight: 1024,
                            imageQuality: 80,
                          );
                          if (file == null) return;
                          final bytes = await file.readAsBytes();
                          final mime = file.mimeType ?? 'image/jpeg';
                          final b64 = base64Encode(bytes);
                          final dataUrl = 'data:$mime;base64,$b64';
                          setLocal(() {
                            _pickedDataUrl = dataUrl;
                          });
                        },
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Pick Image'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Checkbox(
                        value: _vaccinatedNew,
                        onChanged: (v) => setLocal(() => _vaccinatedNew = v ?? false),
                      ),
                      const Expanded(
                        child: Text(
                          'Mark as vaccinated now',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: _saving ? null : () async {
              final name = _nameCtrl.text.trim();
              final desc = _descCtrl.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter pet name')));
                return;
              }
              setState(() => _saving = true);
                try {
                final String? imageValue = _pickedDataUrl;

                final user = _auth.currentUser;
                if (user == null) throw 'Not signed in';

                final payload = <String, dynamic>{
                  'ownerId': user.uid,
                  'name': name,
                  'desc': desc,
                  'createdAt': FieldValue.serverTimestamp(),
                };
                if (imageValue != null && imageValue.isNotEmpty) {
                  payload['image'] = imageValue;
                }
                if (_vaccinatedNew) {
                  payload['vaccinated'] = true;
                  payload['lastVaccinated'] = FieldValue.serverTimestamp();
                }

                await _firestore.collection('mypet').add(payload);

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pet added')));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to add pet: $e')));
              } finally {
                if (mounted) setState(() => _saving = false);
              }
            },
            child: _saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePet(String id, String? imageUrl) async {
    try {
  await _firestore.collection('mypet').doc(id).delete();
      // Note: storage cleanup omitted (requires firebase_storage)
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pet deleted')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }

  Future<void> _updateVaccination(String id) async {
    try {
      await _firestore.collection('mypet').doc(id).update({
        'vaccinated': true,
        'lastVaccinated': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vaccination updated')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update vaccination: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Pets'), backgroundColor: Colors.deepPurple),
        body: const Center(child: Text('Please log in to view your pets')),
      );
    }

  // Avoid server-side ordering which may require indexes or cause failed-precondition.
  // We'll fetch the user's pets and sort client-side by 'createdAt'.
  final stream = _firestore.collection('mypet').where('ownerId', isEqualTo: user.uid).snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text('My Pets'), backgroundColor: Colors.deepPurple),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        onPressed: _showAddPetDialog,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) return const Center(child: Text('No pets yet. Tap + to add one.'));

          // Convert to list and sort client-side by createdAt (descending).
          final sorted = docs.toList();
          sorted.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aTs = aData['createdAt'];
            final bTs = bData['createdAt'];

            DateTime aDt;
            DateTime bDt;
            if (aTs is Timestamp) aDt = aTs.toDate();
            else if (aTs is DateTime) aDt = aTs;
            else aDt = DateTime.fromMillisecondsSinceEpoch(0);

            if (bTs is Timestamp) bDt = bTs.toDate();
            else if (bTs is DateTime) bDt = bTs;
            else bDt = DateTime.fromMillisecondsSinceEpoch(0);

            return bDt.compareTo(aDt);
          });

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: sorted.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final d = sorted[i];
              final data = d.data() as Map<String, dynamic>;
              final name = data['name'] ?? '';
              final desc = data['desc'] ?? '';
              final image = data['image'] ?? '';

              Widget leadingThumb;
              if (image is String && image.isNotEmpty) {
                if (image.startsWith('data:')) {
                  final bytes = base64Decode(image.split(',').last);
                  leadingThumb = ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(bytes, width: 72, height: 72, fit: BoxFit.cover),
                  );
                } else {
                  leadingThumb = ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(image, width: 72, height: 72, fit: BoxFit.cover),
                  );
                }
              } else {
                leadingThumb = const CircleAvatar(child: Icon(Icons.pets));
              }

              return Card(
                child: ListTile(
                  leading: leadingThumb,
                  title: Text(name),
                  subtitle: Text(desc, maxLines: 2, overflow: TextOverflow.ellipsis),
                  trailing: SizedBox(
                    width: 112,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: data['vaccinated'] == true ? 'Update last vaccinated date' : 'Mark vaccinated',
                          icon: Icon(
                            Icons.vaccines,
                            color: data['vaccinated'] == true ? Colors.green : Colors.grey,
                          ),
                          onPressed: () => _updateVaccination(d.id),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          tooltip: 'Delete pet',
                          onPressed: () {
                            showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Delete pet'),
                                content: const Text('Are you sure you want to delete this pet?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                  TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
                                ],
                              ),
                            ).then((yes) {
                              if (yes == true) _deletePet(d.id, image as String?);
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

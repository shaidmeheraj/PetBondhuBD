import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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
  final TextEditingController _urlCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  // Image picking and storage omitted for now; use image URL input instead.

  Future<void> _showAddPetDialog() async {
    _nameCtrl.clear();
    _descCtrl.clear();
    _urlCtrl.clear();
    // no picked image support in this simplified version

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Pet'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Pet name')),
              const SizedBox(height: 8),
              TextField(controller: _descCtrl, decoration: const InputDecoration(labelText: 'Description'), maxLines: 3),
              const SizedBox(height: 8),
              const SizedBox(height: 8),
              const Text('Image URL (optional)'),
              TextField(controller: _urlCtrl, decoration: const InputDecoration(labelText: 'Image URL')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: _saving ? null : () async {
              final name = _nameCtrl.text.trim();
              final desc = _descCtrl.text.trim();
              final urlText = _urlCtrl.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter pet name')));
                return;
              }
              setState(() => _saving = true);
                try {
                final String imageUrl = urlText;

                final user = _auth.currentUser;
                if (user == null) throw 'Not signed in';

                await _firestore.collection('mypet').add({
                  'ownerId': user.uid,
                  'name': name,
                  'desc': desc,
                  'image': imageUrl,
                  'createdAt': FieldValue.serverTimestamp(),
                });

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

              return Card(
                child: ListTile(
                  leading: (image != null && (image as String).isNotEmpty)
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(image, width: 72, height: 72, fit: BoxFit.cover),
                        )
                      : const CircleAvatar(child: Icon(Icons.pets)),
                  title: Text(name),
                  subtitle: Text(desc, maxLines: 2, overflow: TextOverflow.ellipsis),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
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
                ),
              );
            },
          );
        },
      ),
    );
  }
}

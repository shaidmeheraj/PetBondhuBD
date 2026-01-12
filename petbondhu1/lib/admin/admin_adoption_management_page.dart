import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminAdoptionManagementPage extends StatelessWidget {
  const AdminAdoptionManagementPage({super.key});

  Stream<QuerySnapshot<Map<String, dynamic>>> _postsStream() {
    return FirebaseFirestore.instance
        .collection('post')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> _toggleApprove(BuildContext context, DocumentSnapshot<Map<String, dynamic>> doc) async {
    final data = doc.data() ?? {};
    final current = (data['approved'] ?? false) == true;
    try {
      await doc.reference.update({'approved': !current});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(!current ? 'Marked approved' : 'Marked unapproved')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $e')),
      );
    }
  }

  Future<void> _deletePost(BuildContext context, DocumentSnapshot<Map<String, dynamic>> doc) async {
    final petName = (doc.data()?['petName'] ?? 'Pet').toString();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete Adoption Post'),
        content: Text('Delete "$petName" adoption post?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await doc.reference.delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post deleted')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }

  Widget _buildList(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _postsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(child: Text('No adoption posts yet.'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final d = docs[i];
            final data = d.data();
            final petName = (data['petName'] ?? 'Pet').toString();
            final type = (data['type'] ?? '').toString();
            final desc = (data['desc'] ?? '').toString();
            final approved = (data['approved'] ?? false) == true;
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: Icon(Icons.pets, color: approved ? Colors.green : Colors.teal),
                title: Text('$petName${type.isNotEmpty ? ' · $type' : ''}', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(desc, maxLines: 2, overflow: TextOverflow.ellipsis),
                trailing: Wrap(
                  spacing: 4,
                  children: [
                    IconButton(
                      tooltip: approved ? 'Unapprove' : 'Approve',
                      onPressed: () => _toggleApprove(context, d),
                      icon: Icon(
                        approved ? Icons.check_circle : Icons.cancel,
                        color: approved ? Colors.green : Colors.red,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Delete',
                      onPressed: () => _deletePost(context, d),
                      icon: const Icon(Icons.delete, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin: Adoption Posts'),
        backgroundColor: Colors.teal,
      ),
      body: _buildList(context),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminPetShopManagementPage extends StatelessWidget {
  const AdminPetShopManagementPage({super.key});

  Stream<QuerySnapshot<Map<String, dynamic>>> _productsStream() {
    return FirebaseFirestore.instance
        .collection('product')
        .orderBy('date', descending: true)
        .snapshots();
  }

  Future<void> _toggleApprove(BuildContext context, DocumentSnapshot<Map<String, dynamic>> doc) async {
    final data = doc.data() ?? {};
    final current = (data['approved'] ?? false) == true;
    try {
      await doc.reference.update({'approved': !current});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(!current ? 'Product approved' : 'Product unapproved')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $e')),
      );
    }
  }

  Future<void> _deleteProduct(BuildContext context, DocumentSnapshot<Map<String, dynamic>> doc) async {
    final productName = (doc.data()?['product'] ?? 'Product').toString();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Delete "$productName" product listing?'),
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
        const SnackBar(content: Text('Product deleted')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }

  Widget _buildList(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _productsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(child: Text('No products listed yet.'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final d = docs[i];
            final data = d.data();
            final productName = (data['product'] ?? 'Product').toString();
            final owner = (data['owner'] ?? '').toString();
            final desc = (data['description'] ?? '').toString();
            final approved = (data['approved'] ?? false) == true;
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: Icon(Icons.store, color: approved ? Colors.green : Colors.deepOrange),
                title: Text(productName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Owner: $owner\n$desc', maxLines: 2, overflow: TextOverflow.ellipsis),
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
                      onPressed: () => _deleteProduct(context, d),
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
        title: const Text('Admin: Pet Shop Products'),
        backgroundColor: Colors.deepOrange,
      ),
      body: _buildList(context),
    );
  }
}

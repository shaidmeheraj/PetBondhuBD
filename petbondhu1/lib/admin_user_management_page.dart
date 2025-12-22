import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminUserManagementPage extends StatefulWidget {
  const AdminUserManagementPage({super.key});

  @override
  State<AdminUserManagementPage> createState() => _AdminUserManagementPageState();
}

class _AdminUserManagementPageState extends State<AdminUserManagementPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch all user documents ordered by creation time (most recent first).
  Stream<QuerySnapshot<Map<String, dynamic>>> _userStream() {
    return _firestore
        .collection('users')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> _toggleApproved(DocumentSnapshot<Map<String, dynamic>> doc) async {
    final data = doc.data() ?? {};
    // If field missing treat as false.
    final currentApproved = data['approved'] == true;
    try {
      await doc.reference.update({'approved': !currentApproved});
      final displayName = (data['name'] ?? data['email'] ?? data['uid'] ?? 'User').toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$displayName ${!currentApproved ? 'approved' : 'blocked'}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $e')),
      );
    }
  }

  Future<void> _deleteUser(DocumentSnapshot<Map<String, dynamic>> doc) async {
    final data = doc.data() ?? {};
    final displayName = (data['name'] ?? data['email'] ?? data['uid'] ?? 'User').toString();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete "$displayName"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await doc.reference.delete();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Deleted $displayName')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        backgroundColor: Colors.deepPurple,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _userStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No users found.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();
              final email = (data['email'] ?? 'No email').toString();
              final uid = (data['uid'] ?? 'No UID').toString();
              final role = (data['role'] ?? 'user').toString();
              final approved = data['approved'] == true;
              final createdAtRaw = data['createdAt'];
              String createdAtStr;
              if (createdAtRaw is Timestamp) {
                createdAtStr = createdAtRaw.toDate().toString();
              } else {
                createdAtStr = 'Unknown date';
              }
              final icon = role.toLowerCase() == 'admin'
                  ? Icons.admin_panel_settings
                  : role.toLowerCase() == 'shop owner'
                      ? Icons.store
                      : Icons.person;
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: Icon(icon, color: Colors.deepPurple),
                  title: Text(email, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Role: $role\nUID: $uid\nCreated: $createdAtStr'),
                  trailing: SizedBox(
                    width: 120,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: approved ? 'Block user' : 'Approve user',
                          icon: Icon(
                            approved ? Icons.check_circle : Icons.block,
                            color: approved ? Colors.green : Colors.red,
                          ),
                          onPressed: () => _toggleApproved(doc),
                        ),
                        IconButton(
                          tooltip: 'Delete user',
                          icon: const Icon(Icons.delete, color: Colors.grey),
                          onPressed: () => _deleteUser(doc),
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

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminEmergencyContactManagementPage extends StatelessWidget {
  const AdminEmergencyContactManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Contact Management'),
        backgroundColor: Colors.deepPurple,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('emergency_contacts')
            .orderBy('name')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No contacts yet. Tap + to add.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final d = docs[index];
              final data = d.data();
              final name = (data['name'] ?? '').toString();
              final hospital = (data['hospital'] ?? '').toString();
              final phone = (data['phone'] ?? '').toString();
              final location = (data['location'] ?? '').toString();
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.local_hospital, color: Colors.deepPurple),
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('$hospital\n$location\n$phone'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.orange),
                        onPressed: () => _showAddOrEditDialog(context, doc: d),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final ok = await _confirm(context, 'Delete contact for "$name"?');
                          if (ok == true) {
                            await d.reference.delete();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted')));
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        onPressed: () => _showAddOrEditDialog(context),
        tooltip: 'নতুন Vet/Clinic Add করুন',
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<bool?> _confirm(BuildContext context, String message) {
    return showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Confirm'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(c, true), child: const Text('OK')),
        ],
      ),
    );
  }

  Future<void> _showAddOrEditDialog(BuildContext context, {DocumentSnapshot<Map<String, dynamic>>? doc}) async {
    final nameCtrl = TextEditingController(text: doc?.data()?['name']?.toString() ?? '');
    final hospitalCtrl = TextEditingController(text: doc?.data()?['hospital']?.toString() ?? '');
    final phoneCtrl = TextEditingController(text: doc?.data()?['phone']?.toString() ?? '');
    final locationCtrl = TextEditingController(text: doc?.data()?['location']?.toString() ?? '');
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(doc == null ? 'Add Contact' : 'Edit Contact'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Doctor Name'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter name' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: hospitalCtrl,
                  decoration: const InputDecoration(labelText: 'Hospital/Clinic'),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Phone'),
                  keyboardType: TextInputType.phone,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter phone' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: locationCtrl,
                  decoration: const InputDecoration(labelText: 'Location'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (!(formKey.currentState?.validate() ?? false)) return;
              final data = {
                'name': nameCtrl.text.trim(),
                'hospital': hospitalCtrl.text.trim(),
                'phone': phoneCtrl.text.trim(),
                'location': locationCtrl.text.trim(),
                'updatedAt': FieldValue.serverTimestamp(),
              };
              if (doc == null) {
                await FirebaseFirestore.instance.collection('emergency_contacts').add({
                  ...data,
                  'createdAt': FieldValue.serverTimestamp(),
                });
              } else {
                await doc.reference.update(data);
              }
              if (context.mounted) {
                Navigator.pop(c, true);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(doc == null ? 'Contact added' : 'Contact updated')),
      );
    }
  }
}

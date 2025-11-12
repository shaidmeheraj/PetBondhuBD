import 'package:flutter/material.dart';

class AdminEmergencyContactManagementPage extends StatelessWidget {
  const AdminEmergencyContactManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy vet/clinic data for demonstration
    final List<Map<String, dynamic>> contacts = [
      {'name': 'Dr. Rahman', 'hospital': 'Pet Care Hospital', 'phone': '+880123456789', 'location': 'Dhaka'},
      {'name': 'Dr. Fariha Farjan', 'hospital': 'Barisal Vet Hospital', 'phone': '+8801825809073', 'location': 'Barisal'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Contact Management'),
        backgroundColor: Colors.deepPurple,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: contacts.length,
        itemBuilder: (context, index) {
          final contact = contacts[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.local_hospital, color: Colors.deepPurple),
              title: Text(contact['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${contact['hospital']}\n${contact['location']}\n${contact['phone']}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.orange),
                    onPressed: () {
                      // Update vet/clinic info logic here
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      // Remove vet/clinic info logic here
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        onPressed: () {
          // Add new vet/clinic info logic here
        },
        tooltip: 'নতুন Vet/Clinic Add করুন',
        child: const Icon(Icons.add),
      ),
    );
  }
}

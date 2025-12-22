import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
// For Google Maps integration, you need to add google_maps_flutter package and proper setup in Android/iOS

class EmergencyContactPage extends StatelessWidget {
  EmergencyContactPage({super.key});

  Stream<QuerySnapshot<Map<String, dynamic>>> _contactsStream() {
    return FirebaseFirestore.instance
        .collection('emergency_contacts')
        .orderBy('name')
        .snapshots();
  }

  Future<void> _callVet(BuildContext context, String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not place a call to $phone')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Contact 🚨'),
        backgroundColor: Colors.red,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _contactsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? [];
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (docs.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('No emergency contacts yet.')),
                )
              else
                ...docs.map((d) {
                  final data = d.data();
                  final name = (data['name'] ?? '').toString();
                  final hospital = (data['hospital'] ?? '').toString();
                  final location = (data['location'] ?? '').toString();
                  final phone = (data['phone'] ?? '').toString();
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: const Icon(Icons.local_hospital, color: Colors.red),
                      title: Text(name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (hospital.isNotEmpty) Text('Hospital: $hospital'),
                          if (location.isNotEmpty) Text('Location: $location'),
                          if (phone.isNotEmpty) Text('Phone: $phone'),
                        ],
                      ),
                      trailing: ElevatedButton.icon(
                        icon: const Icon(Icons.call),
                        label: const Text('Call Vet'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        onPressed: phone.isEmpty ? null : () => _callVet(context, phone),
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 24),
              // Placeholder for Google Maps integration
              Card(
                elevation: 2,
                child: ListTile(
                  leading: const Icon(Icons.map, color: Colors.green),
                  title: const Text('Find Nearest Pet Clinic'),
                  subtitle: const Text('Uses GPS and Google Maps'),
                  trailing: ElevatedButton.icon(
                    icon: const Icon(Icons.location_searching),
                    label: const Text('Show on Map'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    onPressed: () {
                      // TODO: Integrate Google Maps and show nearest clinic
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Google Maps integration coming soon!')),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
// For Google Maps integration, you need to add google_maps_flutter package and proper setup in Android/iOS

class EmergencyContactPage extends StatelessWidget {
  final List<Map<String, String>> vets = [
    {
      'name': 'Dr. Rahman',
      'phone': '+880123456789',
      'hospital': 'Pet Care Hospital',
      'location': 'Dhaka, Bangladesh',
    },
    {
      'name': 'Dr. Fariha Farjan',
      'phone': '+8801825809073',
      'hospital': 'Barisal Vet Hospital',
      'location': 'Babuganj, Barisal, Bangladesh',
    },
  ];

  Future<void> _callVet(String phone) async {
    final Uri url = Uri(scheme: 'tel', path: phone);
    if (await canLaunch(url.toString())) {
      await launch(url.toString());
    } else {
      // Could not launch
      throw 'Could not launch $phone';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Contact 🚨'),
        backgroundColor: Colors.red,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ...vets.map((vet) => Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.local_hospital, color: Colors.red),
                  title: Text(vet['name'] ?? ''),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hospital: ${vet['hospital']}'),
                      Text('Location: ${vet['location']}'),
                      Text('Phone: ${vet['phone']}'),
                    ],
                  ),
                  trailing: ElevatedButton.icon(
                    icon: const Icon(Icons.call),
                    label: const Text('Call Vet'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () => _callVet(vet['phone'] ?? ''),
                  ),
                ),
              )),
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
      ),
    );
  }
}

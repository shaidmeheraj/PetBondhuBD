import 'package:flutter/material.dart';

class AdminPetProfileManagementPage extends StatelessWidget {
  const AdminPetProfileManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy pet profile data for demonstration
    final List<Map<String, dynamic>> petProfiles = [
      {'owner': 'Alice', 'petName': 'Tommy', 'type': 'Dog', 'desc': 'Friendly, 2 years old', 'flagged': false},
      {'owner': 'Bob', 'petName': 'Kitty', 'type': 'Cat', 'desc': 'Playful, 1 year old', 'flagged': true},
      {'owner': 'Charlie', 'petName': 'Max', 'type': 'Dog', 'desc': 'Energetic, 3 years old', 'flagged': false},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pet & Profile Management'),
        backgroundColor: Colors.deepPurple,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: petProfiles.length,
        itemBuilder: (context, index) {
          final pet = petProfiles[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: Icon(
                pet['type'] == 'Dog' ? Icons.pets : Icons.pets,
                color: Colors.deepPurple,
              ),
              title: Text('${pet['petName']} (${pet['type']})', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Owner: ${pet['owner']}\n${pet['desc']}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (pet['flagged'])
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        // Remove inappropriate content logic here
                      },
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

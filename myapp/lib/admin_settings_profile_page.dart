import 'package:flutter/material.dart';

class AdminSettingsProfilePage extends StatelessWidget {
  const AdminSettingsProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy admin profile data for demonstration
    final Map<String, String> adminProfile = {
      'name': 'Admin User',
      'email': 'admin@petbondhu.com',
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Admin Profile'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.deepPurple,
                  child: Icon(Icons.person, size: 40, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(adminProfile['name']!, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    Text(adminProfile['email']!, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
            ListTile(
              leading: const Icon(Icons.lock, color: Colors.deepPurple),
              title: const Text('Change Password'),
              onTap: () {
                // Password change logic here
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.deepPurple),
              title: const Text('Logout'),
              onTap: () {
                // Logout logic here
              },
            ),
          ],
        ),
      ),
    );
  }
}

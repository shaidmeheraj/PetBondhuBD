import 'package:flutter/material.dart';

class AdminUserManagementPage extends StatelessWidget {
  const AdminUserManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy user data for demonstration
    final List<Map<String, dynamic>> users = [
      {'name': 'Alice', 'role': 'Pet Lover', 'approved': true},
      {'name': 'Bob', 'role': 'Shop Owner', 'approved': false},
      {'name': 'Charlie', 'role': 'Pet Lover', 'approved': true},
      {'name': 'Daisy', 'role': 'Shop Owner', 'approved': true},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        backgroundColor: Colors.deepPurple,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: Icon(
                user['role'] == 'Shop Owner' ? Icons.store : Icons.pets,
                color: Colors.deepPurple,
              ),
              title: Text(user['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(user['role']),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      user['approved'] ? Icons.check_circle : Icons.block,
                      color: user['approved'] ? Colors.green : Colors.red,
                    ),
                    onPressed: () {
                      // Approve/Block logic here
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.grey),
                    onPressed: () {
                      // Delete user logic here
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

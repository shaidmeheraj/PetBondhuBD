import 'package:flutter/material.dart';

class AdminLostFoundManagementPage extends StatelessWidget {
  const AdminLostFoundManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy lost pet report data for demonstration
    final List<Map<String, dynamic>> lostReports = [
      {'petName': 'Tommy', 'owner': 'Alice', 'desc': 'Lost near park', 'verified': false},
      {'petName': 'Kitty', 'owner': 'Bob', 'desc': 'Missing since yesterday', 'verified': true},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lost & Found Management'),
        backgroundColor: Colors.deepPurple,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: lostReports.length,
        itemBuilder: (context, index) {
          final report = lostReports[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.location_on, color: Colors.deepPurple),
              title: Text(report['petName'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Owner: ${report['owner']}\n${report['desc']}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      report['verified'] ? Icons.verified : Icons.help_outline,
                      color: report['verified'] ? Colors.green : Colors.orange,
                    ),
                    onPressed: () {
                      // Verify logic here
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      // Delete report logic here
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

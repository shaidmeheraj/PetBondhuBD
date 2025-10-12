import 'package:flutter/material.dart';

class AdminTipsKnowledgeHubPage extends StatelessWidget {
  const AdminTipsKnowledgeHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy tips/articles/videos for demonstration
    final List<Map<String, dynamic>> tips = [
      {'title': 'How to care for puppies', 'type': 'Article', 'approved': true},
      {'title': 'Cat grooming tips', 'type': 'Article', 'approved': false},
      {'title': 'Dog training video', 'type': 'Video', 'approved': true},
      {'title': 'User submitted: Homemade pet food', 'type': 'Article', 'approved': false},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tips & Knowledge Hub Management'),
        backgroundColor: Colors.deepPurple,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: tips.length,
        itemBuilder: (context, index) {
          final tip = tips[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: Icon(
                tip['type'] == 'Video' ? Icons.play_circle_fill : Icons.menu_book,
                color: Colors.deepPurple,
              ),
              title: Text(tip['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(tip['type']),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      tip['approved'] ? Icons.check_circle : Icons.cancel,
                      color: tip['approved'] ? Colors.green : Colors.red,
                    ),
                    onPressed: () {
                      // Approve/Reject logic here
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.grey),
                    onPressed: () {
                      // Delete tip/article/video logic here
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
        child: const Icon(Icons.add),
        onPressed: () {
          // Add new article/tip/video logic here
        },
        tooltip: 'নতুন Article/Tip/Video Add করুন',
      ),
    );
  }
}

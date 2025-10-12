import 'package:flutter/material.dart';

class AdminCommunityForumControlPage extends StatelessWidget {
  const AdminCommunityForumControlPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy forum posts/comments for demonstration
    final List<Map<String, dynamic>> forumPosts = [
      {'user': 'Alice', 'content': 'My cat stopped eating, what should I do?', 'reported': false},
      {'user': 'Bob', 'content': 'Try changing the food brand.', 'reported': true},
      {'user': 'Charlie', 'content': 'Visit a vet if it continues.', 'reported': false},
      {'user': 'Daisy', 'content': 'This post is inappropriate.', 'reported': true},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Forum Control'),
        backgroundColor: Colors.deepPurple,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: forumPosts.length,
        itemBuilder: (context, index) {
          final post = forumPosts[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: Icon(
                post['reported'] ? Icons.report : Icons.forum,
                color: post['reported'] ? Colors.red : Colors.deepPurple,
              ),
              title: Text(post['user'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(post['content']),
              trailing: post['reported']
                  ? IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        // Delete reported post/comment logic here
                      },
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }
}

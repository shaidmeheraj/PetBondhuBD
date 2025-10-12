import 'package:flutter/material.dart';

class AdminAdoptionPetShopManagementPage extends StatelessWidget {
  const AdminAdoptionPetShopManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy adoption posts and shop products for demonstration
    final List<Map<String, dynamic>> adoptionPosts = [
      {'petName': 'Tommy', 'type': 'Dog', 'desc': 'Friendly, 2 years old', 'approved': false},
      {'petName': 'Kitty', 'type': 'Cat', 'desc': 'Playful, 1 year old', 'approved': true},
    ];
    final List<Map<String, dynamic>> shopProducts = [
      {'owner': 'Happy Pet Shop', 'product': 'Dog Food', 'desc': 'Premium quality', 'approved': true},
      {'owner': 'Happy Pet Shop', 'product': 'Cat Toy', 'desc': 'Colorful and safe', 'approved': false},
    ];

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Adoption & Pet Shop Management'),
          backgroundColor: Colors.deepPurple,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Adoption Posts'),
              Tab(text: 'Shop Products'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Adoption Posts Tab
            ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: adoptionPosts.length,
              itemBuilder: (context, index) {
                final post = adoptionPosts[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: Icon(post['type'] == 'Dog' ? Icons.pets : Icons.pets, color: Colors.deepPurple),
                    title: Text(post['petName'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${post['desc']}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            post['approved'] ? Icons.check_circle : Icons.cancel,
                            color: post['approved'] ? Colors.green : Colors.red,
                          ),
                          onPressed: () {
                            // Approve/Reject logic here
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.grey),
                          onPressed: () {
                            // Delete post logic here
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            // Shop Products Tab
            ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: shopProducts.length,
              itemBuilder: (context, index) {
                final product = shopProducts[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: const Icon(Icons.store, color: Colors.deepPurple),
                    title: Text(product['product'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Owner: ${product['owner']}\n${product['desc']}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            product['approved'] ? Icons.check_circle : Icons.cancel,
                            color: product['approved'] ? Colors.green : Colors.red,
                          ),
                          onPressed: () {
                            // Approve/Reject logic here
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.grey),
                          onPressed: () {
                            // Remove product logic here
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

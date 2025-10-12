// Adoption & Pet Shop
// ...existing code from lib/adoption_petshop_page.dart...
import 'package:flutter/material.dart';

class AdoptionPetShopPage extends StatefulWidget {
  const AdoptionPetShopPage({super.key});

  @override
  State<AdoptionPetShopPage> createState() => _AdoptionPetShopPageState();
}

class _AdoptionPetShopPageState extends State<AdoptionPetShopPage> {
  final List<Map<String, dynamic>> adoptionPosts = [
    {
      'petName': 'Tommy',
      'type': 'Dog',
      'desc': 'Friendly, 2 years old',
      'contact': '+880123456789',
    },
  ];

  final List<Map<String, dynamic>> shopProducts = [
    {
      'owner': 'Happy Pet Shop',
      'product': 'Dog Food',
      'desc': 'Premium quality',
      'contact': '+880987654321',
    },
    {
      'owner': 'Happy Pet Shop',
      'product': 'Cat Toy',
      'desc': 'Colorful and safe',
      'contact': '+880987654321',
    },
  ];

  final TextEditingController _petNameCtrl = TextEditingController();
  final TextEditingController _petTypeCtrl = TextEditingController();
  final TextEditingController _petDescCtrl = TextEditingController();
  final TextEditingController _petContactCtrl = TextEditingController();

  final TextEditingController _shopOwnerCtrl = TextEditingController();
  final TextEditingController _shopProductCtrl = TextEditingController();
  final TextEditingController _shopDescCtrl = TextEditingController();
  final TextEditingController _shopContactCtrl = TextEditingController();

  bool isShopOwner = false;

  void _addAdoptionPost() {
    if (_petNameCtrl.text.isNotEmpty && _petContactCtrl.text.isNotEmpty) {
      setState(() {
        adoptionPosts.insert(0, {
          'petName': _petNameCtrl.text,
          'type': _petTypeCtrl.text,
          'desc': _petDescCtrl.text,
          'contact': _petContactCtrl.text,
        });
        _petNameCtrl.clear();
        _petTypeCtrl.clear();
        _petDescCtrl.clear();
        _petContactCtrl.clear();
      });
    }
  }

  void _addShopProduct() {
    if (_shopOwnerCtrl.text.isNotEmpty && _shopProductCtrl.text.isNotEmpty && _shopContactCtrl.text.isNotEmpty) {
      setState(() {
        shopProducts.insert(0, {
          'owner': _shopOwnerCtrl.text,
          'product': _shopProductCtrl.text,
          'desc': _shopDescCtrl.text,
          'contact': _shopContactCtrl.text,
        });
        _shopOwnerCtrl.clear();
        _shopProductCtrl.clear();
        _shopDescCtrl.clear();
        _shopContactCtrl.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adoption & Pet Shop 🏪'),
        backgroundColor: Colors.teal,
        actions: [
          Row(
            children: [
              const Text('Shop Owner', style: TextStyle(color: Colors.white)),
              Switch(
                value: isShopOwner,
                onChanged: (val) {
                  setState(() {
                    isShopOwner = val;
                  });
                },
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: isShopOwner ? _buildShopSection() : _buildAdoptionSection(),
      ),
    );
  }

  Widget _buildAdoptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Post for Pet Adoption', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 8),
        TextField(controller: _petNameCtrl, decoration: const InputDecoration(labelText: 'Pet Name')),
        TextField(controller: _petTypeCtrl, decoration: const InputDecoration(labelText: 'Type (Dog/Cat/etc)')),
        TextField(controller: _petDescCtrl, decoration: const InputDecoration(labelText: 'Description')),
        TextField(controller: _petContactCtrl, decoration: const InputDecoration(labelText: 'Contact Number'), keyboardType: TextInputType.phone),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _addAdoptionPost,
          icon: const Icon(Icons.add),
          label: const Text('Post for Adoption'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
        ),
        const SizedBox(height: 16),
        const Text('Available for Adoption:', style: TextStyle(fontWeight: FontWeight.bold)),
        Expanded(
          child: ListView.builder(
            itemCount: adoptionPosts.length,
            itemBuilder: (context, index) {
              final post = adoptionPosts[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.pets, color: Colors.teal),
                  title: Text('${post['petName']} (${post['type']})'),
                  subtitle: Text(post['desc'] ?? ''),
                  trailing: ElevatedButton.icon(
                    icon: const Icon(Icons.call),
                    label: const Text('Contact'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                    onPressed: () {
                      // TODO: Integrate call
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildShopSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('List Pet Shop Products', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 8),
        TextField(controller: _shopOwnerCtrl, decoration: const InputDecoration(labelText: 'Shop Owner Name')),
        TextField(controller: _shopProductCtrl, decoration: const InputDecoration(labelText: 'Product Name')),
        TextField(controller: _shopDescCtrl, decoration: const InputDecoration(labelText: 'Description')),
        TextField(controller: _shopContactCtrl, decoration: const InputDecoration(labelText: 'Contact Number'), keyboardType: TextInputType.phone),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _addShopProduct,
          icon: const Icon(Icons.add_business),
          label: const Text('List Product'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
        ),
        const SizedBox(height: 16),
        const Text('Available Products:', style: TextStyle(fontWeight: FontWeight.bold)),
        Expanded(
          child: ListView.builder(
            itemCount: shopProducts.length,
            itemBuilder: (context, index) {
              final prod = shopProducts[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.shopping_bag, color: Colors.teal),
                  title: Text('${prod['product']}'),
                  subtitle: Text('${prod['desc']} (by ${prod['owner']})'),
                  trailing: ElevatedButton.icon(
                    icon: const Icon(Icons.call),
                    label: const Text('Contact'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                    onPressed: () {
                      // TODO: Integrate call
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

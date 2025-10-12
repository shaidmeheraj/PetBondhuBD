import 'package:flutter/material.dart';

class PetProfileTab extends StatefulWidget {
  const PetProfileTab({super.key});

  @override
  State<PetProfileTab> createState() => _PetProfileTabState();
}

class _PetProfileTabState extends State<PetProfileTab> {
  final List<Map<String, dynamic>> pets = [
    {
      'name': 'Bella',
      'age': 2,
      'breed': 'Golden Retriever',
      'image': 'https://images.unsplash.com/photo-1558788353-f76d92427f16',
    },
    {
      'name': 'Tommy',
      'age': 4,
      'breed': 'Persian Cat',
      'image': 'https://images.unsplash.com/photo-1518717758536-85ae29035b6d',
    },
  ];

  void _addPet() {
    // Demo: Add a new pet (static)
    setState(() {
      pets.add({
        'name': 'New Pet',
        'age': 1,
        'breed': 'Unknown',
        'image': 'https://images.unsplash.com/photo-1518717758536-85ae29035b6d',
      });
    });
  }

  void _openPetDetails(Map<String, dynamic> pet) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PetDetailsPage(pet: pet),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _addPet,
        backgroundColor: Colors.deepPurple,
        tooltip: 'Add New Pet',
        child: const Icon(Icons.add),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: pets.length,
        itemBuilder: (context, index) {
          final pet = pets[index];
          return GestureDetector(
            onTap: () => _openPetDetails(pet),
            child: Card(
              elevation: 5,
              margin: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(pet['image']),
                  radius: 28,
                ),
                title: Text(pet['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Age: ${pet['age']} | Breed: ${pet['breed']}'),
                trailing: const Icon(Icons.arrow_forward_ios, color: Colors.deepPurple),
              ),
            ),
          );
        },
      ),
    );
  }
}

class PetDetailsPage extends StatefulWidget {
  final Map<String, dynamic> pet;
  const PetDetailsPage({super.key, required this.pet});

  @override
  State<PetDetailsPage> createState() => _PetDetailsPageState();
}

class _PetDetailsPageState extends State<PetDetailsPage> {
  late Map<String, dynamic> pet;
  late TextEditingController healthNotesCtrl;

  @override
  void initState() {
    super.initState();
    pet = widget.pet;
    healthNotesCtrl = TextEditingController(text: pet['healthNotes'] ?? '');
  }

  @override
  void dispose() {
    healthNotesCtrl.dispose();
    super.dispose();
  }

  void _editPetInfo() {
    showDialog(
      context: context,
      builder: (context) {
        TextEditingController nameCtrl = TextEditingController(text: pet['name']);
        TextEditingController ageCtrl = TextEditingController(text: pet['age'].toString());
        TextEditingController breedCtrl = TextEditingController(text: pet['breed']);
        TextEditingController healthCtrl = TextEditingController(text: pet['healthNotes'] ?? '');
        return AlertDialog(
          title: const Text('Edit Pet Info'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: ageCtrl,
                  decoration: const InputDecoration(labelText: 'Age'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: breedCtrl,
                  decoration: const InputDecoration(labelText: 'Breed'),
                ),
                TextField(
                  controller: healthCtrl,
                  decoration: const InputDecoration(labelText: 'Health Notes'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  pet['name'] = nameCtrl.text;
                  pet['age'] = int.tryParse(ageCtrl.text) ?? pet['age'];
                  pet['breed'] = breedCtrl.text;
                  pet['healthNotes'] = healthCtrl.text;
                  healthNotesCtrl.text = healthCtrl.text;
                });
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final vaccineInfo = pet['vaccines'] ?? ['Rabies', 'Parvo'];
    return Scaffold(
      appBar: AppBar(
        title: Text('${pet['name']} Details'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editPetInfo,
            tooltip: 'Edit Pet Info',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(pet['image']),
              radius: 60,
            ),
            const SizedBox(height: 24),
            Text(pet['name'], style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text('Age: ${pet['age']}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('Breed: ${pet['breed']}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Vaccine Info:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              children: vaccineInfo.map<Widget>((v) => Chip(label: Text(v))).toList(),
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Health Notes:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: healthNotesCtrl,
              readOnly: true,
              maxLines: 2,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'No health notes',
              ),
            ),
          ],
        ),
      ),
    );
  }
}


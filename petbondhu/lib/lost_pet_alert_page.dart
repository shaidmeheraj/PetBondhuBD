import 'package:flutter/material.dart';

class LostPetAlertPage extends StatefulWidget {
  const LostPetAlertPage({Key? key}) : super(key: key);

  @override
  State<LostPetAlertPage> createState() => _LostPetAlertPageState();
}

class _LostPetAlertPageState extends State<LostPetAlertPage> {
  final List<Map<String, dynamic>> lostPets = [];

  void _markPetAsLost() async {
    String name = '';
    String imageUrl = '';
    String contact = '';
    await showDialog(
      context: context,
      builder: (context) {
        TextEditingController nameCtrl = TextEditingController();
        TextEditingController imageCtrl = TextEditingController();
        TextEditingController contactCtrl = TextEditingController();
        return AlertDialog(
          title: const Text('Mark Pet as Lost'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Pet Name'),
                ),
                TextField(
                  controller: imageCtrl,
                  decoration: const InputDecoration(labelText: 'Image URL'),
                ),
                TextField(
                  controller: contactCtrl,
                  decoration: const InputDecoration(labelText: 'Contact Number'),
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (nameCtrl.text.isNotEmpty && contactCtrl.text.isNotEmpty) {
                  setState(() {
                    lostPets.add({
                      'name': nameCtrl.text,
                      'image': imageCtrl.text,
                      'contact': contactCtrl.text,
                    });
                  });
                  Navigator.pop(context);
                }
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lost Pet Alert'),
        backgroundColor: Colors.deepPurple,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _markPetAsLost,
        backgroundColor: Colors.deepPurple,
        tooltip: 'Mark Pet as Lost',
        child: const Icon(Icons.report_gmailerrorred),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: lostPets.isEmpty
            ? const Center(child: Text('No lost pets reported yet.'))
            : ListView.builder(
                itemCount: lostPets.length,
                itemBuilder: (context, index) {
                  final pet = lostPets[index];
                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      leading: pet['image'].isNotEmpty
                          ? CircleAvatar(backgroundImage: NetworkImage(pet['image']), radius: 28)
                          : const CircleAvatar(child: Icon(Icons.pets)),
                      title: Text(pet['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Contact: ${pet['contact']}'),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

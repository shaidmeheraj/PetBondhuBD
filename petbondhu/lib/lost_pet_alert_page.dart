import 'package:flutter/material.dart';

class LostPetAlertPage extends StatefulWidget {
  const LostPetAlertPage({super.key});

  @override
  State<LostPetAlertPage> createState() => _LostPetAlertPageState();
}

class _LostPetAlertPageState extends State<LostPetAlertPage> {
  final List<Map<String, dynamic>> lostPets = [];

  void _markPetAsLost() async {
  // Removed unused variables
    await showDialog(
      context: context,
      builder: (context) {
        TextEditingController nameCtrl = TextEditingController();
        TextEditingController imageCtrl = TextEditingController();
        TextEditingController contactCtrl = TextEditingController();
        TextEditingController lastSeenCtrl = TextEditingController();
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
                TextField(
                  controller: lastSeenCtrl,
                  decoration: const InputDecoration(labelText: 'Last Seen Location'),
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
                      'lastSeen': lastSeenCtrl.text,
                      'found': false,
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
                  if (pet['found'] == true) {
                    return SizedBox.shrink(); // Hide found pets
                  }
                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          leading: pet['image'].isNotEmpty
                              ? CircleAvatar(backgroundImage: NetworkImage(pet['image']), radius: 28)
                              : const CircleAvatar(child: Icon(Icons.pets)),
                          title: Text(pet['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (pet['lastSeen'] != null && pet['lastSeen'].toString().isNotEmpty)
                                Text('Last Seen: ${pet['lastSeen']}'),
                              Text('Contact: ${pet['contact']}'),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.check_circle_outline),
                              label: const Text('Report Found'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                              onPressed: () {
                                setState(() {
                                  lostPets[index]['found'] = true;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Thank you for reporting ${pet['name']} as found!')),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class PetTipsTab extends StatelessWidget {
  const PetTipsTab({Key? key}) : super(key: key);

  final List<Map<String, dynamic>> tips = const [
    {
      'category': 'Nutrition 🍖',
      'tip': "Dogs should not eat chocolate – it's toxic.",
    },
    {
      'category': 'Nutrition 🍖',
      'tip': "Cats need taurine in their diet for heart health.",
    },
    {
      'category': 'Grooming ✂️',
      'tip': "Brush your pet regularly to reduce shedding.",
    },
    {
      'category': 'Grooming ✂️',
      'tip': "Trim nails every 3-4 weeks to prevent injury.",
    },
    {
      'category': 'Emergency 🚑',
      'tip': "Keep emergency vet contacts handy.",
    },
    {
      'category': 'Emergency 🚑',
      'tip': "Know basic pet CPR for emergencies.",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView.builder(
          itemCount: tips.length,
          itemBuilder: (context, index) {
            final tip = tips[index];
            return Card(
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: Text(tip['category'], style: const TextStyle(fontSize: 18)),
                title: Text(tip['tip'], style: const TextStyle(fontSize: 16)),
              ),
            );
          },
        ),
      ),
    );
  }
}

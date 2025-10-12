import 'package:flutter/material.dart';

class PetDescriptionScreen extends StatelessWidget {
  const PetDescriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Pet Description")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("🐾 Name: Tommy", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text("Breed: German Shepherd", style: TextStyle(fontSize: 16)),
            Text("Age: 1 year", style: TextStyle(fontSize: 16)),
            Text("Vaccinated: Yes", style: TextStyle(fontSize: 16)),
            SizedBox(height: 20),
            Text(
              "Description:\nTommy is a playful and intelligent dog, perfect for families. He loves walks and is trained.",
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

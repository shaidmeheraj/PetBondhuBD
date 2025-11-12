import 'package:flutter/material.dart';

class ChatBotPage extends StatelessWidget {
  const ChatBotPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Chatbot"), backgroundColor: Colors.deepPurple),
      body: const Center(
        child: Text("Chatbot feature coming soon 🤖", style: TextStyle(fontSize: 20)),
      ),
    );
  }
}

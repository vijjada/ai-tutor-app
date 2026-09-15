import 'package:flutter/material.dart';
import 'chat/chat_screen.dart';

class HomeShellScreen extends StatelessWidget {
  const HomeShellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Tutor')),
body: Center(
child: GestureDetector(
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ChatScreen()),
    );
  },
child: Icon(Icons.person, size: 120, color: Colors.deepPurple),
),
      ),
    );
  }
}

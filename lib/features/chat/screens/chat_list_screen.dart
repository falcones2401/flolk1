import 'package:flutter/material.dart';
import '../../search/screens/search_user_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flolk Chat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchUserScreen()),
              );
            },
          ),
        ],
      ),
      body: const Center(
        child: Text('Nessuna chat attiva. Usa la lente in alto per cercare un utente!'),
      ),
    );
  }
}
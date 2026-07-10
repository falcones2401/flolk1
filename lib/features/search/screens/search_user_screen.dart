import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../chat/screens/single_chat_screen.dart';

class SearchUserScreen extends StatefulWidget {
  const SearchUserScreen({Key? key}) : super(key: key);

  @override
  State<SearchUserScreen> createState() => _SearchUserScreenState();
}

class _SearchUserScreenState extends State<SearchUserScreen> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  void _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Cerchiamo su Firestore gli utenti il cui username inizia o contiene il testo digitato
      final lowercaseQuery = query.toLowerCase().trim();
      
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isGreaterThanOrEqualTo: lowercaseQuery)
          .where('username', isLessThanOrEqualTo: '$lowercaseQuery\uf8ff')
          .get();

      setState(() {
        _searchResults = querySnapshot.docs
            .map((doc) => doc.data())
            // Escludiamo noi stessi dai risultati della ricerca
            .where((userData) => userData['uid'] != _currentUserId)
            .toList();
      });
    } catch (e) {
      print("Errore durante la ricerca: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cerca Utenti'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Barra di ricerca stile Flolk
            TextField(
              controller: _searchController,
              onChanged: _searchUsers,
              decoration: InputDecoration(
                hintText: 'Inserisci l\'username...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF6C63FF)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _searchUsers('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFF6C63FF)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Lista dei risultati reali da Firebase
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)))
                  : _searchResults.isEmpty
                      ? const Center(
                          child: Text(
                            'Nessun utente trovato.\nCerca un username per iniziare a chattare!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final userData = _searchResults[index];
                            final username = userData['username'] as String;

                            return Card(
                              color: const Color(0xFF1E1E1E),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: const Color(0xFF6C63FF),
                                  child: Text(
                                    username[0].toUpperCase(), 
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                                  ),
                                ),
                                title: Text(username, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: const Text('Tocca per aprire la conversazione'),
                                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                                onTap: () {
                                  // MODIFICATO: Ora passiamo sia l'username che l'UID reale a SingleChatScreen
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SingleChatScreen(
                                        targetUsername: username,
                                        targetUid: userData['uid'] as String,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
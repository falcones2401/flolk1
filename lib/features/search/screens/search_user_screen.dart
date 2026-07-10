import 'package:flutter/material.dart';
import '../../chat/screens/single_chat_screen.dart';

class SearchUserScreen extends StatefulWidget {
  const SearchUserScreen({Key? key}) : super(key: key);

  @override
  State<SearchUserScreen> createState() => _SearchUserScreenState();
}

class _SearchUserScreenState extends State<SearchUserScreen> {
  final _searchController = TextEditingController();
  List<String> _searchResults = [];
  bool _isLoading = false;

  void _searchUsers(String query) {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isLoading = true);

    // TODO: Qui inseriremo la chiamata al Database (es. Supabase) per cercare l'username reale
    // Per ora simuliamo una ricerca locale con utenti fittizi per testare il design
    Future.delayed(const Duration(milliseconds: 500), () {
      final mockUsers = ['mario_rossi', 'luca_verdi', 'giulia_bianchi', 'stefano_99', 'falcones_fan'];
      
      setState(() {
        _searchResults = mockUsers
            .where((user) => user.toLowerCase().contains(query.toLowerCase()))
            .toList();
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
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
            // Barra di ricerca con lo stile di Flolk
            TextField(
              controller: _searchController,
              onChanged: _searchUsers,
              decoration: InputDecoration(
                hintText: 'Inserisci l\'username esatto...',
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
            
            // Lista dei risultati
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)))
                  : _searchResults.isEmpty
                      ? const Center(
                          child: Text(
                            'Cerca un username per iniziare a chattare.\nLa chat si attiverà al primo messaggio!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final username = _searchResults[index];
                            return Card(
                              color: const Color(0xFF1E1E1E),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: const Color(0xFF6C63FF),
                                  child: Text(username[0].toUpperCase(), style: const TextStyle(color: Colors.white)),
                                ),
                                title: Text(username, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: const Text('Tocca per aprire la conversazione'),
                                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                                onTap: () {
                                  // Logica: Passiamo alla chat singola passando l'username cercato.
                                  // La stanza viene creata localmente, sul server nascerà solo quando uno dei due scrive.
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SingleChatScreen(targetUsername: username),
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
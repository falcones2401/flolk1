import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/network/chat_service.dart';
import 'group_chat_screen.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({Key? key}) : super(key: key);

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _groupNameController = TextEditingController();
  final ChatService _chatService = ChatService();
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  List<Map<String, dynamic>> _allUsers = [];
  final List<String> _selectedUserUids = [];
  final List<String> _selectedUsernames = [];
  bool _isLoading = true;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  // Carica tutti gli utenti disponibili su Flolk per poterli invitare
  void _loadUsers() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('users').get();
      setState(() {
        _allUsers = snapshot.docs
            .map((doc) => doc.data())
            .where((userData) => userData['uid'] != _currentUserId) // Esclude se stessi
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      print("Errore caricamento utenti gruppo: $e");
      setState(() => _isLoading = false);
    }
  }

  void _toggleUserSelection(String uid, String username) {
    setState(() {
      if (_selectedUserUids.contains(uid)) {
        _selectedUserUids.remove(uid);
        _selectedUsernames.remove(username);
      } else {
        _selectedUserUids.add(uid);
        _selectedUsernames.add(username);
      }
    });
  }

  void _handleCreateGroup() async {
    final groupName = _groupNameController.text.trim();
    if (groupName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Inserisci un nome per il gruppo")),
      );
      return;
    }

    if (_selectedUserUids.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Seleziona almeno un partecipante")),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      // Chiave fissa temporanea per i test del gruppo
      const String groupSecretKey = "flolk1_group_super_secret_key_32b";

      // 1. Crea il gruppo su Firebase
      final String newGroupId = await _chatService.createGroupChat(
        groupName: groupName,
        memberUids: _selectedUserUids,
        groupSecretKey: groupSecretKey,
      );

      if (mounted) {
        // 2. Apri direttamente la schermata del gruppo appena creato passandogli i dati reali
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => GroupChatScreen(
              groupId: newGroupId,
              groupName: groupName,
              members: _selectedUsernames,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Errore creazione gruppo: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuovo Gruppo Sicuro'),
        backgroundColor: const Color(0xFF1E1E1E),
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _isCreating ? null : _handleCreateGroup,
              child: _isCreating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('CREA', style: TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Input Nome Gruppo
                  TextField(
                    controller: _groupNameController,
                    decoration: InputDecoration(
                      labelText: 'Nome del Gruppo',
                      prefixIcon: const Icon(Icons.group_add, color: Color(0xFF6C63FF)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Seleziona i partecipanti (${_selectedUserUids.length} selezionati):',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  
                  // Lista degli utenti con Checkbox
                  Expanded(
                    child: _allUsers.isEmpty
                        ? const Center(child: Text('Nessun altro utente registrato su Flolk.'))
                        : ListView.builder(
                            itemCount: _allUsers.length,
                            itemBuilder: (context, index) {
                              final userData = _allUsers[index];
                              final uid = userData['uid'] as String;
                              final username = userData['username'] as String;
                              final isSelected = _selectedUserUids.contains(uid);

                              return Card(
                                color: const Color(0xFF1E1E1E),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                child: CheckboxListTile(
                                  activeColor: const Color(0xFF6C63FF),
                                  checkColor: Colors.white,
                                  title: Text(username, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  value: isSelected,
                                  secondary: CircleAvatar(
                                    backgroundColor: isSelected ? const Color(0xFF6C63FF) : const Color(0xFF2C2C2C),
                                    child: Text(
                                      username[0].toUpperCase(),
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  onChanged: (_) => _toggleUserSelection(uid, username),
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
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../search/screens/search_user_screen.dart';
import '../../auth/screens/login_screen.dart';
import '../../../core/encryption/crypto_service.dart';
import '../../../core/network/chat_service.dart';
import 'single_chat_screen.dart';
import 'group_chat_screen.dart';
import 'create_group_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final ChatService _chatService = ChatService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2, // 2 Tab: Chat Singole e Gruppi
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Flolk Chat', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF1E1E1E),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                }
              },
            ),
          ],
          bottom: const TabBar(
            indicatorColor: Color(0xFF6C63FF),
            labelColor: Color(0xFF6C63FF),
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(icon: Icon(Icons.person), text: "Chat"),
              Tab(icon: Icon(Icons.group), text: "Gruppi"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // --- TAB 1: CHAT SINGOLE ---
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chat_rooms')
                  .where('participants', arrayContains: _currentUserId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Nessuna chat attiva. Tocca + per iniziare.'));
                }

                final rooms = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: rooms.length,
                  itemBuilder: (context, index) {
                    final roomData = rooms[index].data() as Map<String, dynamic>;
                    final participants = List<String>.from(roomData['participants'] ?? []);
                    final targetUid = participants.firstWhere((id) => id != _currentUserId, orElse: () => '');

                    if (targetUid.isEmpty) return const SizedBox();

                    final encryptedLastMsg = roomData['lastMessage'] as String? ?? '';
                    // Decifratura DINAMICA dell'anteprima
                    final chatKey = _chatService.getChatKey(targetUid);
                    final decryptedLastMsg = encryptedLastMsg.isNotEmpty
                        ? CryptoService.decryptMessage(encryptedLastMsg, chatKey)
                        : 'Nessun messaggio';

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('users').doc(targetUid).get(),
                      builder: (context, userSnapshot) {
                        if (!userSnapshot.hasData) return const SizedBox(height: 70);
                        final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                        final targetUsername = userData?['username'] as String? ?? 'Utente';

                        return Card(
                          color: const Color(0xFF1E1E1E),
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: theme.colorScheme.primary,
                              child: Text(targetUsername[0].toUpperCase(), style: const TextStyle(color: Colors.white)),
                            ),
                            title: Text(targetUsername, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(decryptedLastMsg, maxLines: 1, overflow: TextOverflow.ellipsis),
                            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SingleChatScreen(
                                    targetUsername: targetUsername,
                                    targetUid: targetUid,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),

            // --- TAB 2: CHAT DI GRUPPO ---
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('group_rooms')
                  .where('participants', arrayContains: _currentUserId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Nessun gruppo attivo. Crea il tuo primo gruppo!'));
                }

                final groupRooms = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: groupRooms.length,
                  itemBuilder: (context, index) {
                    final groupData = groupRooms[index].data() as Map<String, dynamic>;
                    final groupId = groupData['groupId'] as String;
                    final groupName = groupData['groupName'] as String;
                    final participants = List<String>.from(groupData['participants'] ?? []);

                    final encryptedLastMsg = groupData['lastMessage'] as String? ?? '';
                    // Decifratura DINAMICA dell'anteprima del gruppo
                    final groupKey = _chatService.getGroupKey(groupId);
                    final decryptedLastMsg = encryptedLastMsg.isNotEmpty
                        ? CryptoService.decryptMessage(encryptedLastMsg, groupKey)
                        : 'Nessun messaggio';

                    return Card(
                      color: const Color(0xFF1E1E1E),
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.secondary,
                          child: Text(groupName[0].toUpperCase(), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                        ),
                        title: Text(groupName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(decryptedLastMsg, maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                        onTap: () {
                          // Estraiamo i nomi visualizzabili (placeholder o uids per semplicità di caricamento immediato)
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GroupChatScreen(
                                groupId: groupId,
                                groupName: groupName,
                                members: participants, 
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
        // Menu fluttuante per decidere se cercare utente o creare gruppo
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton.small(
              heroTag: 'btnGroup',
              backgroundColor: theme.colorScheme.secondary,
              child: const Icon(Icons.group_add, color: Colors.black),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CreateGroupScreen()),
                );
              },
            ),
            const SizedBox(height: 12),
            FloatingActionButton(
              heroTag: 'btnUser',
              backgroundColor: theme.colorScheme.primary,
              child: const Icon(Icons.message, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SearchUserScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
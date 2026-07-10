import 'package:flutter/material.dart';
import '../../../core/network/chat_service.dart';

class GroupChatScreen extends StatefulWidget {
  final String groupId;
  final String groupName;
  final List<String> members;

  const GroupChatScreen({
    Key? key,
    required this.groupId,
    required this.groupName,
    required this.members,
  }) : super(key: key);

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final _messageController = TextEditingController();
  final ChatService _chatService = ChatService();

  void _sendGroupMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    try {
      // Modificato: rimosso parametro chiave fissa
      await _chatService.sendGroupSecureMessage(
        groupId: widget.groupId,
        plainText: text,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Errore gruppo: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.groupName, style: const TextStyle(fontSize: 18)),
            Text(
              '${widget.members.length} partecipanti',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E1E1E),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: const Color(0xFF1E1E1E),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (context) {
                  return Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Membri del Gruppo', style: theme.textTheme.headlineMedium),
                        const SizedBox(height: 16),
                        const ListTile(
                          leading: CircleAvatar(backgroundColor: Color(0xFF6C63FF), child: Text('TU')),
                          title: Text('Tu (Amministratore)'),
                        ),
                        ...widget.members.map((member) => ListTile(
                          leading: CircleAvatar(
                            backgroundColor: theme.colorScheme.secondary,
                            child: Text(member[0].toUpperCase(), style: const TextStyle(color: Colors.black)),
                          ),
                          title: Text(member),
                        )).toList(),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              // Modificato: rimosso parametro chiave fissa
              stream: _chatService.getGroupSecureMessages(
                groupId: widget.groupId,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)));
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      'Inizio della chat di gruppo protetta.\nTutti i messaggi sono crittografati end-to-end.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                final messages = snapshot.data!;

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg['isMe'] as bool;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe ? theme.colorScheme.primary : const Color(0xFF2C2C2C),
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: Radius.circular(isMe ? 16 : 0),
                            bottomRight: Radius.circular(isMe ? 0 : 16),
                          ),
                        ),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isMe)
                              Text(
                                msg['senderName'] ?? 'Membro',
                                style: TextStyle(
                                  color: theme.colorScheme.secondary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            if (!isMe) const SizedBox(height: 4),
                            Text(
                              msg['text'] ?? '',
                              style: const TextStyle(color: Colors.white, fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.only(left: 12, right: 12, bottom: 20, top: 8),
            color: const Color(0xFF121212),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Scrivi nel gruppo sicuro...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      fillColor: const Color(0xFF1E1E1E),
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _sendGroupMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primary,
                  radius: 22,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: _sendGroupMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
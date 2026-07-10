import 'package:flutter/material.dart';
import '../../../core/network/chat_service.dart';

class SingleChatScreen extends StatefulWidget {
  final String targetUsername;
  final String targetUid;

  const SingleChatScreen({
    Key? key, 
    required this.targetUsername,
    required this.targetUid,
  }) : super(key: key);

  @override
  State<SingleChatScreen> createState() => _SingleChatScreenState();
}

class _SingleChatScreenState extends State<SingleChatScreen> {
  final _messageController = TextEditingController();
  final ChatService _chatService = ChatService();

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    try {
      // Modificato: non passiamo più la chiave statica, fa tutto il ChatService internamente
      await _chatService.sendSecureMessage(
        targetUid: widget.targetUid,
        plainText: text,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Errore d'invio: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: theme.colorScheme.secondary,
              radius: 18,
              child: Text(
                widget.targetUsername[0].toUpperCase(),
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Text(widget.targetUsername, style: const TextStyle(fontSize: 18)),
          ],
        ),
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 1,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              // Modificato: rimosso il parametro della chiave statica
              stream: _chatService.getSecureMessages(
                targetUid: widget.targetUid,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)));
                }
                
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        'Questa chat è cifrata end-to-end.\nInvia un messaggio per iniziare la conversazione sicura con ${widget.targetUsername}.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
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
                        child: Text(
                          msg['text'] ?? '',
                          style: const TextStyle(color: Colors.white, fontSize: 15),
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
                      hintText: 'Scrivi un messaggio sicuro...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      fillColor: const Color(0xFF1E1E1E),
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primary,
                  radius: 22,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: _sendMessage,
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
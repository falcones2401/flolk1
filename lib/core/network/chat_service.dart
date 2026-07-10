import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'dart:crypto'; // Fornisce la generazione di stringhe casuali se necessario, o usiamo un hash generato
import '../encryption/crypto_service.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  /// Genera un ID univoco e standardizzato per la stanza unendo i due UID
  String _getChatRoomId(String uid1, String uid2) {
    return uid1.hashCode <= uid2.hashCode ? '${uid1}_$uid2' : '${uid2}_$uid1';
  }

  /// Genera una chiave simmetrica dinamica a 32 caratteri basandosi sugli ID dei partecipanti
  String _generateDynamicKey(String seed1, String seed2) {
    final bytes = utf8.encode('${seed1}_${seed2}_flolk_salt_2026');
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 32); // Estrae esattamente 32 byte stabili per AES
  }

  /// Invia un messaggio crittografato su Firestore con chiave dinamica
  Future<void> sendSecureMessage({
    required String targetUid,
    required String plainText,
  }) async {
    if (plainText.trim().isEmpty) return;

    final String roomId = _getChatRoomId(_currentUserId, targetUid);
    // Genera la chiave in modo dinamico per questa specifica coppia di utenti
    final String chatSecretKey = _generateDynamicKey(_currentUserId, targetUid);

    // 1. Crittografia del testo del messaggio
    final String encryptedText = CryptoService.encryptMessage(plainText, chatSecretKey);

    final messageData = {
      'senderId': _currentUserId,
      'receiverId': targetUid,
      'text': encryptedText,
      'timestamp': FieldValue.serverTimestamp(),
    };

    // 2. Aggiorna i dettagli della stanza
    await _firestore.collection('chat_rooms').doc(roomId).set({
      'participants': [_currentUserId, targetUid],
      'lastMessage': encryptedText,
      'lastMessageTimestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // 3. Salva il messaggio nella sotto-collezione interna
    await _firestore
        .collection('chat_rooms')
        .doc(roomId)
        .collection('messages')
        .add(messageData);
  }

  /// Recupera lo stream di messaggi in tempo reale e li decifra con chiave dinamica
  Stream<List<Map<String, dynamic>>> getSecureMessages({
    required String targetUid,
  }) {
    final String roomId = _getChatRoomId(_currentUserId, targetUid);
    final String chatSecretKey = _generateDynamicKey(_currentUserId, targetUid);

    return _firestore
        .collection('chat_rooms')
        .doc(roomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            final encryptedText = data['text'] as String;

            try {
              data['text'] = CryptoService.decryptMessage(encryptedText, chatSecretKey);
            } catch (e) {
              data['text'] = "[Errore di decrittazione]";
            }
            data['isMe'] = data['senderId'] == _currentUserId;
            
            return data;
          }).toList();
        });
  }

  /// Crea una nuova stanza di gruppo su Firestore generando una chiave dinamica
  Future<String> createGroupChat({
    required String groupName,
    required List<String> memberUids,
  }) async {
    if (!memberUids.contains(_currentUserId)) {
      memberUids.add(_currentUserId);
    }

    final groupDoc = _firestore.collection('group_rooms').doc();
    // Genera la chiave del gruppo basandosi sull'ID univoco del documento appena creato
    final String groupSecretKey = _generateDynamicKey(groupDoc.id, groupName);
    
    await groupDoc.set({
      'groupId': groupDoc.id,
      'groupName': groupName,
      'participants': memberUids,
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessage': CryptoService.encryptMessage('Gruppo creato', groupSecretKey),
      'lastMessageTimestamp': FieldValue.serverTimestamp(),
    });

    return groupDoc.id;
  }

  /// Invia un messaggio crittografato all'interno di un gruppo con chiave dinamica
  Future<void> sendGroupSecureMessage({
    required String groupId,
    required String plainText,
  }) async {
    if (plainText.trim().isEmpty) return;

    // Recupera la chiave derivata in base all'ID di questo specifico gruppo
    final String groupSecretKey = _generateDynamicKey(groupId, "GroupNamePlaceholder");
    final String encryptedText = CryptoService.encryptMessage(plainText, groupSecretKey);

    final messageData = {
      'senderId': _currentUserId,
      'senderName': FirebaseAuth.instance.currentUser?.email?.split('@')[0] ?? 'Membro',
      'text': encryptedText,
      'timestamp': FieldValue.serverTimestamp(),
    };

    await _firestore.collection('group_rooms').doc(groupId).update({
      'lastMessage': encryptedText,
      'lastMessageTimestamp': FieldValue.serverTimestamp(),
    });

    await _firestore
        .collection('group_rooms')
        .doc(groupId)
        .collection('messages')
        .add(messageData);
  }

  /// Recupera i messaggi del gruppo in tempo reale e li decifra con chiave dinamica
  Stream<List<Map<String, dynamic>>> getGroupSecureMessages({
    required String groupId,
  }) {
    final String groupSecretKey = _generateDynamicKey(groupId, "GroupNamePlaceholder");

    return _firestore
        .collection('group_rooms')
        .doc(groupId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            final encryptedText = data['text'] as String;

            try {
              data['text'] = CryptoService.decryptMessage(encryptedText, groupSecretKey);
            } catch (e) {
              data['text'] = "[Errore di decrittazione]";
            }
            data['isMe'] = data['senderId'] == _currentUserId;
            
            return data;
          }).toList();
        });
  }

  /// Espone la funzione di calcolo chiave esternamente per le anteprime delle liste chat
  String getChatKey(String targetUid) => _generateDynamicKey(_currentUserId, targetUid);
  String getGroupKey(String groupId) => _generateDynamicKey(groupId, "GroupNamePlaceholder");
}
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Registrazione con Username, Email e Password
  Future<User?> signUpWithEmailAndPassword({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      // 1. Controlla prima se l'username è già stato preso da qualcun altro
      final usernameCheck = await _firestore
          .collection('users')
          .where('username', isEqualTo: username.toLowerCase().trim())
          .get();

      if (usernameCheck.docs.isNotEmpty) {
        throw Exception("Questo username è già in uso. Scegline un altro.");
      }

      // 2. Crea l'utente su Firebase Authentication
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      User? user = result.user;

      // 3. Salva l'utente sul database Firestore con il suo username univoco
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'username': username.toLowerCase().trim(),
          'email': email.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      return user;
    } catch (e) {
      print("Errore durante la registrazione: $e");
      rethrow;
    }
  }

  // Login con Email e Password
  Future<User?> loginWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return result.user;
    } catch (e) {
      print("Errore durante il login: $e");
      rethrow;
    }
  }

  // Logout
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
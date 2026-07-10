import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/network/auth_service.dart';
import 'signup_screen.dart';
import '../../chat/screens/chat_list_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identityController = TextEditingController(); // Può essere username o email
  final _passwordController = TextEditingController();
  
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      String input = _identityController.text.trim();
      String email = input;

      try {
        // Se l'input non contiene la '@', assumiamo che sia un username
        if (!input.contains('@')) {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .where('username', isEqualTo: input.toLowerCase())
              .get();

          if (userDoc.docs.isEmpty) {
            throw Exception("Username non trovato.");
          }
          // Recuperiamo l'email reale collegata a questo username
          email = userDoc.docs.first.data()['email'];
        }

        // Effettuiamo il login con l'email trovata
        final user = await _authService.loginWithEmailAndPassword(email, _passwordController.text);

        if (user != null && mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ChatListScreen()),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Bentornato su Flolk',
                  style: theme.textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Accedi per visualizzare le tue chat crittografate',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _identityController,
                  decoration: InputDecoration(
                    labelText: 'Username o Email',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) => value!.isEmpty ? 'Inserisci il tuo username o email' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) => value!.isEmpty ? 'Inserisci la password' : null,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Accedi', style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SignupScreen()),
                    );
                  },
                  child: const Text('Non hai un account? Registrati'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/chat/screens/chat_list_screen.dart';

void main() async {
  // Assicura che i binding di Flutter siano pronti prima di inizializzare Firebase
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inizializza Firebase nativamente su Android/iOS
  await Firebase.initializeApp();
  
  runApp(const FlolkApp());
}

class FlolkApp extends StatelessWidget {
  const FlolkApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flolk',
      debugShowCheckedModeBanner: false,
      
      // Definiamo il tema scuro personalizzato dell'app (Stile Flolk)
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212), // Sfondo scuro profondo
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6C63FF),       // Viola Flolk per bottoni e messaggi inviati
          secondary: Color(0xFF00E676),     // Verde Flolk per accenti e avatar
          surface: Color(0xFF1E1E1E),       // Grigio scuro per le schede (Card)
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontSize: 24, 
            fontWeight: FontWeight.bold, 
            color: Colors.white,
          ),
        ),
      ),
      
      // Controllo dello stato dell'utente: se è già loggato va alla lista chat, altrimenti al login
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Se Firebase sta ancora controllando lo stato di login, mostra un caricamento
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF))),
            );
          }
          
          // Se c'è un utente autenticato, entra nell'app, altrimenti mostra la schermata di Login
          if (snapshot.hasData && snapshot.data != null) {
            return const ChatListScreen();
          }
          
          return const LoginScreen();
        },
      ),
    );
  }
}
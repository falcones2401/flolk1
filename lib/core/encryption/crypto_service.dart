import 'dart:convert';
import 'dart:math';

class CryptoService {
  // Genera una chiave simmetrica casuale per le chat di gruppo o singole
  static String generateSymmetricKey() {
    final random = Random.secure();
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Url.encode(values);
  }

  /// Cifra un messaggio di testo usando una chiave segreta
  /// Questo testo cifrato è quello che viaggerà nel database.
  static String encryptMessage(String plainText, String key) {
    if (plainText.isEmpty) return '';
    
    // Convertiamo il testo in byte
    final bytes = utf8.encode(plainText);
    
    // Simulazione dell'algoritmo di cifratura (AES) in puro Dart senza dipendenze esterne per ora
    // Sposta i byte in base alla chiave per rendere il testo illeggibile
    final keyHash = key.hashCode;
    final encryptedBytes = bytes.map((byte) => byte ^ (keyHash & 0xFF)).toList();
    
    // Restituisce una stringa apparentemente casuale (es. "aGabb2819==")
    return base64.encode(encryptedBytes);
  }

  /// Decifra un messaggio ricevuto che era stato precedentemente crittografato
  static String decryptMessage(String encryptedText, String key) {
    try {
      if (encryptedText.isEmpty) return '';
      
      // Decodifichiamo dalla stringa base64 ai byte cifrati
      final encryptedBytes = base64.decode(encryptedText);
      
      // Invertiamo l'operazione di cifratura usando la stessa chiave
      final keyHash = key.hashCode;
      final decryptedBytes = encryptedBytes.map((byte) => byte ^ (keyHash & 0xFF)).toList();
      
      return utf8.decode(decryptedBytes);
    } catch (e) {
      return "[Errore di decifratura: Chiave non valida o messaggio corrotto]";
    }
  }
}
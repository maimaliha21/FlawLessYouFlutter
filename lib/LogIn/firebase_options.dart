// lib/firebase_options.dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return const FirebaseOptions(
        apiKey: "AIzaSyB4c0Fng6e_0eYj-fsTARN32LXbq5XrAL8",
        authDomain: "flawlessyou.firebaseapp.com",
        projectId: "flawlessyou",
        storageBucket: "flawlessyou.firebasestorage.app",
        messagingSenderId: "631393157394",
        appId: "1:631393157394:web:2ba5b8b300fa6c3a5b33cb",
        measurementId: "G-8PDB3KEJ3S"
    );
  }
}
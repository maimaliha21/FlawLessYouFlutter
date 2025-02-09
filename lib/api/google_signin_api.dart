

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleSignInApi {
  static final _googleSignIn = GoogleSignIn(
    clientId: "631393157394-3u002d405h0m3psm44vmaakn13oerqm4.apps.googleusercontent.com",
    scopes: ['email', 'profile'],
  );

  static final _firebaseAuth = FirebaseAuth.instance;

  static Future<String?> login() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null; // تم إلغاء تسجيل الدخول
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      return userCredential.user?.uid; // إرجاع uid الخاص بالمستخدم بعد التسجيل الناجح
    } catch (e) {
      print("Error during Google Sign-In: $e");
      return null;
    }
  }
}

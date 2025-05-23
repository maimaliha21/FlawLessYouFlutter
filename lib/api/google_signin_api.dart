import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
// import 'package:google_sign_in_web/google_sign_in_web.dart' as web;

class GoogleSignInApi {
  static final _googleSignIn = GoogleSignIn(
    clientId: "631393157394-glrev6a2q6oiquvv15a24minn0j93t51.apps.googleusercontent.com",
    scopes: ['email', 'profile'],
    signInOption: SignInOption.standard,
  );

  static final _firebaseAuth = FirebaseAuth.instance;

  static Future<String?> login() async {
    try {
      // استخدام الأسلوب الحديث بدلاً من signIn المهمل
      final googleUser = await _googleSignIn.signInSilently() ?? await _googleSignIn.signIn();

      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      print('ID Token: ${googleAuth.idToken}');

      if (googleAuth.idToken == null) {
        print('Google Sign-In succeeded but no ID token');
        return null;
      }

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      await _firebaseAuth.signInWithCredential(credential);
      return googleAuth.idToken;
    } catch (e) {
      print('Google Sign-In Error: $e');
      return null;
    }
  }

  static Future<void> signOut() async {
    try {
      await Future.wait([
        _firebaseAuth.signOut(),
        _googleSignIn.signOut(),
      ]);
      print('Successfully signed out');
    } catch (e) {
      print('Error signing out: $e');
    }
  }
}
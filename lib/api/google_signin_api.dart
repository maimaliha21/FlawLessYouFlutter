import 'package:google_sign_in/google_sign_in.dart';

class GoogleSignInApi {
  static final _googleSignIn = GoogleSignIn(
    clientId: "631393157394-vocg3facesl3ur7mgnokqd11vjhiupql.apps.googleusercontent.com",
     scopes: ['email', 'profile'],
  );

  static Future<String?> login() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null; // تم إلغاء تسجيل الدخول
      }

      final googleAuth = await googleUser.authentication;
      return googleAuth.idToken; // إرجاع idToken
    } catch (e) {
      print("Error during Google Sign-In: $e");
      return null;
    }
  }
}

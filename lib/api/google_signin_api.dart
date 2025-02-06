import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';

class GoogleSignInApi {
  static final _googleSignIn = GoogleSignIn();

  static Future<void> login(BuildContext context) async {
    final user = await _googleSignIn.signIn();
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google Sign-In canceled or failed')),
      );
    } else {
      print("Google Sign-In successful: ${user.displayName}, ${user.email}");

      // أضف هنا منطق التعامل مع Google Sign-In Token إذا كان مطلوبًا
    }
  }
}

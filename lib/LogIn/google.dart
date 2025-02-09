import 'package:flutter/material.dart';
import 'auth_service.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Google OAuth2 Login')),
        body: Center(
          child: AuthButton(),
        ),
      ),
    );
  }
}

class AuthButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: Icon(Icons.login),
      label: Text('Sign in with Google'),
      onPressed: () async {
        final token = await AuthService.signInWithGoogle();
        if (token != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Logged in successfully!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Login failed!')),
          );
        }
      },
    );
  }
}
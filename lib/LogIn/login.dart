import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:FlawlessYou/ProfileSection/profile.dart';
import 'package:FlawlessYou/Verification_Account_SignUp/createprofilee.dart';
import 'package:FlawlessYou/api/google_signin_api.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../SharedPreferences.dart';
import '../SignUp/signUp.dart';
import 'firebase_options.dart';
import 'package:FlawlessYou/Admin/AdminProfileSectio/adminprofile.dart';
import 'package:FlawlessYou/Expert/ExpertChat/chatexpert.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login App',
      theme: ThemeData(
        primaryColor: Color(0xFF596D56),
      ),
      home: LoginScreen(),
    );
  }
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  // دالة لجلب معلومات المستخدم
  Future<Map<String, dynamic>?> fetchUserInfo(String token) async {
    try {
      final baseUrl = await getBaseUrl();
      print('Using baseUrl: $baseUrl');

      final response = await http.get(
        Uri.parse('$baseUrl/api/users/me'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final userInfo = jsonDecode(response.body);
        print('Fetched user info: $userInfo');
        await saveUserData(token, userInfo); // حفظ بيانات المستخدم
        return userInfo;
      } else {
        print('Failed to fetch user info: ${response.statusCode}');
        print('Error response: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error fetching user info: $e');
      return null;
    }
  }

  // دالة لتسجيل الدخول باستخدام اسم المستخدم وكلمة المرور
  Future<void> loginWithCredentials(
      BuildContext context, String username, String password) async {
    final baseUrl = await getBaseUrl();

    print('Using baseUrl for login: $baseUrl');

    final url = Uri.parse('$baseUrl/api/auth/signin');

    try {
      print('Attempting login for user: $username');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'username': username, 'password': password}),
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        final token = responseBody['accessToken'];
        print('Login successful, JWT Token received: $token');

        // جلب معلومات المستخدم
        final userInfo = await fetchUserInfo(token);

        if (userInfo != null) {
          if (userInfo['role'] == 'ADMIN') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => AdminProfile(),
              ),
            );

          }
          else if (userInfo['role'] == 'SKIN_EXPERT') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => Profile(
                  token: token,
                  userInfo: userInfo,
                ),
                ),
            );
          }


          else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => Profile(
                  token: token,
                  userInfo: userInfo,
                ),
              ),
            );
          }
        } else {
          throw Exception('Failed to fetch user information');
        }
      } else {
        final errorBody = jsonDecode(response.body);
        print('Login failed: ${response.statusCode}');
        print('Error body: $errorBody');
        throw Exception(errorBody['message'] ?? 'Invalid username or password');
      }
    } catch (e) {
      print('Error during login: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // دالة لتسجيل الدخول باستخدام Google
  Future<void> loginWithGoogle(BuildContext context) async {
    try {
      print('Starting Google Sign-In process');
      final idToken = await GoogleSignInApi.login();

      if (idToken == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to get Google ID token'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // جلب معلومات المستخدم من Google باستخدام التوكن
      final googleResponse = await http.post(
        Uri.parse('https://www.googleapis.com/oauth2/v3/tokeninfo?id_token=$idToken'),
      );

      if (googleResponse.statusCode == 200) {
        final googleUserInfo = jsonDecode(googleResponse.body);
        final email = googleUserInfo['email'];

        final baseUrl = await getBaseUrl();
        print('Using baseUrl for Google login: $baseUrl');

        // إرسال البريد الإلكتروني إلى الخادم
        final response = await http.post(
          Uri.parse('$baseUrl/api/auth/google'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email}),
        );

        print('Received email, authenticating with backend');

        if (response.statusCode == 200) {
          final responseBody = jsonDecode(response.body);
          final token = responseBody['accessToken'];
          print('Backend authentication successful');

          final userInfo = await fetchUserInfo(token);
          if (userInfo != null) {
            print('User info fetched successfully');
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => Profile(
                  token: token,
                  userInfo: userInfo,
                ),
              ),
            );
          } else {
            throw Exception('Failed to fetch user information');
          }
        } else {
          final errorBody = jsonDecode(response.body);
          throw Exception(errorBody['message'] ?? 'Failed to authenticate with server');
        }
      } else {
        throw Exception('Failed to fetch user info from Google');
      }
    } catch (e) {
      print('Error during Google authentication: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Authentication failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();

    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: () async {
          print('Refreshing data...');
          await fetchUserInfo('your_token_here');
        },
        child: Stack(
          children: [
            Positioned(
              top: -60,
              left: -60,
              child: CircleAvatar(
                radius: 100,
                backgroundColor: Colors.green.withOpacity(0.3), // تم التعديل هنا
              ),
            ),
            Positioned(
              top: 50,
              left: 50,
              child: CircleAvatar(
                radius: 80,
                backgroundColor: Colors.green.withOpacity(0.4), // تم التعديل هنا
              ),
            ),
            Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/logoflutter.png',
                        height: 100,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Login to Your Account',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: usernameController,
                        decoration: InputDecoration(
                          labelText: 'Username or email',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          suffixIcon: Icon(Icons.visibility_off),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            final username = usernameController.text.trim();
                            final password = passwordController.text.trim();
                            if (username.isEmpty || password.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please fill in all fields'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            loginWithCredentials(context, username, password);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF88A383),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          child: const Text(
                            'Login',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => loginWithGoogle(context),
                          icon: Image.asset(
                            'assets/google_logo.png',
                            height: 24,
                          ),
                          label: const Text(
                            'Sign in with Google',
                            style: TextStyle(fontSize: 16, color: Colors.black),
                          ),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => signup()),
                          );
                        },
                        child: const Text.rich(
                          TextSpan(
                            text: "Don't have an account? ",
                            style: TextStyle(color: Colors.black),
                            children: [
                              TextSpan(
                                text: 'Sign Up',
                                style: TextStyle(
                                  color: Color(0xFF88A383),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

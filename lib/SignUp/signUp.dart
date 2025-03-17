import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../SharedPreferences.dart';

class signup extends StatelessWidget {
  const signup({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const CreateProfileScreen(),
    );
  }
}

class CreateProfileScreen extends StatefulWidget {
  const CreateProfileScreen({super.key});

  @override
  _CreateProfileScreenState createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends State<CreateProfileScreen> {
  bool isChecked = false;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _gender;

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _signUp() async {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        _showSnackBar('Passwords do not match');
        return;
      }

      final baseUrl = await getBaseUrl();
      final signUpUrl = '$baseUrl/api/auth/signup';

      final response = await http.post(
        Uri.parse(signUpUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "username": _emailController.text.split('@')[0], // استخدام جزء من الإيميل كاسم مستخدم
          "email": _emailController.text,
          "password": _passwordController.text,
          "phoneNumber": _phoneNumberController.text,
          "gender": _gender,
        }),
      );

      if (response.statusCode == 200) {
        _showSnackBar('User registered successfully!');
        await _signIn();
      } else {
        _showSnackBar('Failed to register user: ${response.body}');
      }
    }
  }

  Future<void> _signIn() async {
    final baseUrl = await getBaseUrl();
    final signInUrl = '$baseUrl/api/auth/signin';

    final response = await http.post(
      Uri.parse(signInUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "username": _emailController.text.split('@')[0],
        "password": _passwordController.text,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['accessToken'];
      await _fetchUserInfo(token);
    } else {
      _showSnackBar('Failed to sign in: ${response.body}');
    }
  }

  Future<void> _fetchUserInfo(String token) async {
    final baseUrl = await getBaseUrl();
    final userInfoUrl = '$baseUrl/api/users/me';

    final response = await http.get(
      Uri.parse(userInfoUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final userInfo = jsonDecode(response.body);
      await saveUserData(token, userInfo);
      _showSnackBar('User info fetched successfully!');
    } else {
      _showSnackBar('Failed to fetch user info: ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue.shade50,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/p1.png',
                    width: 150,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Create your account',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 50),
                  Container(
                    width: 280,
                    child: Column(
                      children: [
                        _buildTextField('Email', _emailController, false),
                        const SizedBox(height: 10),
                        _buildTextField('Phone Number', _phoneNumberController, false),
                        const SizedBox(height: 10),
                        _buildTextField('Password', _passwordController, true),
                        const SizedBox(height: 10),
                        _buildTextField('Confirm Password', _confirmPasswordController, true),
                        const SizedBox(height: 15),
                        DropdownButtonFormField<String>(
                          value: _gender,
                          onChanged: (newValue) {
                            setState(() {
                              _gender = newValue;
                            });
                          },
                          items: <String>['MALE', 'FEMALE']
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          decoration: InputDecoration(
                            labelText: 'Gender',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              isChecked = !isChecked;
                            });
                          },
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.grey.shade600),
                                  color: isChecked ? Colors.blue.shade700 : Colors.transparent,
                                ),
                                child: isChecked
                                    ? const Icon(Icons.check, color: Colors.white, size: 18)
                                    : null,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'I agree with and accept Privacy and Policy',
                                  style: GoogleFonts.poppins(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildButtonContainer('Sign Up', _signUp),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String hintText, TextEditingController controller, bool isPassword) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      style: GoogleFonts.poppins(fontSize: 14),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue.shade300, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $hintText';
        }
        return null;
      },
    );
  }

  Widget _buildButtonContainer(String text, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: Colors.blue.shade700,
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
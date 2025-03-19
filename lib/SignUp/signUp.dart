import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../LogIn/login.dart';
import '../ProfileSection/profile.dart';
import '../SharedPreferences.dart'; // تأكد من أن هذا الملف موجود ويحتوي على الدوال المطلوبة

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
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _gender;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _signup() async {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        _showSnackBar('Passwords do not match');
        return;
      }

      if (!isChecked) {
        _showSnackBar('You must agree to the Privacy and Policy');
        return;
      }

      final baseUrl = await getBaseUrl();
      final signupUrl = '$baseUrl/api/auth/signup';

      final requestBody = {
        'username': _usernameController.text.trim(),
        'email': _emailController.text.trim(),
        'password': _passwordController.text.trim(),
        'phoneNumber': _phoneNumberController.text.trim(),
        'gender': _gender,
      };

      print('Sending request to: $signupUrl');
      print('Request body: $requestBody');

      try {
        final response = await http.post(
          Uri.parse(signupUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(requestBody),
        );

        print('Response status code: ${response.statusCode}');
        print('Response body: ${response.body}');

        if (response.statusCode == 200) {
          _showSnackBar('User registered successfully!');
          await _signIn();

        } else {
          _showSnackBar('Failed to register user: ${response.body}');
        }
      } catch (e) {
        _showSnackBar('An error occurred: $e');
      }
    }
  }

  Future<void> _signIn() async {
    final baseUrl = await getBaseUrl();
    final signInUrl = '$baseUrl/api/auth/signin';

    final requestBody = {
      "username": _usernameController.text.trim(),
      "password": _passwordController.text.trim(),
    };

    print('Sending request to: $signInUrl');
    print('Request body: $requestBody');

    try {
      final response = await http.post(
        Uri.parse(signInUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['accessToken'];
        await _fetchUserInfo(token);
      } else {
        _showSnackBar('Failed to sign in: ${response.body}');
      }
    } catch (e) {
      _showSnackBar('An error occurred: $e');
    }
  }

  Future<void> _fetchUserInfo(String token) async {
    final baseUrl = await getBaseUrl();
    final userInfoUrl = '$baseUrl/api/users/me';

    print('Sending request to: $userInfoUrl');
    print('Token: $token');

    try {
      final response = await http.get(
        Uri.parse(userInfoUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final userInfo = jsonDecode(response.body);
        await saveUserData(token, userInfo);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>  Profile(token: token, userInfo: userInfo),
          ),
        );
        _showSnackBar('User info fetched successfully!');
      } else {
        _showSnackBar('Failed to fetch user info: ${response.body}');
      }
    } catch (e) {
      _showSnackBar('An error occurred: $e');
    }
  }

  Widget _buildImagePicker() {
    return Column(
      children: [
        GestureDetector(
          onTap: _pickImage,
          child: CircleAvatar(
            radius: 50,
            backgroundColor: Color(0xFF88A383),
            backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null,
            child: _imageFile == null
                ? Icon(Icons.camera_alt, size: 40, color: Color(0xFF596D56))
                : null,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Add Profile Picture',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Color(0xFF596D56),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE8F5E9), // تغيير لون الخلفية إلى أخضر فاتح
      body: Stack(
        children: [
          Positioned(
            top: -50,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Color(0xFF88A383).withOpacity(0.5),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: Color(0xFF88A383).withOpacity(0.5),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // زر السهم للعودة إلى صفحة LoginScreen
                      Align(
                        alignment: Alignment.topLeft,
                        child: IconButton(
                          icon: Icon(Icons.arrow_back, color: Color(0xFF596D56), size: 40), // تكبير حجم السهم
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LoginScreen(), // الانتقال إلى LoginScreen
                              ),
                            );
                          },
                        ),
                      ),
                      Text(
                        'Create your account',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildImagePicker(),
                      const SizedBox(height: 20),
                      Container(
                        width: 320, // زيادة عرض الحاوية
                        child: Column(
                          children: [
                            _buildTextField('Username', _usernameController, false),
                            const SizedBox(height: 10),
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
                                      color: isChecked ? Color(0xFF596D56) : Colors.transparent,
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
                            _buildButtonContainer('Sign Up', _signup),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
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
          borderSide: BorderSide(color: Color(0xFF88A383), width: 2),
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
        minimumSize: Size(double.infinity, 50), // زيادة عرض الزر
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: Color(0xFF596D56),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 16, // زيادة حجم النص
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
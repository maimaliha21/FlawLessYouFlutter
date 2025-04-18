import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import '../ProfileSection/profile.dart';
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
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _gender;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  // Color Scheme
  final Color primaryColor = const Color(0xFF88A383); // Sage green
  final Color backgroundColor = const Color(0xFFF8F9FA); // Light background
  final Color cardColor = Colors.white;
  final Color textColor = const Color(0xFF212529);
  final Color secondaryTextColor = const Color(0xFF6C757D);
  final Color borderColor = const Color(0xFFE9ECEF);

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        final fileSize = await file.length();
        const maxSize = 5 * 1024 * 1024; // 5MB

        if (fileSize > maxSize) {
          _showSnackBar('Image size too large (max 5MB)');
          return;
        }

        setState(() {
          _imageFile = file;
        });
      }
    } catch (e) {
      _showSnackBar('Failed to pick image: ${e.toString()}');
    }
  }

  Future<void> _signup() async {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        _showSnackBar('Passwords do not match');
        return;
      }

      if (!isChecked) {
        _showSnackBar('Please agree to the Privacy Policy');
        return;
      }

      setState(() {
        _isLoading = true;
      });

      final baseUrl = await getBaseUrl();
      final signupUrl = '$baseUrl/api/auth/signup';

      final requestBody = {
        'username': _usernameController.text.trim(),
        'email': _emailController.text.trim(),
        'password': _passwordController.text.trim(),
        'phoneNumber': _phoneNumberController.text.trim(),
        'gender': _gender,
      };

      try {
        final response = await http.post(
          Uri.parse(signupUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(requestBody),
        );

        if (response.statusCode == 200) {
          _showSnackBar('Registration successful!');
          await _signIn();
        } else {
          final errorResponse = jsonDecode(response.body);
          _showSnackBar('Registration failed: ${errorResponse['message'] ?? 'Unknown error'}');
        }
      } catch (e) {
        _showSnackBar('An error occurred: ${e.toString()}');
      } finally {
        setState(() {
          _isLoading = false;
        });
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

    try {
      final response = await http.post(
        Uri.parse(signInUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['accessToken'];

        // Upload image if exists
        if (_imageFile != null) {
          await _uploadProfilePicture(token);
        }

        await _fetchUserInfo(token);
      } else {
        final errorResponse = jsonDecode(response.body);
        _showSnackBar('Login failed: ${errorResponse['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      _showSnackBar('An error occurred: ${e.toString()}');
    }
  }

  Future<void> _uploadProfilePicture(String token) async {
    final baseUrl = await getBaseUrl();
    final uploadUrl = '$baseUrl/api/users/profilePicture';

    if (_imageFile == null) return;

    try {
      var request = http.MultipartRequest('POST', Uri.parse(uploadUrl));
      request.headers['Authorization'] = 'Bearer $token';

      // Determine the mime type and add the file
      final mimeType = lookupMimeType(_imageFile!.path) ?? 'image/jpeg';
      final fileExtension = mimeType.split('/').last;

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          _imageFile!.path,
          contentType: MediaType('image', fileExtension),
        ),
      );

      var response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final jsonResponse = jsonDecode(responseBody);

      if (response.statusCode == 200) {
        debugPrint('Profile picture uploaded: ${jsonResponse['url']}');
      } else {
        throw Exception(jsonResponse['message'] ?? 'Failed to upload profile picture');
      }
    } catch (e) {
      debugPrint('Profile picture upload error: ${e.toString()}');
      throw Exception('Profile picture upload failed');
    }
  }

  Future<void> _fetchUserInfo(String token) async {
    final baseUrl = await getBaseUrl();
    final userInfoUrl = '$baseUrl/api/users/me';

    try {
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

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => Profile(token: token, userInfo: userInfo),
          ),
        );
      } else {
        throw Exception('Failed to fetch user info: ${response.body}');
      }
    } catch (e) {
      _showSnackBar('An error occurred: ${e.toString()}');
    }
  }

  Widget _buildImagePicker() {
    return Column(
      children: [
        GestureDetector(
          onTap: _pickImage,
          child: CircleAvatar(
            radius: 60,
            backgroundColor: primaryColor.withOpacity(0.1),
            backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null,
            child: _imageFile == null
                ? Icon(Icons.add_a_photo, size: 40, color: primaryColor)
                : null,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Add Profile Picture',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: primaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Text(
                'Create Account',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Fill in your details to get started',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: secondaryTextColor,
                ),
              ),
              const SizedBox(height: 32),
              _buildImagePicker(),
              const SizedBox(height: 32),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildTextField('Username', Icons.person, _usernameController, false),
                    const SizedBox(height: 16),
                    _buildTextField('Email', Icons.email, _emailController, false),
                    const SizedBox(height: 16),
                    _buildTextField('Phone Number', Icons.phone, _phoneNumberController, false),
                    const SizedBox(height: 16),
                    _buildTextField('Password', Icons.lock, _passwordController, true),
                    const SizedBox(height: 16),
                    _buildTextField('Confirm Password', Icons.lock, _confirmPasswordController, true),
                    const SizedBox(height: 16),
                    _buildGenderDropdown(),
                    const SizedBox(height: 24),
                    _buildTermsCheckbox(),
                    const SizedBox(height: 32),
                    _isLoading
                        ? const CircularProgressIndicator(color: Color(0xFF88A383))
                        : _buildsignupButton(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, IconData icon, TextEditingController controller, bool isPassword) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        style: GoogleFonts.poppins(color: textColor),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(color: secondaryTextColor),
          prefixIcon: Icon(icon, color: primaryColor),
          filled: true,
          fillColor: cardColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryColor, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $label';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
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
            child: Text(
              value == 'MALE' ? 'Male' : 'Female',
              style: GoogleFonts.poppins(),
            ),
          );
        }).toList(),
        decoration: InputDecoration(
          labelText: 'Gender',
          labelStyle: GoogleFonts.poppins(color: secondaryTextColor),
          prefixIcon: Icon(Icons.people, color: primaryColor),
          filled: true,
          fillColor: cardColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryColor, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        style: GoogleFonts.poppins(color: textColor),
      ),
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              isChecked = !isChecked;
            });
          },
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: isChecked ? primaryColor : Colors.transparent,
              border: Border.all(
                color: isChecked ? primaryColor : borderColor,
                width: 1.5,
              ),
            ),
            child: isChecked
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'I agree to the Terms and Conditions and Privacy Policy',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: secondaryTextColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildsignupButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _signup,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
        ),
        child: Text(
          'Sign Up',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
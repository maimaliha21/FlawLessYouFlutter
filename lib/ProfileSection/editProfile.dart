import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http_parser/http_parser.dart'; // لأجل MediaType
import '../CustomBottomNavigationBar.dart';
import '../LogIn/login.dart';
import '../SharedPreferences.dart';

class EditProfile extends StatefulWidget {
  final String token;

  const EditProfile({
    Key? key,
    required this.token,
  }) : super(key: key);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfile>
    with SingleTickerProviderStateMixin {
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  late TabController _tabController;
  String baseUrl = '';
  bool _isLoading = false;
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadBaseUrl();
    fetchUserData();
  }

  Future<void> _loadBaseUrl() async {
    final url = await getBaseUrl();
    setState(() {
      baseUrl = url ?? '';
    });
  }

  Future<void> fetchUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/users/profile'),
        headers: {
          'accept': '*/*',
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> userData = jsonDecode(response.body);
        setState(() {
          _usernameController.text = userData['userName'] ?? '';
          _emailController.text = userData['email'] ?? '';
          _phoneController.text = userData['phoneNumber'] ?? '';
          _genderController.text = userData['gender'] ?? '';
          _profileImageUrl = userData['profilePictureUrl'];
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch user data: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        final File imageFile = File(image.path);
        final int fileSize = await imageFile.length();
        const int maxSize = 5 * 1024 * 1024; // 5MB

        if (fileSize > maxSize) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Image size should be less than 5MB')),
          );
          return;
        }

        setState(() {
          _profileImage = imageFile;
          _isLoading = true;
        });

        await _uploadProfileImage(imageFile);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting image: $e')),
      );
    }
  }

  Future<void> _uploadProfileImage(File imageFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/users/profilePicture'),
      );

      request.headers['Authorization'] = 'Bearer ${widget.token}';
      request.headers['accept'] = '*/*';

      // تحديد نوع المحتوى بناءً على امتداد الملف
      String extension = imageFile.path.split('.').last.toLowerCase();
      String contentType = 'image/$extension';
      if (extension == 'jpg') contentType = 'image/jpeg';

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
          contentType: MediaType.parse(contentType),
        ),
      );

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var jsonResponse = jsonDecode(responseData);

      if (response.statusCode == 200) {
        setState(() {
          _profileImageUrl = jsonResponse['url'];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(jsonResponse['message'] ?? 'Profile picture updated successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload: ${jsonResponse['message'] ?? response.reasonPhrase}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload error: ${e.toString()}')),
      );
      debugPrint('Upload error details: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveChanges() async {
    if (_tabController.index == 1) {
      if (_newPasswordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('New password and confirmation do not match')),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        final response = await http.put(
          Uri.parse('$baseUrl/api/auth/changePassword'),
          headers: {
            'accept': '*/*',
            'Authorization': 'Bearer ${widget.token}',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'oldPassword': _oldPasswordController.text,
            'newPassword': _newPasswordController.text,
          }),
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Password changed successfully')),
          );

          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => LoginScreen()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to change password: ${response.statusCode}')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      final result = await showDialog(
        context: context,
        builder: (BuildContext context) {
          String username = '';
          String password = '';

          return AlertDialog(
            title: Text('Identity verification'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: InputDecoration(labelText: 'Username'),
                  onChanged: (value) {
                    username = value;
                  },
                ),
                TextField(
                  decoration: InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  onChanged: (value) {
                    password = value;
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop({'username': username, 'password': password});
                },
                child: Text('Confirmation'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Cancel'),
              ),
            ],
          );
        },
      );

      if (result == null) return;

      setState(() {
        _isLoading = true;
      });

      try {
        final authResponse = await http.post(
          Uri.parse('$baseUrl/api/auth/signin'),
          headers: {
            'accept': '*/*',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'username': result['username'],
            'password': result['password'],
          }),
        );

        if (authResponse.statusCode == 200) {
          final Map<String, dynamic> requestBody = {
            "userName": _usernameController.text,
            "email": _emailController.text,
            "phoneNumber": _phoneController.text,
            "gender": _genderController.text.isEmpty ? null : _genderController.text.toUpperCase(),
          };

          final updateResponse = await http.put(
            Uri.parse('$baseUrl/api/users/update'),
            headers: {
              'accept': '*/*',
              'Authorization': 'Bearer ${widget.token}',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(requestBody),
          );

          if (updateResponse.statusCode == 200) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('User updated successfully')),
            );

            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => LoginScreen()),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to update user: ${updateResponse.statusCode}')),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Username or password is incorrect')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _genderController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Personal Info'),
            Tab(text: 'Security'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          SizedBox(height: 20),
          Padding(
            padding: EdgeInsets.only(top: 20),
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      spreadRadius: 2,
                      offset: Offset(0, 4),
                    ),
                  ],
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: _getProfileImage(),
                ),
              ),
            ),
          ),
          SizedBox(height: 20),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildTextFieldWithDescription(
                        'Username',
                        _usernameController,
                        description: 'Enter your username',
                        hintText: _usernameController.text.isEmpty ? null : _usernameController.text,
                      ),
                      const SizedBox(height: 10),
                      _buildTextFieldWithDescription(
                        'Email',
                        _emailController,
                        description: 'Enter your email address',
                        hintText: _emailController.text.isEmpty ? null : _emailController.text,
                      ),
                      const SizedBox(height: 10),
                      _buildTextFieldWithDescription(
                        'Phone Number',
                        _phoneController,
                        description: 'Enter your phone number',
                        hintText: _phoneController.text.isEmpty ? null : _phoneController.text,
                      ),
                      const SizedBox(height: 10),
                      _buildTextFieldWithDescription(
                        'Gender',
                        _genderController,
                        description: 'Enter your gender (MALE/FEMALE)',
                        hintText: _genderController.text.isEmpty ? null : _genderController.text,
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
                SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildTextFieldWithDescription(
                        'Old Password',
                        _oldPasswordController,
                        description: 'Enter your old password',
                        isPassword: true,
                      ),
                      _buildTextFieldWithDescription(
                        'New Password',
                        _newPasswordController,
                        description: 'Enter your new password',
                        isPassword: true,
                      ),
                      _buildTextFieldWithDescription(
                        'Confirm New Password',
                        _confirmPasswordController,
                        description: 'Confirm your new password',
                        isPassword: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _isLoading
          ? null
          : Padding(
        padding: EdgeInsets.only(bottom: 155),
        child: FloatingActionButton.extended(
          onPressed: _saveChanges,
          icon: Icon(Icons.save, color: Colors.white),
          label: Text(
            'Save Changes',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.blue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 5,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: CustomBottomNavigationBar2(),
    );
  }

  ImageProvider? _getProfileImage() {
    if (_profileImage != null) {
      return FileImage(_profileImage!);
    } else if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
      return NetworkImage(_profileImageUrl!);
    }
    return AssetImage('assets/profile.jpg');
  }

  Widget _buildTextFieldWithDescription(
      String label,
      TextEditingController controller, {
        String? description,
        bool isPassword = false,
        String? hintText,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (description != null)
          Padding(
            padding: EdgeInsets.only(bottom: 5),
            child: Text(
              description,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        _buildTextField(label, controller, isPassword: isPassword, hintText: hintText),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool isPassword = false, String? hintText}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 20),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          filled: true,
          fillColor: Colors.grey[200],
        ),
      ),
    );
  }
}
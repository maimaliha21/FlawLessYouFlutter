import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../LogIn/login.dart';
import '../Product/product.dart';

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

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this); // طول التبويب 1
    fetchUserData(); // جلب بيانات المستخدم عند بدء التشغيل
  }
  Future<void> fetchUserData() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:8080/api/users/profile'),
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
          _genderController.text = userData['gender'] ?? ''; // تعيينها إلى فارغة إذا كانت null
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
    }
  }
  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _profileImage = File(image.path);
      });
    }
  }

  Future<void> _saveChanges() async {
    // عرض Dialog لإدخال اسم المستخدم وكلمة المرور
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
                Navigator.of(context).pop(); // إغلاق Dialog بدون إرجاع بيانات
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );

    // إذا تم الضغط على إلغاء، لا نكمل العملية
    if (result == null) return;

    final String username = result['username'];
    final String password = result['password'];

    try {
      // التحقق من صحة اسم المستخدم وكلمة المرور
      final authResponse = await http.post(
        Uri.parse('http://localhost:8080/api/auth/signin'),
        headers: {
          'accept': '*/*',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      if (authResponse.statusCode == 200) {
        // إذا كانت البيانات صحيحة، نتابع عملية التحديث
        final Map<String, dynamic> requestBody = {
          "userName": _usernameController.text,
          "email": _emailController.text,
          "phoneNumber": _phoneController.text,
          "gender": _genderController.text.isEmpty ? null : _genderController.text.toUpperCase(),
        };

        final updateResponse = await http.put(
          Uri.parse('http://localhost:8080/api/users/update'),
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

          // الانتقال إلى صفحة تسجيل الدخول بعد عرض الرسالة
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => LoginScreen()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update user: ${updateResponse.statusCode}')),
          );
        }
      } else {
        // إذا كانت البيانات غير صحيحة، نعرض رسالة خطأ
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Username or password is incorrect')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    }
  }
  @override
  void dispose() {
    _tabController.dispose();
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
      body: Column(
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
                  backgroundImage: _profileImage == null
                      ? AssetImage('assets/profile.jpg') as ImageProvider
                      : FileImage(_profileImage!),
                ),
              ),
            ),
          ),
          SizedBox(height: 20),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Personal Info Tab
                SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Username field
                      _buildTextFieldWithDescription(
                        'Username',
                        _usernameController,
                        description: 'Enter your username',
                        hintText: _usernameController.text.isEmpty ? null : _usernameController.text,
                      ),
                      const SizedBox(height: 10),

                      // Email field
                      _buildTextFieldWithDescription(
                        'Email',
                        _emailController,
                        description: 'Enter your email address',
                        hintText: _emailController.text.isEmpty ? null : _emailController.text,
                      ),
                      const SizedBox(height: 10),

                      // Phone number field
                      _buildTextFieldWithDescription(
                        'Phone Number',
                        _phoneController,
                        description: 'Enter your phone number',
                        hintText: _phoneController.text.isEmpty ? null : _phoneController.text,
                      ),
                      const SizedBox(height: 10),

                      // Gender field
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

                // Security Tab
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
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
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
    );
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
          hintText: hintText, // عرض البيانات الحالية كـ hint
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
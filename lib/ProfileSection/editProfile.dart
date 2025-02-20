import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

void main() {
  runApp(editProfile());
}

class editProfile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: EditProfileScreen(),
    );
  }
}

class EditProfileScreen extends StatefulWidget {
  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen>
    with SingleTickerProviderStateMixin {
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _profileImage = File(image.path);
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dobController.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            // الانتقال إلى صفحة أخرى (مثل صفحة البروفايل)
            Navigator.pop(context);
          },
        ),
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
          // مساحة فارغة في الأعلى
          SizedBox(height: 20),
          // صورة البروفايل مع ظل
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
          SizedBox(height: 20), // مسافة بين صورة البروفايل والحقول
          // التبويبات
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Personal Info Tab
                SingleChildScrollView(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildTextFieldWithDescription(
                        'First Name',
                        _firstNameController,
                        description: 'Enter your first name',
                      ),
                      _buildTextFieldWithDescription(
                        'Last Name',
                        _lastNameController,
                        description: 'Enter your last name',
                      ),
                      _buildDateFieldWithDescription(
                        'Date of Birth',
                        _dobController,
                        context,
                        description: 'Select your date of birth',
                      ),
                      _buildTextFieldWithDescription(
                        'Phone Number',
                        _phoneController,
                        description: 'Enter your phone number',
                      ),
                    ],
                  ),
                ),
                // Security Tab
                SingleChildScrollView(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildTextFieldWithDescription(
                        'Email',
                        _emailController,
                        description: 'Enter your email address',
                      ),
                      _buildTextFieldWithDescription(
                        'Username',
                        _usernameController,
                        description: 'Enter your username',
                      ),
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
      // زر Save مع تصميم جديد
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: 155), // رفع الزر لأعلى قليلاً
        child: FloatingActionButton.extended(
          onPressed: () {
            // Save changes logic here
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Changes saved successfully!')),
            );
          },
          icon: Icon(Icons.save, color: Colors.white),
          label: Text(
            'Save Changes',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.blue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30), // حواف مدورة
          ),
          elevation: 5, // ظل للزر
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat, // وضع الزر في المنتصف
    );
  }

  Widget _buildTextFieldWithDescription(
      String label,
      TextEditingController controller, {
        String? description,
        bool isPassword = false,
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
        _buildTextField(label, controller, isPassword: isPassword),
      ],
    );
  }

  Widget _buildDateFieldWithDescription(
      String label,
      TextEditingController controller,
      BuildContext context, {
        String? description,
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
        _buildDateField(label, controller, context),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool isPassword = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 20),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          filled: true,
          fillColor: Colors.grey[200],
        ),
      ),
    );
  }

  Widget _buildDateField(
      String label, TextEditingController controller, BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 20),
      child: TextField(
        controller: controller,
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          filled: true,
          fillColor: Colors.grey[200],
          suffixIcon: IconButton(
            icon: Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context),
          ),
        ),
        onTap: () => _selectDate(context),
      ),
    );
  }
}
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http_parser/http_parser.dart';
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
  // Controllers and Variables
  late TabController _tabController;
  final ImagePicker _picker = ImagePicker();
  File? _profileImage;
  String? _profileImageUrl;
  String? _selectedGender;
  bool _isLoading = false;
  String baseUrl = '';

  // Form Controllers
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // Constants
  final List<String> genders = ['MALE', 'FEMALE'];
  final double profileImageSize = 100.0;
  final double formPadding = 20.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeData();
  }

  // Initialization Methods
  Future<void> _initializeData() async {
    setState(() => _isLoading = true);
    try {
      await _loadBaseUrl();
      await _loadUserDataFromCache();
      await fetchUserData();
    } catch (e) {
      _showErrorSnackbar('Error initializing data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadBaseUrl() async {
    final url = await getBaseUrl();
    setState(() => baseUrl = url ?? '');
  }

  Future<void> _loadUserDataFromCache() async {
    final userData = await getUserData();
    if (userData != null && userData['userInfo'] != null) {
      final userInfo = userData['userInfo'];
      setState(() {
        _usernameController.text = userInfo['userName'] ?? '';
        _emailController.text = userInfo['email'] ?? '';
        _phoneController.text = userInfo['phoneNumber'] ?? '';
        _selectedGender = userInfo['gender'];
        _profileImageUrl = userInfo['profilePicture'];
      });
    }
  }

  // Data Handling Methods
  Future<void> fetchUserData() async {
    try {
      if (baseUrl.isEmpty) return;

      final response = await http.get(
        Uri.parse('$baseUrl/api/users/profile'),
        headers: _buildHeaders(),
      );

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        setState(() {
          _usernameController.text = userData['userName'] ?? _usernameController.text;
          _emailController.text = userData['email'] ?? _emailController.text;
          _phoneController.text = userData['phoneNumber'] ?? _phoneController.text;
          _selectedGender = userData['gender'];
          _profileImageUrl = userData['profilePicture'];
        });
        await _updateSharedPreferences(userData);
      } else {
        throw Exception('Failed with status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
    }
  }

  Map<String, String> _buildHeaders() {
    return {
      'accept': '*/*',
      'Authorization': 'Bearer ${widget.token}',
    };
  }

  // Image Handling
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        final imageFile = File(image.path);
        if (await _validateImageSize(imageFile)) {
          setState(() {
            _profileImage = imageFile;
            _isLoading = true;
          });
          await _uploadProfileImage(imageFile);
        }
      }
    } catch (e) {
      _showErrorSnackbar('Error selecting image: $e');
    }
  }

  Future<bool> _validateImageSize(File imageFile) async {
    final fileSize = await imageFile.length();
    const maxSize = 5 * 1024 * 1024;
    if (fileSize > maxSize) {
      _showErrorSnackbar('Image size should be less than 5MB');
      return false;
    }
    return true;
  }

  Future<void> _uploadProfileImage(File imageFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/users/profilePicture'),
      );

      request.headers.addAll(_buildHeaders());

      final extension = imageFile.path.split('.').last.toLowerCase();
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
          contentType: MediaType.parse(extension == 'jpg' ? 'image/jpeg' : 'image/$extension'),
        ),
      );

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonResponse = jsonDecode(responseData);

      if (response.statusCode == 200) {
        setState(() => _profileImageUrl = jsonResponse['url']);
        await _updateSharedPreferences({'profilePicture': jsonResponse['url']});
        _showSuccessSnackbar('Profile picture updated successfully');
      } else {
        throw Exception(jsonResponse['message'] ?? 'Upload failed');
      }
    } catch (e) {
      _showErrorSnackbar('Upload error: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Profile Update Methods
  Future<void> _saveChanges() async {
    _tabController.index == 1
        ? await _handlePasswordChange()
        : await _handleProfileUpdate();
  }

  Future<void> _handlePasswordChange() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showErrorSnackbar('New password and confirmation do not match');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/auth/changePassword'),
        headers: {
          ..._buildHeaders(),
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'oldPassword': _oldPasswordController.text,
          'newPassword': _newPasswordController.text,
        }),
      );

      if (response.statusCode == 200) {
        _showSuccessSnackbar('Password changed successfully');
        _navigateToLogin();
      } else {
        throw Exception('Failed with status: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorSnackbar('Error changing password: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleProfileUpdate() async {
    final result = await _showVerificationDialog();
    if (result == null) return;

    setState(() => _isLoading = true);

    try {
      await _verifyCredentials(result['username']!, result['password']!);
      await _updateProfile();
    } catch (e) {
      _showErrorSnackbar('Error updating profile: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<Map<String, String>?> _showVerificationDialog() async {
    String username = '';
    String password = '';

    return await showDialog<Map<String, String>>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Identity Verification', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => username = value,
              ),
              SizedBox(height: 15),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                onChanged: (value) => password = value,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop({'username': username, 'password': password}),
              child: Text('Verify', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _verifyCredentials(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/signin'),
      headers: {
        'accept': '*/*',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Username or password is incorrect');
    }
  }

  Future<void> _updateProfile() async {
    final requestBody = {
      "userName": _usernameController.text,
      "email": _emailController.text,
      "phoneNumber": _phoneController.text,
      "gender": _selectedGender,
    };

    final response = await http.put(
      Uri.parse('$baseUrl/api/users/update'),
      headers: {
        ..._buildHeaders(),
        'Content-Type': 'application/json',
      },
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      _showSuccessSnackbar('Profile updated successfully');
      await _updateSharedPreferences(requestBody);
      _navigateToLogin();
    } else {
      throw Exception('Failed with status: ${response.statusCode}');
    }
  }

  // Helper Methods
  Future<void> _updateSharedPreferences(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userInfoJson = prefs.getString('userInfo');
      final existingUserInfo = userInfoJson != null ? jsonDecode(userInfoJson) : {};

      existingUserInfo.addAll({
        'userName': userData['userName'] ?? existingUserInfo['userName'],
        'email': userData['email'] ?? existingUserInfo['email'],
        'phoneNumber': userData['phoneNumber'] ?? existingUserInfo['phoneNumber'],
        'gender': userData['gender'] ?? existingUserInfo['gender'],
        'profilePicture': userData['profilePicture'] ?? existingUserInfo['profilePicture'],
      });

      await prefs.setString('userInfo', jsonEncode(existingUserInfo));
    } catch (e) {
      debugPrint('Error updating SharedPreferences: $e');
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  // UI Components
  Widget _buildProfileImage() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: profileImageSize,
        height: profileImageSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              spreadRadius: 2,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            CircleAvatar(
              radius: profileImageSize / 2,
              backgroundColor: Colors.grey[200],
              backgroundImage: _profileImage != null
                  ? FileImage(_profileImage!)
                  : (_profileImageUrl != null && _profileImageUrl!.isNotEmpty
                  ? NetworkImage(_profileImageUrl!)
                  : null),
              child: _profileImage == null && (_profileImageUrl == null || _profileImageUrl!.isEmpty)
                  ? Icon(Icons.person, size: profileImageSize / 2, color: Colors.white)
                  : null,
            ),
            if (_isLoading)
              Positioned.fill(
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.edit, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfoTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(formPadding),
      child: Column(
        children: [
          _buildInputField(
            controller: _usernameController,
            label: 'Username',
            hint: 'Enter your username',
            icon: Icons.person,
          ),
          SizedBox(height: 15),
          _buildInputField(
            controller: _emailController,
            label: 'Email',
            hint: 'Enter your email address',
            icon: Icons.email,
            keyboardType: TextInputType.emailAddress,
          ),
          SizedBox(height: 15),
          _buildInputField(
            controller: _phoneController,
            label: 'Phone Number',
            hint: 'Enter your phone number',
            icon: Icons.phone,
            keyboardType: TextInputType.phone,
          ),
          SizedBox(height: 15),
          _buildGenderDropdown(),
        ],
      ),
    );
  }

  Widget _buildSecurityTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(formPadding),
      child: Column(
        children: [
          _buildInputField(
            controller: _oldPasswordController,
            label: 'Old Password',
            hint: 'Enter your current password',
            icon: Icons.lock,
            isPassword: true,
          ),
          SizedBox(height: 15),
          _buildInputField(
            controller: _newPasswordController,
            label: 'New Password',
            hint: 'Enter your new password',
            icon: Icons.lock_outline,
            isPassword: true,
          ),
          SizedBox(height: 15),
          _buildInputField(
            controller: _confirmPasswordController,
            label: 'Confirm Password',
            hint: 'Re-enter your new password',
            icon: Icons.lock_reset,
            isPassword: true,
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.grey[600]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Theme.of(context).primaryColor),
        ),
        filled: true,
        fillColor: Colors.grey[100],
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 5, bottom: 5),
          child: Text(
            'Gender',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.grey[100],
            border: Border.all(color: Colors.grey),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 15),
            child: DropdownButtonFormField<String>(
              value: _selectedGender,
              decoration: InputDecoration(
                border: InputBorder.none,
                prefixIcon: Icon(Icons.transgender, color: Colors.grey[600]),
              ),
              items: genders.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedGender = newValue;
                });
              },
              style: TextStyle(color: Colors.black87),
              dropdownColor: Colors.white,
              icon: Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
              hint: Text('Select your gender'),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Edit Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          tabs: [
            Tab(icon: Icon(Icons.person), text: 'Personal Info'),
            Tab(icon: Icon(Icons.security), text: 'Security'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          SizedBox(height: 20),
          Center(child: _buildProfileImage()),
          SizedBox(height: 20),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPersonalInfoTab(),
                _buildSecurityTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _isLoading
          ? null
          : Padding(
        padding: EdgeInsets.only(bottom: 20),
        child: FloatingActionButton.extended(
          onPressed: _saveChanges,
          icon: Icon(Icons.save, color: Colors.white),
          label: Text(
            'Save Changes',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Theme.of(context).primaryColor,
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

  @override
  void dispose() {
    _tabController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
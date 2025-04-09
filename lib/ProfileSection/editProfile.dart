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
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  late TabController _tabController;
  String baseUrl = '';
  bool _isLoading = false;
  String? _profileImageUrl;
  String? _selectedGender;
  List<String> genders = ['MALE', 'FEMALE'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() => _isLoading = true);
    try {
      await _loadBaseUrl();
      await _loadUserDataFromCache();
      await fetchUserData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error initializing data: $e')),
      );
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
        _profileImageUrl = userInfo['profilePicture'] ?? userInfo['profilePictureUrl'];
      });
    }
  }

  Future<void> fetchUserData() async {
    try {
      if (baseUrl.isEmpty) return;

      final response = await http.get(
        Uri.parse('$baseUrl/api/users/profile'),
        headers: {
          'accept': '*/*',
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        setState(() {
          _usernameController.text = userData['userName'] ?? _usernameController.text;
          _emailController.text = userData['email'] ?? _emailController.text;
          _phoneController.text = userData['phoneNumber'] ?? _phoneController.text;
          _selectedGender = userData['gender'];
          _profileImageUrl = userData['profilePicture'] ?? _profileImageUrl;
        });
        await _updateSharedPreferences(userData);
      } else {
        throw Exception('Failed with status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
    }
  }

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
        final fileSize = await imageFile.length();
        const maxSize = 5 * 1024 * 1024;

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

      final extension = imageFile.path.split('.').last.toLowerCase();
      final contentType = extension == 'jpg' ? 'image/jpeg' : 'image/$extension';

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
          contentType: MediaType.parse(contentType),
        ),
      );

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonResponse = jsonDecode(responseData);

      if (response.statusCode == 200) {
        setState(() => _profileImageUrl = jsonResponse['url']);
        await _updateSharedPreferences({'profilePicture': jsonResponse['url']});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile picture updated successfully')),
        );
      } else {
        throw Exception(jsonResponse['message'] ?? 'Upload failed');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveChanges() async {
    if (_tabController.index == 1) {
      await _handlePasswordChange();
    } else {
      await _handleProfileUpdate();
    }
  }

  Future<void> _handlePasswordChange() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('New password and confirmation do not match')),
      );
      return;
    }

    setState(() => _isLoading = true);

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
        throw Exception('Failed with status: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error changing password: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleProfileUpdate() async {
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
                onChanged: (value) => username = value,
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
                onChanged: (value) => password = value,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop({'username': username, 'password': password}),
              child: Text('Confirmation'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );

    if (result == null) return;

    setState(() => _isLoading = true);

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

      if (authResponse.statusCode != 200) {
        throw Exception('Username or password is incorrect');
      }

      final requestBody = {
        "userName": _usernameController.text,
        "email": _emailController.text,
        "phoneNumber": _phoneController.text,
        "gender": _selectedGender,
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
          SnackBar(content: Text('Profile updated successfully')),
        );
        await _updateSharedPreferences(requestBody);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      } else {
        throw Exception('Failed with status: ${updateResponse.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
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

  Widget _buildProfileImage() {
    if (_profileImage != null) {
      return CircleAvatar(
        radius: 60,
        backgroundImage: FileImage(_profileImage!),
      );
    } else if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 60,
        backgroundImage: NetworkImage(_profileImageUrl!),
      );
    }
    return CircleAvatar(
      radius: 60,
      child: Icon(Icons.person, size: 60),
    );
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
                child: _buildProfileImage(),
              ),
            ),
          ),
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
        padding: EdgeInsets.only(bottom: 155),
        child: FloatingActionButton.extended(
          onPressed: _saveChanges,
          icon: Icon(Icons.save, color: Colors.white),
          label: Text('Save Changes', style: TextStyle(color: Colors.white)),
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

  Widget _buildPersonalInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildTextFieldWithDescription(
            'Username',
            _usernameController,
            description: 'Enter your username',
          ),
          const SizedBox(height: 10),
          _buildTextFieldWithDescription(
            'Email',
            _emailController,
            description: 'Enter your email address',
          ),
          const SizedBox(height: 10),
          _buildTextFieldWithDescription(
            'Phone Number',
            _phoneController,
            description: 'Enter your phone number',
          ),
          const SizedBox(height: 10),
          Padding(
            padding: EdgeInsets.only(bottom: 5),
            child: Text(
              'Select your gender',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          DropdownButtonFormField<String>(
            value: _selectedGender,
            decoration: InputDecoration(
              labelText: 'Gender',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.grey[200],
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
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSecurityTab() {
    return SingleChildScrollView(
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
}
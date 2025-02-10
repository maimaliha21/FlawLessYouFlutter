import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'profile.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(editProfile());
}

class editProfile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: EditProfileScreen(token: 'your_token_here', userInfo: {}),
    );
  }
}

class EditProfileScreen extends StatefulWidget {
  final String token;
  final Map<String, dynamic> userInfo;

  const EditProfileScreen({
    Key? key,
    required this.token,
    required this.userInfo,
  }) : super(key: key);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _profileImage = File(image.path);
      });
    }
  }

  Future<void> _saveChanges() async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://localhost:8080/api/users/update-profile'),
      );

      request.headers.addAll({
        'Authorization': 'Bearer ${widget.token}',
      });

      if (_profileImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'file',
            _profileImage!.path,
          ),
        );
      }

      request.fields['firstName'] = _firstNameController.text;
      request.fields['lastName'] = _lastNameController.text;
      request.fields['dob'] = _dobController.text;
      request.fields['password'] = _passwordController.text;

      var response = await request.send();
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      } else {
        throw Exception('Failed to update profile');
      }
    } catch (e) {
      print('Error updating profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update profile')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _firstNameController.text = widget.userInfo['firstName'] ?? '';
    _lastNameController.text = widget.userInfo['lastName'] ?? '';
    _dobController.text = widget.userInfo['dob'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/bgphoto.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            top: 40,
            left: 10,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfileScreen(token: widget.token, userInfo: widget.userInfo)),
                );
              },
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      spreadRadius: 2,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              children: [
                SizedBox(height: 90),
                Align(
                  alignment: Alignment.center,
                  child: Stack(
                    children: [
                      GestureDetector(
                        onTap: _pickImage,
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.white,
                          child: CircleAvatar(
                            radius: 55,
                            backgroundImage: _profileImage == null
                                ? AssetImage('assets/profile.jpg') as ImageProvider
                                : FileImage(_profileImage!),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 5,
                        right: 5,
                        child: CircleAvatar(
                          radius: 15,
                          backgroundColor: Colors.blue,
                          child: Icon(Icons.edit, color: Colors.white, size: 15),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: _buildTextField('First Name', _firstNameController)),
                    SizedBox(width: 10),
                    Expanded(child: _buildTextField('Last Name', _lastNameController)),
                  ],
                ),
                _buildTextField('Date of Birth', _dobController),
                _buildTextField('Change Password', _passwordController, isPassword: true),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text('Save Changes'),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipPath(
            clipper: BottomWaveClipper(),
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 25,
            left: MediaQuery.of(context).size.width / 2 - 30,
            child: FloatingActionButton(
              backgroundColor: Colors.blue,
              onPressed: () {},
              child: Icon(Icons.face, color: Colors.white),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 70,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    icon: Icon(Icons.home, color: Colors.blue),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: Icon(Icons.chat, color: Colors.blue),
                    onPressed: () {},
                  ),
                  SizedBox(width: 60),
                  IconButton(
                    icon: Icon(Icons.settings, color: Colors.blue),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: Icon(Icons.person, color: Colors.blue),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isPassword = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 5),
        TextField(
          controller: controller,
          obscureText: isPassword,
          decoration: InputDecoration(
            hintText: label,
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 10),
      ],
    );
  }
}

class BottomWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 20);
    path.quadraticBezierTo(
        size.width / 4, size.height, size.width / 2, size.height - 20);
    path.quadraticBezierTo(
        size.width * 3 / 4, size.height - 40, size.width, size.height - 20);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:projtry1/ProfileSection/editProfile.dart';
import 'package:projtry1/api/google_signin_api.dart';
import 'package:projtry1/LogIn/login.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:projtry1/Product/product.dart';
import 'package:projtry1/Product/productPage.dart';
import 'dart:convert';
class Profile extends StatelessWidget {
  final String token;
  final Map<String, dynamic> userInfo;

  const Profile({
    Key? key,
    required this.token,
    required this.userInfo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ProfileScreen(token: token, userInfo: userInfo),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  final String token;
  final Map<String, dynamic> userInfo;

  const ProfileScreen({
    Key? key,
    required this.token,
    required this.userInfo,
  }) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _profileImage = File(image.path);
        });
        await _uploadProfilePicture(File(image.path));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No image selected')),
        );
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to pick image')),
      );
    }
  }

  Future<void> _uploadProfilePicture(File imageFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://localhost:8080/api/users/profilePicture'),
      );

      request.headers.addAll({
        'Authorization': 'Bearer ${widget.token}',
      });

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
        ),
      );

      print('Sending request with file: ${imageFile.path}');

      var response = await request.send();

      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var jsonResponse = jsonDecode(responseData);

        print('Response: $jsonResponse');

        setState(() {
          widget.userInfo['profilePicture'] = jsonResponse['url'];
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated successfully')),
        );
      } else {
        var errorResponse = await response.stream.bytesToString();
        print('Error response: $errorResponse');
        throw Exception('Failed to upload profile picture. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error uploading profile picture: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to upload profile picture')),
      );
    }
  }
  Future<void> _handleLogout() async {
    try {
      // await GoogleSignInApi.signOut();
      // Navigator.of(context).pushAndRemoveUntil(
      //   MaterialPageRoute(builder: (context) => const LoginScreen()),
      //       (route) => false,
      // );
    } catch (e) {
      print('Error during logout: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to logout')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 250,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/bgphoto.jpg'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  top: 30,
                  right: 20,
                  child: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'logout') _handleLogout();
                    },
                    itemBuilder: (BuildContext context) => [
                      const PopupMenuItem(
                        value: 'support',
                        child: Text('Support'),
                      ),
                      const PopupMenuItem(
                        value: 'about_us',
                        child: Text('About Us'),
                      ),
                      const PopupMenuItem(
                        value: 'logout',
                        child: Text('Log Out'),
                      ),
                    ],
                    child: const Icon(
                      Icons.more_vert,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
                Positioned(
                  top: 150,
                  left: MediaQuery.of(context).size.width / 2 - 75,
                  child: GestureDetector(
                    onTap: () => showDialog(
                      context: context,
                      builder: (context) => Dialog(
                        backgroundColor: Colors.transparent,
                        child: Stack(
                          children: [
                            Container(
                              width: 300,
                              height: 300,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(20),
                                image: DecorationImage(
                                  image: _getProfileImage(),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 15,
                              left: 50,
                              right: 50,
                              child: ElevatedButton(
                                onPressed: _pickImage,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFB0BEC5),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 50, vertical: 15),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text('Change Picture'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 75,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: 70,
                        backgroundColor: Colors.white,
                        child: CircleAvatar(
                          radius: 65,
                          backgroundImage: _getProfileImage(),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 60),
            Text(
              widget.userInfo['username'] ?? 'User',
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black),
            ),
            Text(
              widget.userInfo['email'] ?? '',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            if (widget.userInfo['skinType'] != null) ...[
              const SizedBox(height: 5),
              Text(
                'Skin Type: ${widget.userInfo['skinType']}',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => editProfile(
                      ),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 50, vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Edit profile'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 50, vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('View Routine'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TabBarSection(token: widget.token),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        token: widget.token,
        userInfo: widget.userInfo,
      ),
    );
  }

  ImageProvider _getProfileImage() {
    if (_profileImage != null) return FileImage(_profileImage!);
    if (widget.userInfo['profilePicture'] != null) {
      return NetworkImage(widget.userInfo['profilePicture']);
    }
    return const AssetImage('assets/profile.jpg');
  }
}

class CustomBottomNavigationBar extends StatelessWidget {
  final String token;
  final Map<String, dynamic> userInfo;

  const CustomBottomNavigationBar({
    super.key,
    required this.token,
    required this.userInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
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
            child: const Icon(Icons.face, color: Colors.white),
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
                  icon: const Icon(Icons.home, color: Colors.blue),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.chat, color: Colors.blue),
                  onPressed: () {},
                ),
                const SizedBox(width: 60),
                IconButton(
                  icon: const Icon(Icons.settings, color: Colors.blue),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductPage(token: token,userInfo: userInfo

                        ),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.person, color: Colors.blue),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class BottomWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 20);
    path.quadraticBezierTo(size.width / 4, size.height, size.width / 2,
        size.height - 20);
    path.quadraticBezierTo(size.width * 3 / 4, size.height - 40, size.width,
        size.height - 20);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class TabBarSection extends StatefulWidget {
  final String token;

  const TabBarSection({super.key, required this.token});

  @override
  _TabBarSectionState createState() => _TabBarSectionState();
}

class _TabBarSectionState extends State<TabBarSection>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Saved'),
            Tab(text: 'History'),
          ],
        ),
        Container(
          height: 300,
          child: TabBarView(
            controller: _tabController,
            children: [
              ProductTabScreen(
                token: widget.token,
                apiUrl: "http://localhost:8080/product/Saved",
              ),
              const Center(
                child: Text('No history available',
                    style: TextStyle(color: Colors.black)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
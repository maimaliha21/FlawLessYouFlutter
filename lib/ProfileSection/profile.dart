import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:FlawlessYou/ProfileSection/editProfile.dart';
import 'package:FlawlessYou/ProfileSection/supportTeam.dart';
import 'package:FlawlessYou/api/google_signin_api.dart';
import 'package:FlawlessYou/LogIn/login.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:FlawlessYou/Product/productPage.dart';
import 'dart:convert';
import 'package:FlawlessYou/Card/Card.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http_parser/http_parser.dart';

import '../CustomBottomNavigationBar.dart';
import '../FaceAnalysisManager.dart';
import '../Home_Section/home.dart';
import '../Product/product.dart';
import '../Routinebar/routinescreen.dart';
import '../model/SkinAnalysisHistoryScreen.dart';
import '../model/SkinDetailsScreen.dart';
import 'aboutUs.dart';

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
  String? _baseUrl;
  String? _skinType;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadBaseUrl();
    _loadSkinType();
  }

  Future<void> _loadBaseUrl() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _baseUrl = prefs.getString('baseUrl') ?? '';
    });
  }

  Future<void> _loadSkinType() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _skinType = prefs.getString('skinType');
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        final file = File(image.path);
        final fileSize = await file.length();
        const maxSize = 5 * 1024 * 1024; // 5MB

        if (fileSize > maxSize) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image size too large (max 5MB)')),
          );
          return;
        }

        setState(() {
          _profileImage = file;
        });
        await _uploadProfilePicture(_profileImage!);
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: ${e.toString()}')),
      );
    }
  }

  Future<void> _uploadProfilePicture(File imageFile) async {
    if (_baseUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Base URL is not available')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/api/users/profilePicture'),
      );

      request.headers.addAll({
        'Authorization': 'Bearer ${widget.token}',
        'Accept': 'application/json',
      });

      final mimeType = _getMimeType(imageFile.path);
      final fileExtension = imageFile.path.split('.').last.toLowerCase();

      var multipartFile = await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
        filename: 'profile_${DateTime.now().millisecondsSinceEpoch}.$fileExtension',
        contentType: MediaType('image', fileExtension),
      );

      request.files.add(multipartFile);

      print('Uploading profile picture to: $_baseUrl/api/users/profilePicture');
      print('File details: ${imageFile.path}, size: ${imageFile.lengthSync()} bytes');

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var jsonResponse = jsonDecode(responseData);

      print('Response status: ${response.statusCode}');
      print('Response body: $responseData');

      if (response.statusCode == 200) {
        setState(() {
          widget.userInfo['profilePicture'] = jsonResponse['url'];
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(jsonResponse['message'] ?? 'Profile picture updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(jsonResponse['message'] ?? 'Failed to upload profile picture'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error uploading profile picture: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  String _getMimeType(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'jpeg';
      case 'png':
        return 'png';
      case 'gif':
        return 'gif';
      default:
        return 'jpg';
    }
  }

  void _showSkinTypeResult(BuildContext context, String skinType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('نتيجة تحليل نوع البشرة'),
        content: Text('نوع بشرتك هو: $skinType'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('حسناً'),
          ),
        ],
      ),
    );
  }

  void _handleLogout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('userInfo');

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
          (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: screenHeight * 0.25,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(
                          'https://res.cloudinary.com/davwgirjs/image/upload/v1740417378/nhndev/product/320aee5f-ac8b-48be-94c7-e9296259cf99_1740417378981_bgphoto.jpg.jpg'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  top: 30,
                  right: 20,
                  child: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'logout') {
                        _handleLogout();
                      } else if (value == 'support') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => SupportTeam()),
                        );
                      } else if (value == 'about_us') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => aboutUs()),
                        );
                      } else if (value == 'skin_type') {
                        if (_skinType != null) {
                          _showSkinTypeResult(context, _skinType!);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('No skin type analysis available')),
                          );
                        }
                      }
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
                        value: 'skin_type',
                        child: Text('Skin Type Analysis'),
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
                  top: screenHeight * 0.18,
                  left: screenWidth / 2 - (screenWidth * 0.15),
                  child: GestureDetector(
                    onTap: () => showDialog(
                      context: context,
                      builder: (context) => Dialog(
                        backgroundColor: Colors.transparent,
                        child: Stack(
                          children: [
                            Container(
                              width: 300,
                              height: 200,
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
                                onPressed: _isUploading
                                    ? null
                                    : () => _pickImage(ImageSource.gallery),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFB0BEC5),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 50, vertical: 15),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: _isUploading
                                    ? const CircularProgressIndicator(color: Colors.white)
                                    : const Text('Change Picture'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    child: CircleAvatar(
                      radius: screenWidth * 0.15,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: screenWidth * 0.14,
                        backgroundColor: Colors.white,
                        child: CircleAvatar(
                          radius: screenWidth * 0.13,
                          backgroundImage: _getProfileImage(),
                          child: _isUploading
                              ? Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(color: Colors.white),
                            ),
                          )
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 60),
            Text(
              widget.userInfo['userName'] ?? 'User',
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
                      builder: (context) => EditProfile(
                        token: widget.token,
                      ),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF88A383),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 37, vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text('Edit profile'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RoutineScreen(),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF88A383),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text('View Routine'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TabBarSection(token: widget.token, baseUrl: _baseUrl),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar2(),
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

class TabBarSection extends StatefulWidget {
  final String token;
  final String? baseUrl;

  const TabBarSection({super.key, required this.token, this.baseUrl});

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
          labelColor: Color(0xFF88A383),
          unselectedLabelColor: Colors.grey,
          indicatorColor: Color(0xFF88A383),
          indicatorWeight: 3.0,
          tabs: const [
            Tab(text: 'Saved'),
            Tab(text: 'History'),
          ],
        ),
        Container(
          height: MediaQuery.of(context).size.height * 0.40,
          child:TabBarView(
            controller: _tabController,
            children: [
              widget.baseUrl != null
                  ? ProductTabScreen(
                apiUrl: '${widget.baseUrl}/product/Saved',
                pageName: 'home',
              )
                  : Center(child: CircularProgressIndicator()),
              const Center(
                child: SkinAnalysisHistoryScreen(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
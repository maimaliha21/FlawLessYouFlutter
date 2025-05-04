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
        title: Text('Skin Type Result'),
        content: Text('Your skin type is: $skinType'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth >= 600;
        final avatarRadius = isTablet ? constraints.maxWidth * 0.1 : constraints.maxWidth * 0.15;
        final headerHeight = isTablet ? constraints.maxHeight * 0.15 : constraints.maxHeight * 0.2;
        final buttonPadding = isTablet ? EdgeInsets.symmetric(horizontal: 20, vertical: 12) :
        EdgeInsets.symmetric(horizontal: constraints.maxWidth * 0.05, vertical: constraints.maxHeight * 0.015);
        final buttonTextSize = isTablet ? 16.0 : 14.0;
        final userNameSize = isTablet ? 24.0 : 20.0;
        final emailSize = isTablet ? 18.0 : 16.0;

        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                // Header Section with Profile Picture
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      height: headerHeight,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(
                              'https://res.cloudinary.com/davwgirjs/image/upload/v1740417378/nhndev/product/320aee5f-ac8b-48be-94c7-e9296259cf99_1740417378981_bgphoto.jpg.jpg'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
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
                      top: headerHeight - avatarRadius,
                      left: constraints.maxWidth / 2 - avatarRadius,
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
                          radius: avatarRadius,
                          backgroundColor: Colors.white,
                          child: CircleAvatar(
                            radius: avatarRadius - 5,
                            backgroundColor: Colors.white,
                            child: CircleAvatar(
                              radius: avatarRadius - 10,
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

                // User Info Section
                SizedBox(height: avatarRadius * 0.9),
                Column(
                  children: [
                    Text(
                      widget.userInfo['userName'] ?? 'User',
                      style: TextStyle(
                          fontSize: userNameSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.black),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      widget.userInfo['email'] ?? '',
                      style: TextStyle(fontSize: emailSize, color: Colors.grey),
                    ),
                    if (widget.userInfo['skinType'] != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Skin Type: ${widget.userInfo['skinType']}',
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ],
                ),

                // Buttons Section
                SizedBox(height: constraints.maxHeight * 0.03),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: constraints.maxWidth * 0.1),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Flexible(
                        child: ElevatedButton(
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
                            padding: buttonPadding,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            minimumSize: Size(constraints.maxWidth * 0.3, 0),
                          ),
                          child: Text('Edit profile', style: TextStyle(fontSize: buttonTextSize)),
                        ),
                      ),
                      SizedBox(width: constraints.maxWidth * 0.05),
                      Flexible(
                        child: ElevatedButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RoutineScreen(),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF88A383),
                            foregroundColor: Colors.white,
                            padding: buttonPadding,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            minimumSize: Size(constraints.maxWidth * 0.3, 0),
                          ),
                          child: Text('View Routine', style: TextStyle(fontSize: buttonTextSize)),
                        ),
                      ),
                    ],
                  ),
                ),

                // Tab Bar Section at the bottom
                Expanded(
                  child: Column(
                    children: [
                      SizedBox(height: constraints.maxHeight * 0.03),
                      Expanded(
                        child: DefaultTabController(
                          length: 2,
                          child: Column(
                            children: [
                              TabBar(
                                labelColor: Color(0xFF88A383),
                                unselectedLabelColor: Colors.grey,
                                indicatorColor: Color(0xFF88A383),
                                indicatorWeight: 3.0,
                                labelStyle: TextStyle(fontSize: isTablet ? 16 : 14),
                                tabs: const [
                                  Tab(text: 'Saved'),
                                  Tab(text: 'History'),
                                ],
                              ),
                              Expanded(
                                child: TabBarView(
                                  children: [
                                    _baseUrl != null
                                        ? ProductTabScreen(
                                      apiUrl: '${_baseUrl}/product/Saved',
                                      pageName: 'home',
                                    )
                                        : Center(child: CircularProgressIndicator()),
                                    SkinAnalysisHistoryScreen(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: CustomBottomNavigationBar2(),
        );
      },
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
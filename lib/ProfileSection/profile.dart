import 'package:FlawlwssYou/ProfileSection/supportTeam.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../Card/Card.dart';
import '../CustomBottomNavigationBar.dart';
import '../Home_Section/home.dart';
import '../LogIn/login.dart';
import '../Product/product.dart';
import '../Product/productPage.dart';
import '../Routinebar/routinescreen.dart';
import '../model/SkinDetailsScreen.dart';
import 'aboutUs.dart';
import 'editProfile.dart';

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

  @override
  void initState() {
    super.initState();
    _loadBaseUrl();
  }

  Future<void> _loadBaseUrl() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _baseUrl = prefs.getString('baseUrl') ?? 'https://44c2-5-43-193-232.ngrok-free.app';
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        print('Selected file: ${image.path}, MIME type: ${image.mimeType}');
        if (image.mimeType?.startsWith('image/') ?? false) {
          setState(() {
            _profileImage = File(image.path);
          });
          await _uploadProfilePicture(_profileImage!);
          // await _analyzeSkinType(_profileImage!);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a valid image file')),
          );
        }
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
    if (_baseUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Base URL is not available')),
      );
      return;
    }

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/api/users/profilePicture'),
      );

      request.headers.addAll({
        'Authorization': 'Bearer ${widget.token}',
      });

      var multipartFile = await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
        filename: imageFile.path.split('/').last,
      );

      request.files.add(multipartFile);

      print('Sending request with file: ${imageFile.path}');

      var response = await request.send();

      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var jsonResponse = jsonDecode(responseData);

        setState(() {
          widget.userInfo['profilePicture'] = jsonResponse['url'];
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated successfully')),
        );
      } else {
        var errorResponse = await response.stream.bytesToString();
        print('Error response: $errorResponse');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload profile picture: $errorResponse')),
        );
      }
    } catch (e) {
      print('Error uploading profile picture: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload profile picture: $e')),
      );
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

  void _showImagePickerOptions(BuildContext context) async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await showModalBottomSheet<XFile>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.camera),
                title: Text('التقاط صورة من الكاميرا'),
                onTap: () async {
                  final XFile? image = await _picker.pickImage(source: ImageSource.camera);
                  Navigator.pop(context, image);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('تحميل صورة من المعرض'),
                onTap: () async {
                  final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                  Navigator.pop(context, image);
                },
              ),
            ],
          ),
        );
      },
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
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 250,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage('https://res.cloudinary.com/davwgirjs/image/upload/v1740417378/nhndev/product/320aee5f-ac8b-48be-94c7-e9296259cf99_1740417378981_bgphoto.jpg.jpg'),
                      fit: BoxFit.cover,
                    ),
                  ),),
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
                        child: Text('Show Skin Type'),
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
                                onPressed: null,
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
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>  RoutineScreen(),
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

class CustomBottomNavigationBar extends StatefulWidget {
  final String token;
  final Map<String, dynamic> userInfo;

  const CustomBottomNavigationBar({
    super.key,
    required this.token,
    required this.userInfo,
  });

  @override
  _CustomBottomNavigationBarState createState() => _CustomBottomNavigationBarState();
}

class _CustomBottomNavigationBarState extends State<CustomBottomNavigationBar> {
  String selectedSkinType = 'Failed to analyze skin type'; // القيمة الافتراضية

  Future<String> _analyzeSkinType(File imageFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://192.168.60.114:8000/analyze/'),
      );

      request.files.add(
        await http.MultipartFile.fromPath(
          'skin_type',
          imageFile.path,
        ),
      );

      var response = await request.send();

      if (response.statusCode == 200) {
        // حول الـ StreamedResponse لـ String
        final responseData = await response.stream.bytesToString();

        // حول الـ JSON لـ Map
        final jsonResponse = jsonDecode(responseData);

        // استخرج قيمة skin_type
        String skinType = jsonResponse['skin_type'];

        // أرجع القيمة
        return skinType;
      } else {
        print('Failed to analyze skin type1: ${response.statusCode}');
        return 'Failed to analyze skin type2'; // Default to 'Normal' on failure
      }
    } catch (e) {
      print('Error analyzing skin type: $e');
      return e.toString(); // Default to 'Normal' on error
    }
  }

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
            onPressed: () => _showImagePickerOptions(context),
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
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Home(
                          token: widget.token,
                        ),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.chat, color: Colors.blue),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MessageCard(token: widget.token),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 60),
                IconButton(
                  icon: const Icon(Icons.settings, color: Colors.blue),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductPage(token: widget.token, userInfo: widget.userInfo),
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

  void _showImagePickerOptions(BuildContext context) async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await showModalBottomSheet<XFile>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.camera),
                title: Text('التقاط صورة من الكاميرا'),
                onTap: () async {
                  final XFile? image = await _picker.pickImage(source: ImageSource.camera);
                  Navigator.pop(context, image);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('تحميل صورة من المعرض'),
                onTap: () async {
                  final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                  Navigator.pop(context, image);
                },
              ),
            ],
          ),
        );
      },
    );

    if (image != null) {
      _showImagePreviewDialog(context, File(image.path));
    }
  }
  void _showImagePreviewDialog(BuildContext context, File imageFile) async {
    // تحليل نوع البشرة
    final skinType = await _analyzeSkinType(imageFile);

    // القائمة المنسدلة تحتوي على النوع الذي تم تحليله بالإضافة إلى الخيارات الأخرى
    List<String> skinTypes = [skinType, 'Normal', 'Dry', 'Oily'];
    String selectedSkinType = skinType; // القيمة الافتراضية

    // عرض البوب-أب مع الصورة ونتيجة التحليل
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.file(imageFile), // عرض الصورة
            const SizedBox(height: 20),
            Text(
              'نوع بشرتك هو: $skinType', // عرض نتيجة التحليل
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            DropdownButton<String>(
              value: selectedSkinType,
              onChanged: (String? newValue) {
                setState(() {
                  selectedSkinType = newValue!;
                });
              },
              items: skinTypes.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // إغلاق البوب-أب
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SkinDetailsScreen(
                      imageFile: imageFile,
                      skinType: selectedSkinType, // تمرير القيمة المختارة
                    ),
                  ),
                );
              },
              child: const Text('التالي'),
            ),
          ],
        ),
      ),
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
                apiUrl: widget.baseUrl != null
                    ? '${widget.baseUrl}/product/Saved'
                    : '', pageName: 'home',
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
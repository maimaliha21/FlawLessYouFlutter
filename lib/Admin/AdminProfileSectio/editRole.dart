import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'User Filter App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: UserFilterPage(),
    );
  }
}

class UserFilterPage extends StatefulWidget {
  @override
  _UserFilterPageState createState() => _UserFilterPageState();
}

class _UserFilterPageState extends State<UserFilterPage> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _users = [];
  Map<String, String?> _selectedRoles = {}; // لتخزين الرول المحدد لكل مستخدم

  Future<Object> _getUserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userInfoJson = prefs.getString('token');
    if (userInfoJson != null) {
      return userInfoJson;
    }
    return {};
  }

  Future<void> _searchUsers() async {
    final userInfo = await _getUserInfo();
    final token = userInfo;

    final response = await http.get(
      Uri.parse('http://localhost:8080/api/users/Search/username?username=${_searchController.text}'),
      headers: {
        'accept': '*/*',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        _users = jsonDecode(response.body);
        _selectedRoles = {}; // إعادة تعيين الأدوار المحددة عند البحث
      });
    } else {
      throw Exception('Failed to load users');
    }
  }

  Future<void> _updateUserRole(String userId, String newRole) async {
    final userInfo = await _getUserInfo();
    final token = userInfo;

    final response = await http.put(
      Uri.parse('http://localhost:8080/api/users/$userId/role?newRole=$newRole'),
      headers: {
        'accept': '*/*',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Role updated successfully')));
    } else {
      throw Exception('Failed to update role');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Filter'),
        backgroundColor: Colors.transparent, // جعل شريط التطبيق شفافًا
        elevation: 0, // إزالة الظل
      ),
      extendBodyBehindAppBar: true, // لجعل الخلفية تمتد خلف شريط التطبيق
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(
              'https://res.cloudinary.com/davwgirjs/image/upload/v1740399050/nhndev/product/Atn5pCQF7VR4KhJCzI4g_1740399048265_005bdf0b-38be-4cbd-a016-f0c574659898.jpg.jpg',
            ),
            fit: BoxFit.cover,
          ),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: Column(
            children: [
              // العنوان وحقل البحث
              Padding(
                padding: const EdgeInsets.only(top: 100.0, left: 16.0, right: 16.0), // تباعد من الأعلى
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'User Filter',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16), // مسافة بين العنوان وحقل البحث
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              labelText: 'Search by username',
                              filled: true,
                              fillColor: Colors.black.withOpacity(0.5), // خلفية سوداء شفافة
                              labelStyle: TextStyle(color: Colors.white), // لون النص الأبيض
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                            ),
                            style: TextStyle(color: Colors.white), // لون النص الأبيض
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.search, color: Colors.white), // لون الأيقونة أبيض
                          onPressed: _searchUsers,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10.0), // زوايا مستديرة
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                          child: Container(
                            color: Colors.black.withOpacity(0.5), // خلفية سوداء شفافة
                            child: ListTile(
                              title: Text(
                                user['userName'],
                                style: TextStyle(color: Colors.white), // لون النص الأبيض
                              ),
                              trailing: DropdownButton<String>(
                                value: _selectedRoles[user['id']],
                                hint: Text(
                                  'Select Role',
                                  style: TextStyle(color: Colors.white), // لون النص الأبيض
                                ),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _selectedRoles[user['id']] = newValue;
                                  });
                                  _updateUserRole(user['id'], newValue!);
                                },
                                dropdownColor: Colors.black.withOpacity(0.8), // خلفية القائمة المنسدلة
                                items: <String>['USER', 'SKIN_EXPERT', 'ADMIN']
                                    .map<DropdownMenuItem<String>>((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(
                                      value,
                                      style: TextStyle(color: Colors.white), // لون النص الأبيض
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
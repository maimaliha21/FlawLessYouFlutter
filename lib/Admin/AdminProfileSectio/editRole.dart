import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../../Card/Card.dart';
import '../../CustomBottomNavigationBarAdmin.dart';
import '../../Home_Section/home.dart';
import '../../Product/productPage.dart';

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
  Map<String, String?> _selectedRoles = {};

  // دالة لاسترجاع الرابط من SharedPreferences
  Future<String> getBaseUrl() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('baseUrl') ?? ''; // قيمة افتراضية إذا لم يتم العثور على الرابط
  }

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
    final baseUrl = await getBaseUrl(); // استرجاع الرابط من SharedPreferences

    final response = await http.get(
      Uri.parse('$baseUrl/api/users/Search/username?username=${_searchController.text}'),
      headers: {
        'accept': '*/*',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        _users = jsonDecode(response.body);
        _selectedRoles = {};
        for (var user in _users) {
          _selectedRoles[user['id']] = user['role'];
        }
      });
    } else {
      throw Exception('Failed to load users');
    }
  }

  Future<void> _updateUserRole(String userId, String newRole) async {
    final userInfo = await _getUserInfo();
    final token = userInfo;
    final baseUrl = await getBaseUrl(); // استرجاع الرابط من SharedPreferences

    final response = await http.put(
      Uri.parse('$baseUrl/api/users/$userId/role?newRole=$newRole'),
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
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(
              'https://res.cloudinary.com/davwgirjs/image/upload/v1742412083/nhndev/product/dacbcfa8-1768-4c1e-8a7d-736c4e20b0c6_1742412081693_roleBg.jpg.jpg',
            ),
            fit: BoxFit.cover,
          ),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 100.0, left: 16.0, right: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'User Filter',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              labelText: 'Search by username',
                              filled: true,
                              fillColor: Colors.black.withOpacity(0.5),
                              labelStyle: TextStyle(color: Colors.white),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white),
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.blue),
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                            ),
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        SizedBox(width: 10),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: IconButton(
                            icon: Icon(Icons.search, color: Colors.white),
                            onPressed: _searchUsers,
                          ),
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
                        borderRadius: BorderRadius.circular(10.0),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                          child: Container(
                            color: Colors.black.withOpacity(0.5),
                            child: ListTile(
                              title: Text(
                                user['userName'],
                                style: TextStyle(color: Colors.white, fontSize: 18),
                              ),
                              trailing: DropdownButton<String>(
                                value: _selectedRoles[user['id']],
                                hint: Text(
                                  'Select Role',
                                  style: TextStyle(color: Colors.white),
                                ),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _selectedRoles[user['id']] = newValue;
                                  });
                                  _updateUserRole(user['id'], newValue!);
                                },
                                dropdownColor: Colors.black.withOpacity(0.8),
                                items: <String>['USER', 'SKIN_EXPERT', 'ADMIN']
                                    .map<DropdownMenuItem<String>>((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(
                                      value,
                                      style: TextStyle(color: Colors.white),
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
    bottomNavigationBar: CustomBottomNavigationBarAdmin(),);
  }
}


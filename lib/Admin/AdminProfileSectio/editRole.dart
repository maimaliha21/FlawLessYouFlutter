import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';
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
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(
              'https://res.cloudinary.com/davwgirjs/image/upload/v1740398445/nhndev/product/Atn5pCQF7VR4KhJCzI4g_1740398442198_aboutusbg.jpg.jpg',
            ),
            fit: BoxFit.cover,
          ),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          labelText: 'Search by username',
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.search),
                      onPressed: _searchUsers,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    return Card(
                      margin: EdgeInsets.all(8.0),
                      color: Colors.white.withOpacity(0.8),
                      child: ListTile(
                        title: Text(user['userName']),
                        trailing: DropdownButton<String>(
                          value: _selectedRoles[user['id']],
                          hint: Text('Select Role'),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedRoles[user['id']] = newValue;
                            });
                            _updateUserRole(user['id'], newValue!);
                          },
                          items: <String>['USER', 'SKIN_EXPERT', 'ADMIN']
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
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
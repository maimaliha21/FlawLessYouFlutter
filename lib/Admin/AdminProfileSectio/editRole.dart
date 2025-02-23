import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class UserFilterPage extends StatefulWidget {
  @override
  _UserFilterPageState createState() => _UserFilterPageState();
}

class _UserFilterPageState extends State<UserFilterPage> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _users = [];
  String? _selectedRole;

  Future<Map<String, dynamic>> _getUserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userInfoJson = prefs.getString('userInfo');
    if (userInfoJson != null) {
      return jsonDecode(userInfoJson);
    }
    return {};
  }

  Future<void> _searchUsers() async {
    final userInfo = await _getUserInfo();
    final token = userInfo['token'];

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
      });
    } else {
      throw Exception('Failed to load users');
    }
  }

  Future<void> _updateUserRole(String userId, String newRole) async {
    final userInfo = await _getUserInfo();
    final token = userInfo['token'];

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
      body: Column(
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
                  child: ListTile(
                    title: Text(user['userName']),
                    trailing: DropdownButton<String>(
                      value: _selectedRole,
                      hint: Text('Select Role'),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedRole = newValue;
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
    );
  }
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';

import '../CustomBottomNavigationBar.dart';
import '../FaceAnalysisManager.dart';
import '../Home_Section/home.dart';
import '../Product/productPage.dart';
import '../ProfileSection/profile.dart';
import '../model/SkinDetailsScreen.dart';

class MessageCard extends StatefulWidget {
  final String token;

  const MessageCard({super.key, required this.token});

  @override
  _MessageCardState createState() => _MessageCardState();
}

class _MessageCardState extends State<MessageCard> {
  String? selectedExpert;
  List<String> experts = [];
  List<dynamic> cards = [];
  final TextEditingController messageController = TextEditingController();

  Future<String> getBaseUrl() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('baseUrl') ?? 'http://localhost:8080';
  }

  @override
  void initState() {
    super.initState();
    fetchExperts();
    fetchCards();
  }

  Future<void> fetchExperts() async {
    try {
      final baseUrl = await getBaseUrl();
      final response = await http.get(
        Uri.parse('$baseUrl/api/users/experts'),
        headers: {
          'accept': '*/*',
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          experts = data.map((expert) => expert.toString()).toList();
        });
      } else {
        throw Exception('Failed to load experts');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching experts: $e')),
      );
    }
  }

  Future<void> fetchCards() async {
    try {
      final baseUrl = await getBaseUrl();
      final response = await http.get(
        Uri.parse('$baseUrl/cards/user'),
        headers: {
          'accept': '*/*',
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          cards = data;
        });
      } else {
        throw Exception('Failed to load cards');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching cards: $e')),
      );
    }
  }

  Future<void> sendMessage() async {
    if (selectedExpert == null || messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select an expert and enter a message')),
      );
      return;
    }

    try {
      final baseUrl = await getBaseUrl();
      final response = await http.post(
        Uri.parse('$baseUrl/cards/send?message=${Uri.encodeComponent(messageController.text)}&name=${Uri.encodeComponent(selectedExpert!)}'),
        headers: {
          'accept': '*/*',
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Message sent successfully')),
        );
        fetchCards();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending message: $e')),
      );
    }
  }

  Future<void> sendMessageWithAnalysis() async {
    if (selectedExpert == null || messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select an expert and enter a message')),
      );
      return;
    }

    try {
      final baseUrl = await getBaseUrl();
      final response = await http.post(
        Uri.parse('$baseUrl/cards/sendWithAnalysis?message=${Uri.encodeComponent(messageController.text)}&name=${Uri.encodeComponent(selectedExpert!)}'),
        headers: {
          'accept': '*/*',
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Message sent successfully with skin analysis')),
        );
        fetchCards();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message with analysis')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending message with analysis: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Send Message to Expert', style: TextStyle(color: Colors.black87)),
        backgroundColor: const Color(0xFFC7C7BB),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(
              "https://res.cloudinary.com/davwgirjs/image/upload/v1740424863/nhndev/product/320aee5f-ac8b-48be-94c7-e9296259cf99_1740424863643_messagesCards.jpg.jpg",
            ),
            fit: BoxFit.cover,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // First Card
              Card(
                color: Colors.white.withOpacity(0.5),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      DropdownButton<String>(
                        value: selectedExpert,
                        hint: Text('Select Expert', style: TextStyle(color: Colors.black87)),
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedExpert = newValue;
                          });
                        },
                        items: experts.map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value, style: TextStyle(color: Colors.black87)),
                          );
                        }).toList(),
                      ),
                      SizedBox(height: 20),
                      TextField(
                        controller: messageController,
                        maxLines: 3,
                        style: TextStyle(color: Colors.black87),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          labelText: 'Message',
                          labelStyle: TextStyle(color: Colors.black87),
                        ),
                      ),
                      SizedBox(height: 16),
                      // Button for sending message without analysis
                      ElevatedButton(
                        onPressed: sendMessage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF88A383),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text('Send a message without skinAnalysis',
                            style: TextStyle(color: Colors.white)),
                      ),
                      SizedBox(height: 10),
                      // New button for sending message with analysis
                      ElevatedButton(
                        onPressed: sendMessageWithAnalysis,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6A8D73), // Different color
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text('Send with skin analysis',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: cards.length,
                  itemBuilder: (context, index) {
                    final card = cards[index];
                    return Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            card['isPressed'] = !(card['isPressed'] ?? false);
                          });
                        },
                        child: Card(
                          color: (card['isPressed'] ?? false)
                              ? Colors.grey[300]
                              : Colors.white.withOpacity(0.5),
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: ExpansionTile(
                            leading: Icon(Icons.message, color: const Color(0xFF88A383)),
                            title: Text(
                              card['message'],
                              style: TextStyle(color: Colors.black87),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              'Sent to: ${card['expertName'] ?? 'Unknown'}',
                              style: TextStyle(color: Colors.black54),
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Message:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      card['message'],
                                      style: TextStyle(color: Colors.black87),
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'Sent to: ${card['expertName'] ?? 'Unknown'}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    if (card['analysisDate'] != null) ...[
                                      SizedBox(height: 16),
                                      Text(
                                        'Includes skin analysis from: ${card['analysisDate']}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green[700],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
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
      bottomNavigationBar: CustomBottomNavigationBar2(),
    );
  }
}
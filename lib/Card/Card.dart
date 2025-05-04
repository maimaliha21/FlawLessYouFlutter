import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart'; // Added for date formatting

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
  final DateFormat _dateFormatter = DateFormat('yyyy-MM-dd HH:mm'); // Date formatter

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
        messageController.clear();
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
        messageController.clear();
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

  void navigateToSkinAnalysis(Map<String, dynamic> skinAnalysis) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SkinAnalysisDetailsPage(skinAnalysis: skinAnalysis),
      ),
    );
  }

  String _formatDateTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return _dateFormatter.format(dateTime.toLocal());
    } catch (e) {
      return dateTimeString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Send Message to Expert', style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
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
              // Message Composition Card
              Card(
                color: Colors.white.withOpacity(0.8),
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
                        dropdownColor: Colors.white,
                        icon: Icon(Icons.arrow_drop_down, color: Color(0xFF88A383)),
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
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: sendMessage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF88A383),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text('Send Message',
                                style: TextStyle(color: Colors.white)),
                          ),
                          ElevatedButton(
                            onPressed: sendMessageWithAnalysis,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF4A6F4A),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text('With Analysis',
                                style: TextStyle(color: Colors.white)),
                          ),
                        ],
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
                      child: Card(
                        color: Colors.white.withOpacity(0.8),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: ExpansionTile(
                          leading: Icon(Icons.message, color:Color(0xFF4A6F4A)),
                          title: Text(
                            card['message'],
                            style: TextStyle(color: Colors.black87),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            'Sent to: ${card['expertName'] ?? 'Unknown'} • ${_formatDateTime(card['sentDate'])}',
                            style: TextStyle(color: Colors.black54),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                                  if (card['expertReply'] != null && card['expertReply'].isNotEmpty) ...[
                                    SizedBox(height: 16),
                                    Text(
                                      'Expert Reply:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    ...card['expertReply'].map<Widget>((reply) {
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: Text(
                                          reply.toString(),
                                          style: TextStyle(color: Colors.black87),
                                        ),
                                      );
                                    }).toList(),
                                  ],
                                  if (card['skinAnalysis'] != null) ...[
                                    SizedBox(height: 16),
                                    Text(
                                      'Skin Analysis:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    ElevatedButton(
                                      onPressed: () => navigateToSkinAnalysis(card['skinAnalysis']),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Color(0xFF4A6F4A),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: Text(
                                        'View Skin Analysis',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
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

class SkinAnalysisDetailsPage extends StatelessWidget {
  final Map<String, dynamic> skinAnalysis;
  late final DateFormat _dateFormatter;

  SkinAnalysisDetailsPage({super.key, required this.skinAnalysis}) {
    _dateFormatter = DateFormat('yyyy-MM-dd HH:mm');
  }

  String _formatDateTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return _dateFormatter.format(dateTime.toLocal());
    } catch (e) {
      return dateTimeString;
    }
  }

  Color _getProblemColor(String problem) {
    switch (problem) {
      case 'ACNE':
        return Colors.red;
      case 'WRINKLES':
        return Colors.blue;
      case 'PIGMENTATION':
        return Colors.brown;
      case 'NORMAL':
        return Colors.green;
      default:
        return Colors.teal;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Skin Analysis Details'),
        backgroundColor:Color(0xFF88A383),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (skinAnalysis['imageUrl'] != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  skinAnalysis['imageUrl'],
                  height: 250,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Basic Information',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Divider(),
                    SizedBox(height: 8),
                    RowInfo(label: 'Created At:', value: _formatDateTime(skinAnalysis['createdAt'])),
                    RowInfo(label: 'Skin Type:', value: skinAnalysis['skintype']),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Skin Problems Analysis',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Divider(),
                    SizedBox(height: 8),
                    if (skinAnalysis['problems'] != null)
                      ...skinAnalysis['problems'].entries.map((e) =>
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    e.key,
                                    style: TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                ),
                                Text('${e.value}%'),
                                SizedBox(width: 8),
                                Expanded(
                                  flex: 3,
                                  child: LinearProgressIndicator(
                                    value: e.value / 100,
                                    backgroundColor: Colors.grey[200],
                                    color: _getProblemColor(e.key),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            if (skinAnalysis['treatmentId'] != null && skinAnalysis['treatmentId'].isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recommended Treatments',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Divider(),
                      SizedBox(height: 8),
                      ...skinAnalysis['treatmentId'].map<Widget>((treatment) =>
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (treatment['description'] != null)
                                  Text(
                                    treatment['description'],
                                    style: TextStyle(fontSize: 16),
                                  ),
                                if (treatment['productIds'] != null && treatment['productIds'].isNotEmpty)
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(height: 8),
                                      Text(
                                        'Recommended Products:',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      ...treatment['productIds'].entries.map((e) =>
                                          Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 4),
                                            child: Text('- ${e.value}'),
                                          ),
                                      ),
                                    ],
                                  ),
                                Divider(),
                              ],
                            ),
                          ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class RowInfo extends StatelessWidget {
  final String label;
  final String? value;

  const RowInfo({super.key, required this.label, this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value ?? 'Not specified',
              style: TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
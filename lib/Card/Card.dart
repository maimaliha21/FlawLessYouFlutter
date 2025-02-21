import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

  @override
  void initState() {
    super.initState();
    print('Token in MessageCard: ${widget.token}'); // تحقق من التوكن
    fetchExperts();
    fetchCards();
  }

  Future<void> fetchExperts() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:8080/api/users/experts'),
        headers: {
          'accept': '*/*',
          'Authorization': 'Bearer ${widget.token}', // إضافة التوكن إلى الرأس
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          experts = data.map((expert) => expert.toString()).toList();
        });
      } else {
        print('Error fetching experts: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to load experts');
      }
    } catch (e) {
      print('Error fetching experts: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching experts: $e')),
      );
    }
  }

  Future<void> fetchCards() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:8080/cards/user'),
        headers: {
          'accept': '*/*',
          'Authorization': 'Bearer ${widget.token}', // إضافة التوكن إلى الرأس
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          cards = data;
        });
      } else {
        print('Error fetching cards: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to load cards');
      }
    } catch (e) {
      print('Error fetching cards: $e');
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
      final response = await http.post(
        Uri.parse('http://localhost:8080/cards/send?message=${Uri.encodeComponent(messageController.text)}&name=${Uri.encodeComponent(selectedExpert!)}'),
        headers: {
          'accept': '*/*',
          'Authorization': 'Bearer ${widget.token}', // إضافة التوكن إلى الرأس
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Message sent successfully')),
        );
        fetchCards(); // تحديث القائمة بعد إرسال الرسالة
      } else {
        print('Error sending message: ${response.statusCode}');
        print('Response body: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message')),
        );
      }
    } catch (e) {
      print('Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending message: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Send Message to Expert'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    DropdownButton<String>(
                      value: selectedExpert,
                      hint: Text('Select Expert'),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedExpert = newValue;
                        });
                      },
                      items: experts.map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: messageController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Message',
                      ),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: sendMessage,
                      child: Text('Send'),
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
                  return Card(
                    child: ListTile(
                      title: Text(card['message']),
                      subtitle: Text('Sent on: ${card['sentDate']}'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
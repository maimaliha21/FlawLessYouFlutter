import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../../CustomBottomNavigationBar.dart';

class chatexpert extends StatefulWidget {
  const chatexpert({super.key});

  @override
  _MessageCardState createState() => _MessageCardState();
}

class _MessageCardState extends State<chatexpert> {
  List<dynamic> cards = [];
  final TextEditingController replyController = TextEditingController();
  String? token;

  Future<String> getBaseUrl() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('baseUrl') ?? '';
  }

  Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  @override
  void initState() {
    super.initState();
    fetchTokenAndCards();
  }

  Future<void> fetchTokenAndCards() async {
    token = await getToken();
    if (token != null) {
      fetchExpertCards();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Token not found')),
      );
    }
  }

  Future<void> fetchExpertCards() async {
    try {
      final baseUrl = await getBaseUrl();
      final response = await http.get(
        Uri.parse('$baseUrl/cards/expert'),
        headers: {
          'accept': '*/*',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          cards = data;
        });
      } else {
        throw Exception('Failed to load expert cards');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching expert cards: $e')),
      );
    }
  }

  Future<void> replyToCard(String cardId, String reply) async {
    try {
      final baseUrl = await getBaseUrl();
      final response = await http.post(
        Uri.parse('$baseUrl/cards/$cardId/reply'),
        headers: {
          'accept': '*/*',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(reply),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reply sent successfully')),
        );
        fetchExpertCards();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send reply')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending reply: $e')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expert Messages', style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(
              "https://res.cloudinary.com/davwgirjs/image/upload/v1740424863/nhndev/product/320aee5f-ac8b-48be-94c7-e9296259cf99_1740424863643_messagesCards.jpg.jpg",
            ),
            fit: BoxFit.cover,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView.builder(
            itemCount: cards.length,
            itemBuilder: (context, index) {
              final card = cards[index];
              return Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Card(
                  color: Colors.white.withOpacity(0.5),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: ExpansionTile(
                    leading: Icon(Icons.message, color: Colors.teal[300]),
                    title: Text(
                      card['message'],
                      style: const TextStyle(color: Colors.black87),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      'Sent by: ${card['senderName']}',
                      style: const TextStyle(color: Colors.black54),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Message:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              card['message'],
                              style: const TextStyle(color: Colors.black87),
                            ),
                            const SizedBox(height: 16),
                            if (card['expertReply'] != null)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Expert Reply:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    card['expertReply'].join('\n'),
                                    style: const TextStyle(color: Colors.black87),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                const Text(
                                  'Skin Analysis: ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  card['skinAnalysis'] != null ? 'Available' : 'Not available',
                                  style: const TextStyle(color: Colors.black87),
                                ),
                              ],
                            ),
                            if (card['skinAnalysis'] != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: ElevatedButton(
                                  onPressed: () => navigateToSkinAnalysis(card['skinAnalysis']),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.teal[300],
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    'View Skin Analysis',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: replyController,
                              maxLines: 3,
                              style: const TextStyle(color: Colors.black87),
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                labelText: 'Reply',
                                labelStyle: const TextStyle(color: Colors.black87),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                final reply = replyController.text;
                                if (reply.isNotEmpty) {
                                  replyToCard(card['id'], reply);
                                  replyController.clear();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal[300],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Send Reply', style: TextStyle(color: Colors.white)),
                            ),
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
      ),
      bottomNavigationBar: const CustomBottomNavigationBar2(),
    );
  }
}

class SkinAnalysisDetailsPage extends StatelessWidget {
  final Map<String, dynamic> skinAnalysis;

  const SkinAnalysisDetailsPage({super.key, required this.skinAnalysis});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Skin Analysis Details'),
        backgroundColor: Colors.teal[300],
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
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Basic Information',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const Divider(),
                    const SizedBox(height: 8),

                    RowInfo(label: 'Created At:', value: skinAnalysis['createdAt']),
                    RowInfo(label: 'Skin Type:', value: skinAnalysis['skintype']),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Skin Problems Analysis',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const Divider(),
                    const SizedBox(height: 8),
                    if (skinAnalysis['problems'] != null)
                      ...skinAnalysis['problems'].entries.map((e) =>
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    e.key,
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                ),
                                Text('${e.value}%'),
                                const SizedBox(width: 8),
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
            const SizedBox(height: 20),
            if (skinAnalysis['treatmentId'] != null && skinAnalysis['treatmentId'].isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Recommended Treatments',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const Divider(),
                      const SizedBox(height: 8),
                      ...skinAnalysis['treatmentId'].map<Widget>((treatment) =>
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (treatment['description'] != null)
                                  Text(
                                    treatment['description'],
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                if (treatment['productIds'] != null && treatment['productIds'].isNotEmpty)
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 8),
                                      const Text(
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
                                const Divider(),
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
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value ?? 'Not specified',
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
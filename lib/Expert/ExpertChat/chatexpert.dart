import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../../Home_Section/home.dart';
import '../../Product/productPage.dart';

class chatexpert extends StatefulWidget {
  const chatexpert({super.key});

  @override
  _MessageCardState createState() => _MessageCardState();
}

class _MessageCardState extends State<chatexpert> {
  List<dynamic> cards = [];
  final TextEditingController replyController = TextEditingController();
  String? token;

  // دالة لاسترجاع الرابط من SharedPreferences
  Future<String> getBaseUrl() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('baseUrl') ?? '';
  }

  // دالة لاسترجاع التوكن من SharedPreferences
  Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  @override
  void initState() {
    super.initState();
    fetchTokenAndCards();
  }

  // جلب التوكن ثم جلب الكاردات الخاصة بالخبير
  Future<void> fetchTokenAndCards() async {
    token = await getToken();
    if (token != null) {
      fetchExpertCards();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Token not found')),
      );
    }
  }

  // جلب الكاردات الخاصة بالخبير
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

  // الرد على الكارد
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
          SnackBar(content: Text('Reply sent successfully')),
        );
        fetchExpertCards(); // إعادة جلب الكاردات بعد الرد
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send reply')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending reply: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Expert Messages', style: TextStyle(color: Colors.black87)),
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
                      style: TextStyle(color: Colors.black87),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      'Sent by: ${card['senderId'] ?? 'Unknown'}',
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
                            if (card['expertReply'] != null)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Expert Reply:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    card['expertReply'].join('\n'),
                                    style: TextStyle(color: Colors.black87),
                                  ),
                                ],
                              ),
                            SizedBox(height: 16),
                            TextField(
                              controller: replyController,
                              maxLines: 3,
                              style: TextStyle(color: Colors.black87),
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                labelText: 'Reply',
                                labelStyle: TextStyle(color: Colors.black87),
                              ),
                            ),
                            SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                final reply = replyController.text;
                                if (reply.isNotEmpty) {
                                  replyToCard(card['id'], reply);
                                  replyController.clear(); // مسح الحقل بعد الإرسال
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal[300],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text('Send Reply', style: TextStyle(color: Colors.white)),
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
      bottomNavigationBar: CustomBottomNavigationBar(
        userInfo: {}, // يمكنك تمرير معلومات المستخدم هنا إذا كانت متوفرة
      ),
    );
  }
}

class CustomBottomNavigationBar extends StatelessWidget {
  final Map<String, dynamic> userInfo;

  const CustomBottomNavigationBar({
    super.key,
    required this.userInfo,
  });

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
            onPressed: () {},
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
                  onPressed: () async {
                    final token = await SharedPreferences.getInstance().then((prefs) => prefs.getString('token'));
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Home(
                          token: token ?? '',
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
                        builder: (context) => chatexpert(),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 60),
                IconButton(
                  icon: const Icon(Icons.settings, color: Colors.blue),
                  onPressed: () async {
                    final token = await SharedPreferences.getInstance().then((prefs) => prefs.getString('token'));
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductPage(token: token ?? '', userInfo: userInfo),
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
}

class BottomWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 20);
    path.quadraticBezierTo(size.width / 4, size.height, size.width / 2, size.height - 20);
    path.quadraticBezierTo(3 / 4 * size.width, size.height - 40, size.width, size.height - 20);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
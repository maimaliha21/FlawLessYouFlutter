import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart'; // أضف هذه المكتبة

import '../Home_Section/home.dart';
import '../Product/productPage.dart'; // للوصول إلى ImageFilter

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

  // دالة لاسترجاع الرابط من SharedPreferences
  Future<String> getBaseUrl() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('baseUrl') ?? 'http://localhost:8080'; // قيمة افتراضية إذا لم يتم العثور على الرابط
  }

  @override
  void initState() {
    super.initState();
    fetchExperts();
    fetchCards();
  }

  Future<void> fetchExperts() async {
    try {
      final baseUrl = await getBaseUrl(); // استرجاع الرابط من SharedPreferences
      final response = await http.get(
        Uri.parse('$baseUrl/api/users/experts'), // استخدام الرابط المسترجع
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
      final baseUrl = await getBaseUrl(); // استرجاع الرابط من SharedPreferences
      final response = await http.get(
        Uri.parse('$baseUrl/cards/user'), // استخدام الرابط المسترجع
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
      final baseUrl = await getBaseUrl(); // استرجاع الرابط من SharedPreferences
      final response = await http.post(
        Uri.parse('$baseUrl/cards/send?message=${Uri.encodeComponent(messageController.text)}&name=${Uri.encodeComponent(selectedExpert!)}'), // استخدام الرابط المسترجع
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Send Message to Expert', style: TextStyle(color: Colors.black87)), // لون النص أسود
        backgroundColor: Colors.white, // لون خلفية AppBar أبيض
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
              // الكارد الأول
              Card(
                color: Colors.white.withOpacity(0.5), // جعل البوكس شفافًا قليلاً
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20), // جعل الحواف دائرية أكثر
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
                            borderRadius: BorderRadius.circular(12), // جعل حواف TextField دائرية
                          ),
                          labelText: 'Message',
                          labelStyle: TextStyle(color: Colors.black87),
                        ),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: sendMessage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal[300], // لون أخضر ضبابي
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12), // جعل حواف الزر دائرية
                          ),
                        ),
                        child: Text('Send', style: TextStyle(color: Colors.white)),
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
                      padding: const EdgeInsets.only(top: 10), // إنزال الكارد لأسفل قليلاً
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            // تغيير لون الكارد عند الضغط
                            card['isPressed'] = !(card['isPressed'] ?? false);
                          });
                        },
                        child: Card(
                          color: (card['isPressed'] ?? false)
                              ? Colors.grey[300] // لون أغمق عند الضغط
                              : Colors.white.withOpacity(0.5), // لون عادي
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20), // جعل الحواف دائرية أكثر
                          ),
                          child: ExpansionTile(
                            leading: Icon(Icons.message, color: Colors.teal[300]), // أيقونة زيتية
                            title: Text(
                              card['message'],
                              style: TextStyle(color: Colors.black87),
                              maxLines: 2, // عدد الأسطر القصوى قبل التوسيع
                              overflow: TextOverflow.ellipsis, // اختصار النص إذا كان طويلاً
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
      bottomNavigationBar: CustomBottomNavigationBar(
        token: widget.token,
        userInfo: {}, // يمكنك تمرير معلومات المستخدم هنا إذا كانت متوفرة
      ),
    );
  }
}

class CustomBottomNavigationBar extends StatelessWidget {
  final String token;
  final Map<String, dynamic> userInfo;

  const CustomBottomNavigationBar({
    super.key,
    required this.token,
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
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Home(
                          token: token,

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
                        builder: (context) => MessageCard(token: token),
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
                        builder: (context) => ProductPage(token: token, userInfo: userInfo),
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
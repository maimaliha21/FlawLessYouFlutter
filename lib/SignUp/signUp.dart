import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const CreateProfileScreen(),
    );
  }
}

class CreateProfileScreen extends StatefulWidget {
  const CreateProfileScreen({super.key});

  @override
  _CreateProfileScreenState createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends State<CreateProfileScreen> {
  bool isChecked = false;

  Future<void> _signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? account = await googleSignIn.signIn();
      if (account != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Signed in as ${account.email}')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing in with Google: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue.shade50,
      body: Stack(
        children: [
          // Enlarged Background Circles
          Positioned(
            top: -80,
            left: -80,
            child: CircleAvatar(
              radius: 150,
              backgroundColor: Colors.cyan.withOpacity(0.3),
            ),
          ),
          Positioned(
            top: 80,
            left: 80,
            child: CircleAvatar(
              radius: 120,
              backgroundColor: Colors.cyan.withOpacity(0.4),
            ),
          ),

          // Main Content
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Image at the top, centered
                    Image.asset(
                      'assets/p1.png',
                      width: 150, // Adjust the size as needed
                    ),
                    const SizedBox(height: 10),

                    // Text below the image
                    Text(
                      'Create your account',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 50),

                    // Form Container
                    Container(
                      width: 280,
                      child: Column(
                        children: [
                          _buildTextFieldContainer('Email', false),
                          const SizedBox(height: 10),
                          _buildTextFieldContainer('Phone Number', false),
                          const SizedBox(height: 10),
                          _buildTextFieldContainer('Password', true),
                          const SizedBox(height: 10),
                          _buildTextFieldContainer('Confirm Password', true),
                          const SizedBox(height: 15),

                          // Custom Checkbox Row inside the container
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                isChecked = !isChecked;
                              });
                            },
                            child: Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.grey.shade600),
                                    color: isChecked ? Colors.blue.shade700 : Colors.transparent,
                                  ),
                                  child: isChecked
                                      ? const Icon(Icons.check, color: Colors.white, size: 18)
                                      : null,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'I agree with and accept Privacy and Policy',
                                    style: GoogleFonts.poppins(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Sign Up Button inside the container
                          _buildButtonContainer('Sign Up', () {}),
                          const SizedBox(height: 15),

                          // "Or Sign Up With" text inside the container
                          Text(
                            'Or Sign Up With',
                            style: GoogleFonts.poppins(fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 15),
                          _buildGoogleSignInButton(context),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextFieldContainer(String hintText, bool isPassword) {
    return _buildTextField(hintText, isPassword);
  }

  Widget _buildTextField(String hintText, bool isPassword) {
    return TextField(
      obscureText: isPassword,
      style: GoogleFonts.poppins(fontSize: 14),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue.shade300, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }

  Widget _buildButtonContainer(String text, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: Colors.blue.shade700,
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildGoogleSignInButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _signInWithGoogle(context),
      child: Image.asset(
        'assets/google_logo.png',
        height: 40,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.error, color: Colors.red, size: 36);
        },
      ),
    );
  }
}

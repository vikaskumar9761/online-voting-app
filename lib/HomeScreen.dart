import 'dart:math';

import 'package:flutter/material.dart';
import 'package:online_voting/EmailVeryfiying/SignUp.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:online_voting/EmailVeryfiying/dasboard_screen.dart';
import 'package:online_voting/AdminScreen/adminScreen.dart';

class Homescreen extends StatefulWidget {
  const Homescreen({super.key});

  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> {
  // Firebase authentication instance
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Firebase Realtime Database reference for votes
  final DatabaseReference _voteRef = FirebaseDatabase.instance.ref().child('votes');

  // Controllers for email and password input fields
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passController = TextEditingController();

  // Loading state for login button
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    checkUserLoginStatus(); // Check login status when the screen initializes
  }

  // ✅ Check if the user is logged in and verify their voting status
  void checkUserLoginStatus() async {
    User? user = _auth.currentUser;
    await user?.reload(); // ✅ Refresh user data

    if (user != null && user.emailVerified) { // ✅ Check if email is verified
      bool hasVoted = await _checkUserVoted(user.uid);

      // ✅ Navigate to Dashboard Screen if logged in
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DasboardScreen(hasVoted: hasVoted),
          ),
        );
      });
    } else {
      // Show warning if email is not verified
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ Please verify your email first!")),
      );
    }
  }

  // ✅ Function to check if the user has already voted
  Future<bool> _checkUserVoted(String uid) async {
    DatabaseEvent event = await _voteRef.once();
    if (event.snapshot.value != null) {
      Map<dynamic, dynamic> votes = event.snapshot.value as Map<dynamic, dynamic>;

      // Check if user ID exists in any poll
      for (var poll in votes.entries) {
        if (poll.value is Map && poll.value.containsKey(uid)) {
          return true; // User has already voted
        }
      }
    }
    return false; // User has not voted
  }

  // ✅ Login function
  Future<void> login() async {
    setState(() {
      isLoading = true; // Show loading indicator
    });

    try {
      // Authenticate user using Firebase
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passController.text.trim(),
      );

      User? user = userCredential.user;
      await user?.reload(); // Refresh user data

      if (user != null && user.emailVerified) {
        bool hasVoted = await _checkUserVoted(user.uid);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ Successfully logged in!")),
        );

        // Navigate to Dashboard Screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => DasboardScreen(hasVoted: hasVoted)),
        );
      } else {
        // Show error message if email is not verified
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("⚠️ Please verify your email first!")),
        );
      }
    } catch (e) {
      // Show error message in case of login failure

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        isLoading = false; // Hide loading indicator
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Login"),
        actions: [
          // Admin screen button
          IconButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => Adminscreen()),
              );
            },
            icon: Icon(Icons.admin_panel_settings),
          ),
          SizedBox(width: 20),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Email input field
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: "Enter email",
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Password input field
              TextField(
                controller: passController,
                obscureText: true, // Hide password input
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Login and Sign-up buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Login button
                  ElevatedButton(
                    onPressed: login,
                    child: isLoading
                        ? CircularProgressIndicator(color: Colors.white) // Show loading indicator
                        : Text("Login"),
                  ),

                  // Sign-up button
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => SignUpScreen()),
                      );
                    },
                    child: Text("Sign Up"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

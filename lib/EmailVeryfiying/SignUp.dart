import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:online_voting/HomeScreen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // Controllers for user input
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passController = TextEditingController();
  final TextEditingController AadharController = TextEditingController();

  // Firebase Realtime Database reference for storing user info
  final DatabaseReference _userRef = FirebaseDatabase.instance.ref().child("users info");

  // Firebase Authentication instance
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool isLoading = false; // Loading state for sign-up button
  bool isEmailVerified = false; // Email verification status

  // ✅ Password reset function
  Future<void> ressetPass() async {
    try {
      await _auth.sendPasswordResetEmail(email: emailController.text.trim());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Password reset link sent! Check your email.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  // ✅ Sign-Up function
  Future<void> SignUp() async {
    if (isLoading) return; // Prevent multiple clicks

    setState(() {
      isLoading = true;
    });

    try {
      // Create a new user with email and password
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passController.text.trim(),
      );

      User? user = userCredential.user;
      String? uid = AadharController.text.trim();

      // ✅ Store user data in Firebase Realtime Database
      await _userRef.child(uid).set({
        "aadhar": AadharController.text.trim(),
        "email": emailController.text.trim(),
        "userId": user?.uid, // Firebase UID
        "createdAt": DateTime.now().toString(),
        "voteId": false, // Voting status (false means user has not voted)
      });

      // ✅ Send email verification
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Verification email sent! Please check your inbox.")),
        );

        // ✅ Call email verification check function
        await checkEmailVerification(user);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Online Voting"),
        actions: [
          // ✅ Password reset button
          IconButton(
            onPressed: ressetPass,
            icon: Icon(Icons.lock_reset),
            color: Colors.black,
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ✅ Sign Up title
                Row(
                  children: [
                    Container(
                      child: Text(
                        "Sign Up",
                        style: TextStyle(fontSize: 20, color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                    )
                  ],
                ),
                SizedBox(height: 30),

                // ✅ Aadhar Number Input Field
                TextField(
                  controller: AadharController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "Aadhar No.",
                    prefixIcon: Icon(Icons.perm_identity),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                SizedBox(height: 30),

                // ✅ Email Input Field
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: "Email",
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                SizedBox(height: 30),

                // ✅ Password Input Field
                TextField(
                  controller: passController,
                  obscureText: true, // Hide password
                  decoration: InputDecoration(
                    labelText: "Password",
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                SizedBox(height: 30),

                // ✅ Sign Up and Login Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // ✅ Sign Up Button
                    ElevatedButton(
                      onPressed: SignUp,
                      child: isLoading
                          ? CircularProgressIndicator(color: Colors.white) // Show loading indicator
                          : Text("Create"),
                    ),

                    // ✅ Login Button
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => Homescreen()),
                        );
                      },
                      child: Text("Login"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ Function to Check Email Verification
  Future<void> checkEmailVerification(User user) async {
    while (!user.emailVerified) {
      await Future.delayed(Duration(seconds: 3));
      await user.reload(); // Refresh user data
      user = FirebaseAuth.instance.currentUser!;
    }

    // ✅ If Email is Verified, Navigate to Home Screen
    if (user.emailVerified) {
      setState(() {
        isEmailVerified = true;
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Homescreen()),
      );
    }
  }
}

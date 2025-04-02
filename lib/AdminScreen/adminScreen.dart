import 'package:flutter/material.dart';
import 'package:online_voting/AdminScreen/admin_dasbord.dart';
import 'package:online_voting/HomeScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Adminscreen extends StatefulWidget {
  const Adminscreen({super.key});

  @override
  State<Adminscreen> createState() => _AdminscreenState();
}

class _AdminscreenState extends State<Adminscreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController emailCont = TextEditingController();
  final TextEditingController passCont = TextEditingController();
  bool isLoading = false;

  Future<void> admin() async {
    setState(() {
      isLoading = true;
    });
    var email = emailCont.text.trim();
    var pass = passCont.text.trim();
    if (email.isEmpty && pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please Enter User Id or Password")),
      );
    } else {
      try {
        await _auth.signInWithEmailAndPassword(email: email, password: pass);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => PollScreen()),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("error : ${e.toString()}")));
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Login Admin")),
      body: Container(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(
                  controller: emailCont,
                  decoration: InputDecoration(
                    labelText: 'User Id',
                    prefixIcon: Icon(Icons.add_moderator),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                SizedBox(height: 30),
                TextField(
                  controller: passCont,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton(
                      onPressed: admin,
                      child:
                          isLoading
                              ? CircularProgressIndicator(color: Colors.white)
                              : Text(" Login"),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => Homescreen()),
                        );
                      },
                      child: Text("back"),
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
}

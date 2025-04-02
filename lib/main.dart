import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:online_voting/AdminScreen/adminScreen.dart';
import 'package:online_voting/AdminScreen/admin_dasbord.dart';
import 'package:online_voting/EmailVeryfiying/dasboard_screen.dart';
import 'package:online_voting/firebase_options.dart';
import 'EmailVeryfiying/SignUp.dart';// OTP Login Page
import 'package:online_voting/HomeScreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform,);
  FirebaseDatabase.instance.ref().databaseURL = "https://people-731e5-default-rtdb.firebaseio.com/";
  runApp(MyApp());
}

extension on DatabaseReference {
  set databaseURL(String databaseURL) {}
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: Homescreen(),
    );
  }
}


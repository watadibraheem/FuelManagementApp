import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'מערכת ניהול תדלוק',
      theme: ThemeData(primarySwatch: Colors.amber, fontFamily: 'Arial'),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: LoginScreen(), // or your actual screen
      ),
    );
  }
}

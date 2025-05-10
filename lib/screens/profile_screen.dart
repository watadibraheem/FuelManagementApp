import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  final Map<String, dynamic>
  user; // contains user data like name, email, role, etc.
  final Dio dio;

  const ProfileScreen({super.key, required this.user, required this.dio});

  String translateRole(String role) {
    switch (role) {
      case 'admin':
        return 'מנהל תחנה';
      case 'user':
        return 'בעל מנוי';
      default:
        return 'תפקיד לא מזוהה';
    }
  }

  void logout(BuildContext context) {
    // Optional: clear Dio cookie jar if needed
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Widget buildField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("פרופיל"), centerTitle: true, 
        backgroundColor: const Color(0xFFFFD10D),
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFFFD10D),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Image.network(
              "http://10.0.2.2:8801/uploads/sunLogo.png",
              height: 130,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 20),
            buildField("שם מלא", user["name"] ?? ""),
            buildField("דוא\"ל", user["email"] ?? ""),
            buildField("טלפון", user["phone"] ?? ""),
            if (user["business_name"] != null)
              buildField("שם עסק", user["business_name"]),
            buildField("תפקיד", translateRole(user["role"])),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => logout(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                "🚪 התנתק",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

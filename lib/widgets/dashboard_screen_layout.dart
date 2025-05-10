import 'package:flutter/material.dart';

class DashboardScreenLayout extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? fab; // for floating action button like SubmitAbnormalFuel

  const DashboardScreenLayout({
    super.key,
    required this.title,
    required this.child,
    this.fab,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFD10D), // Yellow background
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFFFD10D),
        centerTitle: true,
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Image.network(
              "http://10.0.2.2:8801/uploads/sunLogo.png",
              width: 140,
              height: 140,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 10),
            const Text(
              "Sun ברוך הבא למערכת",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFFF57C00),
              ),
            ),
            const SizedBox(height: 30),
            child,
          ],
        ),
      ),
      floatingActionButton: fab,
    );
  }
}

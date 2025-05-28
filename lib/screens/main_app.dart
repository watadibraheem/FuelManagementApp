import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import 'dashboard/station_manager_dashboard.dart';
import 'dashboard/subscription_owner_dashboard.dart';
import 'profile_screen.dart';

class MainApp extends StatefulWidget {
  final Map<String, dynamic> user;
  final Dio dio;

  const MainApp({super.key, required this.user, required this.dio});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final role = widget.user["role"];

    if (role == "worker") {
      // shouldn't be here, redirect just in case
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pop(context);
      });
      return Scaffold();
    }

    final screens = [
      role == "admin"
          ? StationManagerDashboard(dio: widget.dio, user: widget.user)
          : SubscriptionOwnerDashboard(dio: widget.dio, user: widget.user),
      ProfileScreen(user: widget.user, dio: widget.dio),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'דף הבית',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'פרופיל',
          ),
        ],
        selectedItemColor: Color(0xFFFFD10D),
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}

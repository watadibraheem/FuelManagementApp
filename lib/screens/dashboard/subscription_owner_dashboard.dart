import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../requests/submit_abnormal_fuel.dart';
import '../logs/view_fuel_logs.dart';
import '../cards/manage_fuel_cards.dart';
import '../../widgets/dashboard_screen_layout.dart';

class SubscriptionOwnerDashboard extends StatelessWidget {
  final Dio dio;

  const SubscriptionOwnerDashboard({super.key, required this.dio});

  @override
  Widget build(BuildContext context) {
    return DashboardScreenLayout(
      title: "דף הבית",
      fab: FloatingActionButton(
        backgroundColor: Colors.orange,
        child: const Icon(Icons.local_gas_station),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SubmitAbnormalFuelScreen(dio: dio),
            ),
          );
        },
      ),
      child: Column(
        children: [
          buildButton(context, "יומני תדלוק", Icons.article, () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ViewFuelLogsScreen(dio: dio)),
            );
          }),
          buildButton(context, "ניהול כרטיסי תדלוק", Icons.credit_card, () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ManageFuelCardsScreen(dio: dio),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget buildButton(
    BuildContext context,
    String text,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: Colors.white),
        label: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF57C00),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 30),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          minimumSize: const Size(double.infinity, 60),
        ),
      ),
    );
  }
}

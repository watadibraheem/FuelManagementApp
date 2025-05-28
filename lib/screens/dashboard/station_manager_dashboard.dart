import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../cards/manage_card_requests.dart';
import '../requests/manage_abnormal_requests.dart';
import '../../widgets/dashboard_screen_layout.dart';
import '../logs/view_fuel_logs_grouped.dart';

class StationManagerDashboard extends StatelessWidget {
  final Dio dio;
  final Map<String, dynamic> user;

  const StationManagerDashboard({
    super.key,
    required this.dio,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return DashboardScreenLayout(
      title: "ניהול תחנה",
      child: Column(
        children: [
          buildButton(
            context,
            "אישור בקשות תדלוק חריגות",
            Icons.local_gas_station,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ManageAbnormalRequestsScreen(dio: dio),
                ),
              );
            },
          ),
          buildButton(context, "צפייה ביומני תדלוק", Icons.receipt_long, () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GroupedFuelLogsScreen(dio: dio, user: user),
              ),
            );
          }),
          buildButton(
            context,
            "ניהול בקשות כרטיסים",
            Icons.pending_actions,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ManageCardRequestsScreen(dio: dio),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget buildButton(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: Colors.white),
        label: Text(
          label,
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

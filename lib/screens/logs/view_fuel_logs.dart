import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class ViewFuelLogsScreen extends StatefulWidget {
  final Dio dio;

  const ViewFuelLogsScreen({super.key, required this.dio});

  @override
  State<ViewFuelLogsScreen> createState() => _ViewFuelLogsScreenState();
}

class _ViewFuelLogsScreenState extends State<ViewFuelLogsScreen>
    with TickerProviderStateMixin {
  List<dynamic> normalLogs = [];
  List<dynamic> abnormalLogs = [];
  bool isLoadingNormal = true;
  bool isLoadingAbnormal = true;
  String errorNormal = '';
  String errorAbnormal = '';

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchNormalLogs();
    fetchAbnormalLogs();
  }

  Future<void> fetchNormalLogs() async {
    try {
      final response = await widget.dio.get(
        "http://10.0.2.2:8801/fuel-requests/normal-logs",
      );

      if (response.statusCode == 200) {
        setState(() {
          normalLogs = response.data;
          isLoadingNormal = false;
        });
      } else {
        setState(() {
          errorNormal = 'נכשל בטעינת יומנים רגילים';
          isLoadingNormal = false;
        });
      }
    } catch (e) {
      setState(() {
        errorNormal = 'שגיאה: ${e.toString()}';
        isLoadingNormal = false;
      });
    }
  }

  Future<void> fetchAbnormalLogs() async {
    try {
      final response = await widget.dio.get(
        "http://10.0.2.2:8801/fuel-requests",
      );

      if (response.statusCode == 200) {
        setState(() {
          abnormalLogs = response.data;
          isLoadingAbnormal = false;
        });
      } else {
        setState(() {
          errorAbnormal = 'נכשל בטעינת יומנים חריגים';
          isLoadingAbnormal = false;
        });
      }
    } catch (e) {
      setState(() {
        errorAbnormal = 'שגיאה: ${e.toString()}';
        isLoadingAbnormal = false;
      });
    }
  }

  Widget buildLogCard(dynamic log, {bool isAbnormal = false}) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            buildLogRow("👤 נהג", log['driver_name'] ?? log['name'] ?? '---'),
            if (log['plate'] != null) buildLogRow("🚗 רכב", log['plate']),
            if (log['quantity'] != null)
              buildLogRow("⛽ כמות", "${log['quantity']} ליטר"),
            if (log['amount'] != null)
              buildLogRow("💰 סכום נדרש", "${log['amount']} ₪"),
            if (isAbnormal && log['completed_amount'] != null)
              buildLogRow("✅ סכום שבוצע", "${log['completed_amount']} ₪"),
            if (log['sale'] != null)
              buildLogRow("💸 מחיר סופי", "${log['sale']} ₪"),
            if (log['station'] != null) buildLogRow("🏢 תחנה", log['station']),
            if (log['timestamp'] != null)
              buildLogRow("🕒 תאריך", log['timestamp']),
            if (log['status'] != null) buildStatusBadge(log['status']),
          ],
        ),
      ),
    );
  }

  Widget buildLogRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }

  Widget buildStatusBadge(String status) {
    Color bgColor;
    switch (status) {
      case 'approved':
        bgColor = Colors.green;
        break;
      case 'rejected':
        bgColor = Colors.red;
        break;
      case 'auto-approved':
        bgColor = Colors.blue;
        break;
      case 'done':
        bgColor = Colors.grey;
        break;
      default:
        bgColor = Colors.orange;
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: Alignment.centerRight,
      child: Text(
        "סטטוס: $status",
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  Widget buildLogList(
    bool isLoading,
    String error,
    List logs, {
    required bool isAbnormal,
  }) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (error.isNotEmpty) return Center(child: Text(error));
    if (logs.isEmpty) return const Center(child: Text("אין יומנים להצגה"));

    return ListView(
      padding: const EdgeInsets.all(16),
      children:
          logs.map((log) => buildLogCard(log, isAbnormal: isAbnormal)).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF9C4),
        appBar: AppBar(
          backgroundColor: const Color(0xFFFFD10D),
          title: const Text(
            'יומני תדלוק',
            style: TextStyle(color: Colors.black),
          ),
          centerTitle: true,
          bottom: TabBar(
            controller: _tabController,
            labelColor: Colors.black,
            indicatorColor: Colors.orange,
            indicatorWeight: 3,
            tabs: const [Tab(text: 'רגיל'), Tab(text: 'חריג')],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            buildLogList(
              isLoadingNormal,
              errorNormal,
              normalLogs,
              isAbnormal: false,
            ),
            buildLogList(
              isLoadingAbnormal,
              errorAbnormal,
              abnormalLogs,
              isAbnormal: true,
            ),
          ],
        ),
      ),
    );
  }
}

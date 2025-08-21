import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class ManageAbnormalRequestsScreen extends StatefulWidget {
  final Dio dio;

  const ManageAbnormalRequestsScreen({super.key, required this.dio});

  @override
  State<ManageAbnormalRequestsScreen> createState() =>
      _ManageAbnormalRequestsScreenState();
}

class _ManageAbnormalRequestsScreenState
    extends State<ManageAbnormalRequestsScreen> {
  List<dynamic> requests = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchRequests();
  }

  Future<void> fetchRequests() async {
    try {
      final res = await widget.dio.get(
        "http://10.0.2.2:8801/fuel-requests/pending-approval",
      );

      final data = res.data;

      setState(() {
        requests = List.from(data);
        isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        showSnack("שגיאה בטעינת הבקשות", isError: true);
      }
    }
  }

  String formatLocalDate(String isoDate) {
    try {
      final local = DateTime.parse(isoDate);
      // final local = utc.toLocal();
      final formatted =
          "${local.year.toString().padLeft(4, '0')}/"
          "${local.month.toString().padLeft(2, '0')}/"
          "${local.day.toString().padLeft(2, '0')} "
          "${local.hour.toString().padLeft(2, '0')}:"
          "${local.minute.toString().padLeft(2, '0')}";
      return formatted;
    } catch (_) {
      return isoDate;
    }
  }

  Future<void> handleAction(int id, bool approve) async {
    final action = approve ? "approve" : "reject";
    try {
      await widget.dio.put("http://10.0.2.2:8801/fuel-requests/$action/$id");

      showSnack(
        approve ? "הבקשה אושרה בהצלחה" : "הבקשה נדחתה בהצלחה",
        isError: false,
      );

      setState(() {
        requests.removeWhere((r) => r["id"] == id);
      });
    } catch (e) {
      showSnack("שגיאה בביצוע הפעולה", isError: true);
    }
  }

  void showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, textDirection: TextDirection.rtl),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Widget buildRequestCard(dynamic r) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFFFFD10D),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            padding: const EdgeInsets.all(12),
            child: Text(
              "בקשת תדלוק חדשה 🚗",
              textDirection: TextDirection.rtl,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF3E2723),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                buildRow("👤 נהג", r['driver_name']),
                buildRow("🚗 רכב", r['plate']),
                buildRow("⛽ כמות", "${r['amount']} ₪"),
                buildRow("🏢 חברה", r['business_name']),
                buildRow("🕒 תאריך", formatLocalDate(r['created_at'])),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => handleAction(r["id"], true),
                        icon: const Icon(Icons.check),
                        label: const Text("אשר"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => handleAction(r["id"], false),
                        icon: const Icon(Icons.close),
                        label: const Text("דחה"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildRow(String label, String value) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("בקשות תדלוק חריג"),
        centerTitle: true,
        backgroundColor: const Color(0xFFFFD10D),
        foregroundColor: Colors.black,
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : requests.isEmpty
              ? const Center(
                child: Text(
                  "אין בקשות ממתינות כרגע 🚫",
                  style: TextStyle(fontSize: 16),
                ),
              )
              : RefreshIndicator(
                onRefresh: fetchRequests,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: requests.map(buildRequestCard).toList(),
                ),
              ),
    );
  }
}

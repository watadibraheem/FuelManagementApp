import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class ManageCardRequestsScreen extends StatefulWidget {
  final Dio dio;

  const ManageCardRequestsScreen({super.key, required this.dio});

  @override
  State<ManageCardRequestsScreen> createState() =>
      _ManageCardRequestsScreenState();
}

class _ManageCardRequestsScreenState extends State<ManageCardRequestsScreen> {
  List<dynamic> requests = [];
  Map<int, dynamic> oldCards = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchRequests();
  }

  Future<void> fetchRequests() async {
    try {
      final res = await widget.dio.get(
        "http://10.0.2.2:8801/cards/card-requests/pending",
      );
      final all = res.data;

      final cardsRes = await widget.dio.get("http://10.0.2.2:8801/cards");
      final cardMap = {for (var c in cardsRes.data) c["id"]: c};

      setState(() {
        requests = all;
        oldCards = Map<int, dynamic>.from(cardMap);
        isLoading = false;
      });
    } catch (e) {
      showSnackbar("שגיאה בטעינת הבקשות", true);
    }
  }

  void showSnackbar(String msg, bool isError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, textDirection: TextDirection.rtl),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> handleAction(int id, bool approve) async {
    try {
      final url =
          "http://10.0.2.2:8801/cards/card-requests/$id/${approve ? "approve" : "reject"}";
      await widget.dio.put(url);
      showSnackbar(approve ? "הבקשה אושרה ✅" : "הבקשה נדחתה ❌", false);
      setState(() => requests.removeWhere((r) => r["id"] == id));
    } catch (_) {
      showSnackbar("שגיאה בעדכון הבקשה", true);
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

  String translateAction(String action) {
    switch (action) {
      case "create":
        return "יצירת כרטיס חדש";
      case "update":
        return "עדכון כרטיס קיים";
      case "delete":
        return "מחיקת כרטיס קיים";
      default:
        return "לא ידוע";
    }
  }

  Widget renderRequest(dynamic req) {
    final isUpdate = req["action"] == "update";
    final old = oldCards[req["card_id"]] ?? {};

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFFFFD10D),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Text(
              "בקשה: ${translateAction(req["action"])}",
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
                if (req["action"] == "create") ...[
                  buildRow("👤 נהג", req["driver_name"] ?? "---"),
                  buildRow("🚗 רכב", req["plate"] ?? "---"),
                  buildRow("⛽ סוג דלק", req["product_name"] ?? "---"),
                  buildRow("🏢 חברה", req["business_name"] ?? "---"),
                ],
                if (req["action"] == "delete") ...[
                  buildRow("🚗 רכב", req["plate"] ?? "---"),
                  buildRow("🏢 חברה", req["business_name"] ?? "---"),
                ],
                if (isUpdate) ...[
                  buildRow(
                    "👤 נהג",
                    "${old['driver_name'] ?? '---'} ⬅️ ${req['driver_name'] ?? '---'}",
                  ),
                  buildRow(
                    "🚗 רכב",
                    "${old['plate'] ?? '---'} ⬅️ ${req['plate'] ?? '---'}",
                  ),
                  buildRow(
                    "⛽ דלק",
                    "${old['product_name'] ?? '---'} ⬅️ ${req['product_name'] ?? '---'}",
                  ),
                  buildRow("🏢 חברה", req["business_name"] ?? "---"),
                  buildRow("🕒 תאריך", formatLocalDate(req['created_at'])),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => handleAction(req["id"], true),
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
                        onPressed: () => handleAction(req["id"], false),
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
        title: const Text("בקשות כרטיסים"),
        centerTitle: true,
        backgroundColor: const Color(0xFFFFD10D),
        foregroundColor: Colors.black,
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : requests.isEmpty
              ? const Center(child: Text("אין בקשות ממתינות כרגע 🚫"))
              : RefreshIndicator(
                onRefresh: fetchRequests,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: requests.map(renderRequest).toList(),
                ),
              ),
    );
  }
}

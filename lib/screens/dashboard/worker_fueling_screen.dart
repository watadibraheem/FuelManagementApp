import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';


class WorkerFuelingScreen extends StatefulWidget {
  final Dio dio;

  const WorkerFuelingScreen({super.key, required this.dio});

  @override
  State<WorkerFuelingScreen> createState() => _WorkerFuelingScreenState();
}

class _WorkerFuelingScreenState extends State<WorkerFuelingScreen> {
  List<dynamic> fuelRequests = [];
  bool isLoading = true;
  final Map<int, TextEditingController> amountControllers = {};

  @override
  void initState() {
    super.initState();    
    fetchFuelRequests();
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


  Future<void> fetchFuelRequests() async {
    try {
      final response = await widget.dio.get(
        "http://10.0.2.2:8801/fuel-requests/worker",
      );

      setState(() {
        fuelRequests = response.data;
        for (var req in fuelRequests) {
          amountControllers[req["id"]] = TextEditingController();
        }
        isLoading = false;
      });
    } catch (e) {
      buildLogoutButton();
      setState(() => isLoading = false);
    }
  }

  Future<void> markAsComplete(int id) async {
    final controller = amountControllers[id];
    if (controller == null || controller.text.trim().isEmpty) {
      showSnack("יש להזין את כמות התדלוק בפועל", isError: true);
      return;
    }

    final value = double.tryParse(controller.text.trim());
    if (value == null || value <= 0) {
      showSnack("כמות תדלוק לא תקינה", isError: true);
      return;
    }

    try {
      await widget.dio.put(
        "http://10.0.2.2:8801/fuel-requests/$id/complete",
        data: {"completed_amount": value},
      );

      showSnack("תדלוק סומן כהושלם ✅");

      setState(() {
        fuelRequests.removeWhere((r) => r["id"] == id);
        amountControllers.remove(id);
      });
    } catch (e) {
      showSnack("שגיאה בסימון התדלוק", isError: true);
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

  Widget buildRequestCard(dynamic request) {
    final String driver = request["driver_name"] ?? "---";
    final String plate = request["plate"] ?? "---";
    final String business = request["business_name"] ?? "---";
    final String status = request["status"] ?? "---";
    final amount = request["amount"] ?? 0;
    final date = formatLocalDate(request['created_at'] ?? '---');
    final Color badgeColor =
        {
          "approved": Colors.green,
          "auto-approved": Colors.blue,
          "done": Colors.grey,
        }[status] ??
        Colors.orange;

    final TextEditingController controller =
        amountControllers[request["id"]] ?? TextEditingController();

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            buildRow("👤 נהג", driver),
            buildRow("🚗 רכב", plate),
            buildRow("💰 סכום בבקשה", "₪$amount"),
            buildRow("🏢 חברה", business),
            buildRow("🕒 תאריך", date),
            const SizedBox(height: 6),
            Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "סטטוס: $status",
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                labelText: "כמה תדלקת בפועל (₪)",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () => markAsComplete(request['id']),
              icon: const Icon(Icons.check),
              label: const Text("סמן כתדלוק שבוצע"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
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

  Widget buildLogoutButton() {
    return ElevatedButton.icon(
      onPressed: () async{
        final prefs = await SharedPreferences.getInstance();
        prefs.remove('user');
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      },
      icon: const Icon(Icons.logout),
      label: const Text("התנתק"),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        minimumSize: const Size(double.infinity, 48),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("תדלוקים ממתינים"),
        centerTitle: true,
        backgroundColor: const Color(0xFFFFD10D),
        foregroundColor: Colors.black,
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : fuelRequests.isEmpty
              ? Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "אין בקשות תדלוק ממתינות 🚫",
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 20),
                    buildLogoutButton(),
                  ],
                ),
              )
              : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  ...fuelRequests.map(buildRequestCard).toList(),
                  const SizedBox(height: 30),
                  buildLogoutButton(),
                ],
              ),
    );
  }
}

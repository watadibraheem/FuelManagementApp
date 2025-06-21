import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

class MyRequestsScreen extends StatefulWidget {
  final Dio dio;
  final Map<String, dynamic> user;

  const MyRequestsScreen({super.key, required this.dio, required this.user});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<dynamic> cardRequests = [];
  List<dynamic> abnormalFuelRequests = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchRequests();
  }

  Future<void> fetchRequests() async {
    try {
      final cardRes = await widget.dio.get(
        "http://10.0.2.2:8801/cards/card-requests/my",
      );
      final fuelRes = await widget.dio.get(
        "http://10.0.2.2:8801/cards/fuel-requests/abnormal/my",
      );

      setState(() {
        cardRequests = cardRes.data;
        abnormalFuelRequests = fuelRes.data;
        isLoading = false;
      });
    } catch (_) {
      setState(() => isLoading = false);
    }
  }

  Future<void> cancelRequest(String type, int requestId) async {
    final endpoint =
        type == 'card'
            ? "http://10.0.2.2:8801/cards/card-requests/cancel"
            : "http://10.0.2.2:8801/cards/fuel-requests/abnormal/cancel";

    try {
      await widget.dio.post(endpoint, data: {"request_id": requestId});
      await fetchRequests();
    } catch (_) {}
  }

  Widget requestCard(dynamic request, String type) {
    final statusColor =
        {
          'pending': Colors.orange,
          'canceled': Colors.grey,
          'approved': Colors.green,
          'auto-approved': Colors.blue,
        }[request['status']] ??
        Colors.grey;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(
          type == 'card'
              ? "${request['plate']} | ${request['driver_name']}"
              : "${request['plate']} | ₪${request['amount']}",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          type == 'card'
              ? "דלק: ${request['product_name']} | סטטוס: ${request['status']}"
              : "תאריך: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(request['created_at']))} | סטטוס: ${request['status']}",
        ),
        trailing:
            request['status'] == 'pending'
                ? TextButton(
                  onPressed: () async {
                    final confirm = await showDialog(
                      context: context,
                      builder:
                          (ctx) => AlertDialog(
                            title: const Text("ביטול בקשה"),
                            content: const Text(
                              "האם אתה בטוח שברצונך לבטל בקשה זו?",
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text("לא"),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text("כן"),
                              ),
                            ],
                          ),
                    );
                    if (confirm == true) cancelRequest(type, request['id']);
                  },
                  child: const Text(
                    "ביטול",
                    style: TextStyle(color: Colors.red),
                  ),
                )
                : null,
        leading: CircleAvatar(backgroundColor: statusColor, radius: 6),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("הבקשות שלי"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.credit_card), text: "כרטיסים"),
            Tab(icon: Icon(Icons.local_gas_station), text: "תדלוק חריג"),
          ],
        ),
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                controller: _tabController,
                children: [
                  cardRequests.isEmpty
                      ? const Center(child: Text("לא נמצאו בקשות לכרטיסים."))
                      : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: cardRequests.length,
                        itemBuilder:
                            (context, index) =>
                                requestCard(cardRequests[index], 'card'),
                      ),
                  abnormalFuelRequests.isEmpty
                      ? const Center(
                        child: Text("לא נמצאו בקשות תדלוק חריגות."),
                      )
                      : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: abnormalFuelRequests.length,
                        itemBuilder:
                            (context, index) => requestCard(
                              abnormalFuelRequests[index],
                              'fuel',
                            ),
                      ),
                ],
              ),
    );
  }
}

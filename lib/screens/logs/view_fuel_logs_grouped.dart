import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

class GroupedFuelLogsScreen extends StatefulWidget {
  final Dio dio;
  final Map<String, dynamic> user;

  const GroupedFuelLogsScreen({
    super.key,
    required this.dio,
    required this.user,
  });

  @override
  State<GroupedFuelLogsScreen> createState() => _GroupedFuelLogsScreenState();
}

class _GroupedFuelLogsScreenState extends State<GroupedFuelLogsScreen> {
  List<dynamic> abnormalLogs = [];
  Map<String, List<dynamic>> groupedAbnormalLogs = {};
  List<dynamic> normalLogs = [];
  Map<String, List<dynamic>> groupedNormalLogs = {};
  bool isLoading = true;
  String? selectedCard = 'All';
  String? selectedBusiness = 'All';
  List<String> allCards = ['All'];
  List<String> allBusinesses = ['All'];
  bool isAdmin = false;

  @override
  void initState() {
    super.initState();
    isAdmin = widget.user['role'] == 'admin';
    fetchLogs();
  }

  Future<void> fetchLogs() async {
    try {
      final abnormalRes = await widget.dio.get(
        "http://10.0.2.2:8801/fuel-requests",
      );
      final normalRes = await widget.dio.get(
        "http://10.0.2.2:8801/fuel-requests/normal-logs",
      );
      final resCards = await widget.dio.get(
        "http://10.0.2.2:8801/cards/cards-plates",
      );

      if (abnormalRes.statusCode == 200 && normalRes.statusCode == 200) {
        final abnormalData = abnormalRes.data;
        final normalData = normalRes.data;
        final platesData = resCards.data;

        if (platesData is List) {
          allCards.addAll(
            platesData
                .map((l) {
                  final plate = l['plate']?.toString() ?? '';
                  final driver = l['driver_name']?.toString() ?? '';
                  if (plate.trim().isEmpty) return null;
                  return driver.trim().isNotEmpty ? '$plate - $driver' : plate;
                })
                .whereType<String>()
                .toSet()
                .toList(),
          );
        }

        if (abnormalData is List) {
          allBusinesses.addAll(
            abnormalData
                .map((l) => l['business_name']?.toString())
                .whereType<String>()
                .where((v) => v.trim().isNotEmpty)
                .toSet()
                .toList(),
          );

          setState(() {
            abnormalLogs = abnormalData;
            groupedAbnormalLogs = groupByMonth(abnormalData);
            normalLogs = normalData;
            groupedNormalLogs = groupByMonth(normalData);
            isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("\u274C שגיאה בטעינת לוגים")),
      );
    }
  }

  Map<String, List<dynamic>> groupByMonth(List logs) {
    final Map<String, List<dynamic>> map = {};
    for (var log in logs) {
      final createdAt = log['created_at'];
      DateTime? date;
      if (createdAt != null) {
        try {
          date = DateTime.parse(createdAt);
        } catch (_) {
          date = DateTime(2000);
        }
      } else {
        date = DateTime(2000);
      }
      final key = DateFormat('yyyy-MM').format(date);
      map.putIfAbsent(key, () => []).add(log);
    }
    return map;
  }

  Color getStatusColor(String? status) {
    switch (status) {
      case 'auto-approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      case 'done':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Widget buildFilters() {
    return Column(
      children: [
        if (!isAdmin)
          DropdownButton<String>(
            hint: const Text("סנן לפי כרטיס"),
            value: selectedCard,
            onChanged: (val) => setState(() => selectedCard = val),
            items:
                allCards
                    .map(
                      (plate) =>
                          DropdownMenuItem(value: plate, child: Text(plate)),
                    )
                    .toList(),
          ),
        if (isAdmin)
          DropdownButton<String>(
            hint: const Text("סנן לפי עסק"),
            value: selectedBusiness,
            onChanged: (val) => setState(() => selectedBusiness = val),
            items:
                allBusinesses
                    .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                    .toList(),
          ),
      ],
    );
  }

  Widget buildLogCard(dynamic log) {
    final createdAt =
        log['created_at'] != null
            ? DateFormat(
              'dd/MM/yyyy HH:mm',
              'he',
            ).format(DateTime.parse(log['created_at']).toLocal())
            : '-';
    final statusColor = getStatusColor(log['status']);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("\u{1F464} נהג: ${log['driver_name'] ?? '-'}"),
            Text("\u{1F697} רכב: ${log['plate'] ?? '-'}"),
            Text("\u{1F4B0} סכום: ${log['amount'] ?? log['sale']} \u20AA"),
            if (log['completed_amount'] != null)
              Text("\u2705 בוצע: ${log['completed_amount']} \u20AA"),
            Text("\u{1F3E2} עסק: ${log['business_name'] ?? '-'}"),
            Text("\u{1F4C5} $createdAt"),
            if (log['status'] != null)
              Container(
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "סטטוס: ${log['status']}",
                  style: const TextStyle(color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget buildGroupedLogs(Map<String, List<dynamic>> grouped) {
    if (grouped.isEmpty) {
      return const Center(child: Text("\u274C אין לוגים להצגה"));
    }

    final now = DateTime.now();
    final currentMonthKey = DateFormat('yyyy-MM').format(now);

    final sortedEntries =
        grouped.entries.toList()..sort((a, b) {
          final aDate = DateTime.parse('${a.key}-01');
          final bDate = DateTime.parse('${b.key}-01');

          if (a.key == currentMonthKey) return -1;
          if (b.key == currentMonthKey) return 1;

          return bDate.compareTo(aDate); // Descending order
        });

    return ListView(
      padding: const EdgeInsets.all(12),
      children:
          sortedEntries.map((entry) {
            final logs =
                entry.value.where((log) {
                    String? selectedPlate;
                    if (selectedCard == 'All') {
                      selectedPlate = null;
                    } else {
                      selectedPlate = selectedCard?.split(' - ').first.trim();
                    }

                    final matchCard =
                        selectedPlate == null || log['plate'] == selectedPlate;
                    final matchBiz =
                        !isAdmin ||
                        selectedBusiness == 'All' ||
                        log['business_name'] == selectedBusiness;

                    return matchCard && matchBiz;
                  }).toList()
                  ..sort((a, b) {
                    final dateA =
                        DateTime.tryParse(a['created_at'] ?? '') ??
                        DateTime(2000);
                    final dateB =
                        DateTime.tryParse(b['created_at'] ?? '') ??
                        DateTime(2000);
                    return dateB.compareTo(dateA); // Sort newest to oldest
                  });

            if (logs.isEmpty) return const SizedBox();

            final title = DateFormat(
              'MMMM yyyy',
              'he',
            ).format(DateTime.parse('${entry.key}-01'));

            return ExpansionTile(
              title: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              children: logs.map(buildLogCard).toList(),
            );
          }).toList(),
    );
  }



  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("יומני תדלוק"),
          backgroundColor: const Color(0xFFFFD10D),
          foregroundColor: Colors.black,
          bottom: const TabBar(
            tabs: [Tab(text: 'חריגים'), Tab(text: 'רגילים')],
          ),
        ),
        body:
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: buildFilters(),
                    ),
                    const Divider(height: 0),
                    const SizedBox(height: 8),
                    Expanded(
                      child: TabBarView(
                        children: [
                          buildGroupedLogs(groupedAbnormalLogs),
                          buildGroupedLogs(groupedNormalLogs),
                        ],
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}

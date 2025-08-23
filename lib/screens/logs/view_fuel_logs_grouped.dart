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

class _GroupedFuelLogsScreenState extends State<GroupedFuelLogsScreen>
    with SingleTickerProviderStateMixin {
  List<dynamic> abnormalLogs = [];
  Map<String, List<dynamic>> groupedAbnormalLogs = {};
  bool isLoading = true;

  String? selectedCard = 'All';
  String? selectedBusiness = 'All';
  String selectedStatus = 'All';
  final List<String> allCards = ['All'];
  final List<String> allBusinesses = ['All'];
  final List<String> statusOptions = ['All', 'done', 'rejected', 'canceled'];
  bool isAdmin = false;

  String selectedMonthYear = 'All';
  final List<String> monthYearOptions = ['All'];

  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    isAdmin = widget.user['role'] == 'admin';
    _tabController = TabController(length: 2, vsync: this);
    fetchLogs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> fetchLogs() async {
    try {
      final abnormalRes = await widget.dio.get(
        "http://10.0.2.2:8801/fuel-requests",
      );
      final resCards = await widget.dio.get(
        "http://10.0.2.2:8801/cards/cards-plates",
      );

      if (abnormalRes.statusCode == 200) {
        final abnormalData = abnormalRes.data as List<dynamic>;
        final platesData = resCards.data as List<dynamic>;

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

        allBusinesses.addAll(
          abnormalData
              .map((l) => l['business_name']?.toString())
              .whereType<String>()
              .where((v) => v.trim().isNotEmpty)
              .toSet()
              .toList(),
        );

        final months =
            abnormalData
                .map((l) {
                  final dt = DateTime.tryParse(l['created_at'] ?? '');
                  return dt == null ? null : DateFormat('yyyy-MM').format(dt);
                })
                .whereType<String>()
                .toSet()
                .toList()
              ..sort((a, b) => b.compareTo(a));

        monthYearOptions.addAll(months);

        setState(() {
          abnormalLogs = abnormalData;
          groupedAbnormalLogs = groupByMonth(abnormalData);
          isLoading = false;
        });
      }
    } catch (_) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("⛔ שגיאה בטעינת לוגים")));
    }
  }

  Map<String, List<dynamic>> groupByMonth(List logs) {
    final map = <String, List<dynamic>>{};
    for (var log in logs) {
      DateTime date;
      try {
        date = DateTime.parse(log['created_at'] ?? '');
      } catch (_) {
        date = DateTime(2000);
      }
      final key = DateFormat('yyyy-MM').format(date);
      map.putIfAbsent(key, () => []).add(log);
    }
    return map;
  }

  Widget buildFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!isAdmin)
          DropdownButton<String>(
            isExpanded: true,
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
            isExpanded: true,
            value: selectedBusiness,
            onChanged: (val) => setState(() => selectedBusiness = val),
            items:
                allBusinesses
                    .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                    .toList(),
          ),
        DropdownButton<String>(
          isExpanded: true,
          value: selectedStatus,
          onChanged: (val) => setState(() => selectedStatus = val ?? 'All'),
          items:
              statusOptions
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
        ),
        DropdownButton<String>(
          isExpanded: true,
          value: selectedMonthYear,
          hint: const Text("סנן לפי חודש/שנה"),
          onChanged: (val) => setState(() => selectedMonthYear = val ?? 'All'),
          items:
              monthYearOptions
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
        ),
      ],
    );
  }

  Widget buildSummaryTab() {
    final filtered =
        abnormalLogs.where((log) {
          final plateMatch =
              selectedCard == 'All' ||
              log['plate'] == selectedCard?.split(' - ').first;
          final bizMatch =
              !isAdmin ||
              selectedBusiness == 'All' ||
              log['business_name'] == selectedBusiness;
          final statusMatch =
              selectedStatus == 'All' || log['status'] == selectedStatus;
          final monthMatch =
              selectedMonthYear == 'All' ||
              (log['created_at']?.startsWith(selectedMonthYear) ?? false);

          return plateMatch && bizMatch && statusMatch && monthMatch;
        }).toList();

    final totalLogs = filtered.length;
    double totalCost = 0;

    for (var log in filtered) {
      final status = log['status'];
      if (status != 'done') continue;

      final cost =
          double.tryParse(
            (log['completed_amount'] ?? log['amount'])?.toString() ?? '0',
          ) ??
          0;
      totalCost += cost;
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text("סיכום", style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          Text("סה\"כ בקשות: $totalLogs"),
          Text(
            "סה\"כ עלות (ללא נדחות ומבוטלות): ${totalCost.toStringAsFixed(2)} ₪",
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("יומני תדלוק"),
        backgroundColor: const Color(0xFFFFD10D),
        foregroundColor: Colors.black,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'סיכום'), Tab(text: 'יומנים')],
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
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        buildSummaryTab(),
                        buildGroupedLogs(groupedAbnormalLogs),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }

  Widget buildGroupedLogs(Map<String, List<dynamic>> grouped) {
    if (grouped.isEmpty) {
      return const Center(child: Text("⛔ אין לוגים להצגה"));
    }
    final nowKey = DateFormat('yyyy-MM').format(DateTime.now());
    final sorted =
        grouped.entries.toList()..sort((a, b) {
          if (a.key == nowKey) return -1;
          if (b.key == nowKey) return 1;
          return b.key.compareTo(a.key);
        });

    return ListView(
      padding: const EdgeInsets.all(12),
      children:
          sorted.map((e) {
            final monthTitle = DateFormat(
              'MMMM yyyy',
              'he',
            ).format(DateTime.parse('${e.key}-01'));
            final logs =
                e.value.where((log) {
                    final plateMatch =
                        selectedCard == 'All' ||
                        log['plate'] == selectedCard?.split(' - ').first;
                    final bizMatch =
                        !isAdmin ||
                        selectedBusiness == 'All' ||
                        log['business_name'] == selectedBusiness;
                    final statusMatch =
                        selectedStatus == 'All' ||
                        log['status'] == selectedStatus;
                    final monthMatch =
                        selectedMonthYear == 'All' ||
                        (log['created_at']?.startsWith(selectedMonthYear) ??
                            false);
                    return plateMatch && bizMatch && statusMatch && monthMatch;
                  }).toList()
                  ..sort((a, b) {
                    final dA =
                        DateTime.tryParse(a['created_at'] ?? '') ??
                        DateTime(2000);
                    final dB =
                        DateTime.tryParse(b['created_at'] ?? '') ??
                        DateTime(2000);
                    return dB.compareTo(dA);
                  });

            if (logs.isEmpty) return const SizedBox();

            return ExpansionTile(
              title: Text(
                monthTitle,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              children:
                  logs.map((log) {
                    final createdAt =
                        log['created_at'] != null
                            ? DateFormat('dd/MM/yyyy HH:mm', 'he').format(
                              DateTime.parse(log['created_at']).toLocal(),
                            )
                            : '-';

                    final statusColor = () {
                      switch (log['status']) {
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
                    }();

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("נהג: ${log['driver_name'] ?? '-'}"),
                            Text("רכב: ${log['plate'] ?? '-'}"),
                            Text("עלות: ${log['amount'] ?? log['sale']} ₪"),
                            if (log['completed_amount'] != null)
                              Text("בוצע: ${log['completed_amount']} ₪"),
                            Text("עסק: ${log['business_name'] ?? '-'}"),
                            Text("תאריך: $createdAt"),
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
                  }).toList(),
            );
          }).toList(),
    );
  }
}

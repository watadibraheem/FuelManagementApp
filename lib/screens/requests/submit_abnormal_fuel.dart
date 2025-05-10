import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';

class SubmitAbnormalFuelScreen extends StatefulWidget {
  final Dio dio;

  const SubmitAbnormalFuelScreen({super.key, required this.dio});

  @override
  State<SubmitAbnormalFuelScreen> createState() =>
      _SubmitAbnormalFuelScreenState();
}

class _SubmitAbnormalFuelScreenState extends State<SubmitAbnormalFuelScreen> {
  final TextEditingController amountController = TextEditingController();

  bool isLoading = false;
  String responseMessage = '';
  List<dynamic> userCards = [];
  int? selectedCardId;
  dynamic selectedCard;

  late Dio dio;
  late CookieJar cookieJar;

  @override
  void initState() {
    super.initState();

    dio = widget.dio;
    cookieJar = CookieJar();
    dio.interceptors.add(CookieManager(cookieJar));

    fetchUserCards();
  }

  Future<void> fetchUserCards() async {
    try {
      final response = await dio.get("http://10.0.2.2:8801/cards");

      if (response.statusCode == 200) {
        setState(() {
          userCards = response.data;
        });
      } else {
        setState(() {
          responseMessage = 'שגיאה בטעינת כרטיסים';
        });
      }
    } catch (e) {
      setState(() {
        responseMessage = 'שגיאה: ${e.toString()}';
      });
    }
  }

  void submitRequest() async {
    final amountText = amountController.text.trim();

    if (amountText.isEmpty || selectedCardId == null || selectedCard == null) {
      setState(() {
        responseMessage = 'יש לבחור כרטיס ולהזין כמות תדלוק';
      });
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      setState(() {
        responseMessage = 'כמות תדלוק לא תקינה';
      });
      return;
    }

    setState(() {
      isLoading = true;
      responseMessage = '';
    });

    try {
      final response = await dio.post(
        "http://10.0.2.2:8801/fuel-requests",
        data: {
          "driverName": selectedCard["driver_name"],
          "plate": selectedCard["plate"],
          "amount": amount,
          "card_id": selectedCardId,
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          responseMessage = 'הבקשה נשלחה בהצלחה!';
          amountController.clear();
          selectedCardId = null;
          selectedCard = null;
        });
      } else {
        setState(() {
          responseMessage = 'שליחה נכשלה. נסה שוב.';
        });
      }
    } catch (e) {
      setState(() {
        responseMessage = 'שגיאה: ${e.toString()}';
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  Widget buildInputField(
    TextEditingController controller,
    String label, {
    bool isNumber = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      textDirection: TextDirection.rtl,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Colors.grey[100],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('בקשת תדלוק חריגה'),
        backgroundColor: const Color(0xFFFFD10D),
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            DropdownButtonFormField<int>(
              value: selectedCardId,
              onChanged: (value) {
                setState(() {
                  selectedCardId = value;
                  selectedCard = userCards.firstWhere(
                    (card) => card["id"] == value,
                    orElse: () => null,
                  );
                });
              },
              items:
                  userCards.map<DropdownMenuItem<int>>((card) {
                    return DropdownMenuItem<int>(
                      value: card["id"],
                      child: Text(
                        '${card["driver_name"]} - ${card["plate"]}',
                        textDirection: TextDirection.rtl,
                      ),
                    );
                  }).toList(),
              decoration: InputDecoration(
                labelText: 'בחר כרטיס תדלוק',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
            const SizedBox(height: 16),
            if (selectedCard != null) ...[
              buildStaticLine("👤 שם נהג", selectedCard["driver_name"]),
              buildStaticLine("🚗 מספר רכב", selectedCard["plate"]),
              const SizedBox(height: 16),
            ],
            buildInputField(amountController, 'כמות תדלוק (₪)', isNumber: true),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: isLoading ? null : submitRequest,
              icon: const Icon(Icons.send),
              label: const Text("שלח בקשה"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            const SizedBox(height: 16),
            if (responseMessage.isNotEmpty)
              Text(
                responseMessage,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }

  Widget buildStaticLine(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(value),
      ],
    );
  }
}

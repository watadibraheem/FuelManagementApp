import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class ManageFuelCardsScreen extends StatefulWidget {
  final Dio dio;

  const ManageFuelCardsScreen({super.key, required this.dio});

  @override
  State<ManageFuelCardsScreen> createState() => _ManageFuelCardsScreenState();
}

class _ManageFuelCardsScreenState extends State<ManageFuelCardsScreen> {
  List<dynamic> cards = [];
  List<dynamic> filteredCards = [];
  bool isLoading = true;

  Set<int> editingCards = {};
  Map<int, Map<String, dynamic>> originalCardStates = {};
  Map<int, Map<String, dynamic>> lastSubmittedStates = {};

  final newDriver = TextEditingController();
  final newPlate = TextEditingController();
  final searchPlate = TextEditingController();
  String? selectedFuel;
  final List<String> fuelTypes = ['Gasoline', 'Diesel'];

  @override
  void initState() {
    super.initState();
    fetchCards();
  }

  Future<void> fetchCards() async {
    try {
      final res = await widget.dio.get("http://10.0.2.2:8801/cards");
      final allCards = res.data;

      setState(() {
        cards = allCards;
        filteredCards = allCards;
        isLoading = false;
      });
    } catch (_) {
      showSnackbar("שגיאה בטעינת כרטיסים", true);
    }
  }

  void filterCards(String query) {
    setState(() {
      filteredCards =
          query.trim().isEmpty
              ? cards
              : cards
                  .where((c) => c['plate'].toString().contains(query.trim()))
                  .toList();
    });
  }

  void showSnackbar(String message, bool isError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textDirection: TextDirection.rtl),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      ),
    );
  }

  Future<void> createCard() async {
    if (newDriver.text.isEmpty ||
        newPlate.text.isEmpty ||
        selectedFuel == null) {
      showSnackbar("נא למלא את כל השדות", true);
      return;
    }
    try {
      await widget.dio.post(
        "http://10.0.2.2:8801/cards/card-requests/create",
        data: {
          "driver_name": newDriver.text,
          "plate": newPlate.text,
          "product_name": selectedFuel,
        },
      );
      showSnackbar("הבקשה נשלחה לאישור", false);
      newDriver.clear();
      newPlate.clear();
      setState(() => selectedFuel = null);
      fetchCards();
    } catch (_) {
      showSnackbar("שגיאה בשליחת הבקשה", true);
    }
  }

  Future<void> updateCard(
    dynamic originalCard,
    Map<String, dynamic> editedCard,
  ) async {
    final id = originalCard['id'];

    if (originalCard["is_pending"] == 1) {
      showSnackbar("לא ניתן לבצע פעולה נוספת על כרטיס זה כרגע", true);
      return;
    }

    final originalSnapshot = originalCardStates[id];
    final lastSubmitted = lastSubmittedStates[id];

    final hasChangedFromOriginal =
        originalSnapshot != null &&
        (originalSnapshot['driver_name'] != editedCard['driver_name'] ||
            originalSnapshot['plate'] != editedCard['plate'] ||
            originalSnapshot['product_name'] != editedCard['product_name']);

    final isSameAsLastSubmission =
        lastSubmitted != null &&
        lastSubmitted['driver_name'] == editedCard['driver_name'] &&
        lastSubmitted['plate'] == editedCard['plate'] &&
        lastSubmitted['product_name'] == editedCard['product_name'];

    if (!hasChangedFromOriginal || isSameAsLastSubmission) {
      showSnackbar("לא נעשו שינויים", true);
      setState(() => editingCards.remove(id));
      originalCardStates.remove(id);
      return;
    }

    try {
      await widget.dio.post(
        "http://10.0.2.2:8801/cards/card-requests/update",
        data: {
          "driver_name": editedCard["driver_name"],
          "plate": editedCard["plate"],
          "product_name": editedCard["product_name"],
          "card_id": editedCard["id"],
        },
      );
      showSnackbar("בקשת עדכון נשלחה", false);
      lastSubmittedStates[id] = Map<String, dynamic>.from(editedCard);
      fetchCards();
    } catch (_) {
      showSnackbar("שגיאה בעדכון הכרטיס", true);
    } finally {
      setState(() {
        editingCards.remove(id);
        originalCardStates.remove(id);
      });
    }
  }

  Future<void> deleteCard(dynamic card) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text("אישור מחיקה"),
            content: const Text("האם אתה בטוח שברצונך לבקש מחיקת כרטיס זה?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text("ביטול"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text("מחק"),
              ),
            ],
          ),
    );
    if (confirm != true) return;

    final id = card['id'];

    if (card["is_pending"] == 1) {
      showSnackbar("לא ניתן לבצע פעולה נוספת על כרטיס זה כרגע", true);
      return;
    }

    try {
      await widget.dio.post(
        "http://10.0.2.2:8801/cards/card-requests/delete",
        data: {
          "card_id": id,
          "driver_name": card["driver_name"],
          "plate": card["plate"],
          "product_name": card["product_name"],
        },
      );
      showSnackbar("בקשת מחיקה נשלחה", false);
      fetchCards();
    } catch (_) {
      showSnackbar("שגיאה במחיקת הכרטיס", true);
    } finally {
      setState(() => editingCards.remove(id));
    }
  }

  Widget buildCard(dynamic card) {
    final id = card["id"];
    final isEditing = editingCards.contains(id);
    // final isPending = pendingCardRequests.contains(id);
    final isPending = card["is_pending"] == 1; // <- THIS IS NEW
    final Map<String, dynamic> editingValues = Map<String, dynamic>.from(card);

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            isEditing
                ? buildEditableField(editingValues, "driver_name", "שם נהג")
                : buildStaticField("👤 שם נהג", card["driver_name"]),
            isEditing
                ? buildEditableField(editingValues, "plate", "מספר רכב")
                : buildStaticField("🚗 מספר רכב", card["plate"]),
            isEditing
                ? buildEditableField(editingValues, "product_name", "סוג דלק")
                : buildStaticField("⛽ סוג דלק", card["product_name"]),
            const SizedBox(height: 10),
            if (isPending)
              Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.blueGrey,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  "בקשה ממתינה",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            const SizedBox(height: 10),
            isEditing
                ? Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.save),
                        label: const Text("עדכן"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed:
                            isPending
                                ? null
                                : () => updateCard(card, editingValues),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.delete),
                        label: const Text("מחק"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: isPending ? null : () => deleteCard(card),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.close),
                        label: const Text("ביטול"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed:
                            isPending
                                ? null
                                : () {
                                  setState(() => editingCards.remove(id));
                                  originalCardStates.remove(id);
                                },
                      ),
                    ),
                  ],
                )
                : ElevatedButton.icon(
                  icon: const Icon(Icons.edit),
                  label: const Text("ערוך"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed:
                      isPending
                          ? null
                          : () {
                            originalCardStates[id] = Map<String, dynamic>.from(
                              card,
                            );
                            setState(() => editingCards.add(id));
                          },
                ),
          ],
        ),
      ),
    );
  }

  Widget buildEditableField(
    Map<String, dynamic> card,
    String key,
    String label,
  ) {
    if (key == "product_name") {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: DropdownButtonFormField<String>(
          value: card[key],
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
            fillColor: Colors.grey[100],
          ),
          items:
              fuelTypes
                  .map(
                    (type) => DropdownMenuItem(value: type, child: Text(type)),
                  )
                  .toList(),
          onChanged: (v) => card[key] = v,
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: TextEditingController(text: card[key]),
        onChanged: (v) => card[key] = v,
        textDirection: TextDirection.rtl,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: Colors.grey[100],
        ),
      ),
    );
  }

  Widget buildStaticField(String label, String value) {
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

  Widget buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextField(
        controller: searchPlate,
        textDirection: TextDirection.rtl,
        onChanged: filterCards,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search),
          labelText: "חפש לפי מספר רכב",
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey[100],
        ),
      ),
    );
  }

  Widget buildNewCardForm() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "✳ יצירת כרטיס חדש",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 10),
            buildInput(newDriver, "שם נהג"),
            buildInput(newPlate, "מספר רכב"),
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: DropdownButtonFormField<String>(
                value: selectedFuel,
                decoration: InputDecoration(
                  labelText: "סוג דלק",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                items:
                    fuelTypes
                        .map(
                          (type) =>
                              DropdownMenuItem(value: type, child: Text(type)),
                        )
                        .toList(),
                onChanged: (v) => setState(() => selectedFuel = v),
              ),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text("שלח בקשה"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: createCard,
            ),
          ],
        ),
      ),
    );
  }

  Widget buildInput(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        textDirection: TextDirection.rtl,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: Colors.grey[100],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ניהול כרטיסים"),
        backgroundColor: const Color(0xFFFFD10D),
        foregroundColor: Colors.black,
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  buildNewCardForm(),
                  const Divider(height: 30, thickness: 1.2),
                  buildSearchBar(),
                  if (filteredCards.isEmpty)
                    const Center(
                      child: Text(
                        "אין כרטיסים להצגה כרגע",
                        textDirection: TextDirection.rtl,
                      ),
                    )
                  else
                    ...filteredCards.map(buildCard).toList(),
                ],
              ),
    );
  }
}

import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'package:intl/date_symbol_data_local.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('he', null); // initialize Hebrew locale
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'מערכת ניהול תדלוק',
      theme: ThemeData(primarySwatch: Colors.amber, fontFamily: 'Arial'),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: LoginScreen(), // or your actual screen
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'dashboard/worker_fueling_screen.dart';
import 'main_app.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  late Dio dio;
  late CookieJar cookieJar;

  bool isLoading = false;
  String error = '';

  @override
  void initState() {
    super.initState();
    dio = Dio();
    cookieJar = CookieJar();
    dio.interceptors.add(CookieManager(cookieJar));
    checkLoginStatus();
  }

  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    if (userJson != null) {
      final user = jsonDecode(userJson);
      final role = user["role"];
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (_) =>
                  role == "worker"
                      ? WorkerFuelingScreen(dio: dio)
                      : MainApp(user: user, dio: dio),
        ),
      );
    }
  }

  Future<void> loginUser() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => error = 'נא למלא אימייל וסיסמה');
      return;
    }

    setState(() {
      isLoading = true;
      error = '';
    });

    try {
      final res = await dio.post(
        "http://10.0.2.2:8801/users/login",
        data: {"email": email, "password": password},
      );

      final user = res.data["user"];
      if (user['status'] != 2) {
        setState(() => error = 'המשתמש אינו פעיל');
      } else {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', jsonEncode(user));
        if (!mounted) return;
        final route =
            user["role"] == "worker"
                ? WorkerFuelingScreen(dio: dio)
                : MainApp(user: user, dio: dio);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => route),
        );
      }
    } on DioException catch (e) {
      final msg =
          e.response?.statusCode == 401
              ? (e.response?.data['message'] == 'Invalid password'
                  ? 'סיסמה שגויה'
                  : 'אימייל לא נמצא')
              : 'שגיאה, נסה שוב';
      setState(() => error = msg);
    } catch (_) {
      setState(() => error = 'שגיאה, נסה שוב');
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFD10D),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Logo & Title
              Image.network(
                "http://10.0.2.2:8801/uploads/sunLogo.png",
                width: 180,
                height: 180,
              ),
              const SizedBox(height: 10),
              const Text(
                "SUN ברוך הבא למערכת",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFA500),
                ),
              ),
              const SizedBox(height: 30),

              // Fields
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  hintText: 'אימייל',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'סיסמה',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Error message
              if (error.isNotEmpty)
                Text(error, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 20),

              // Login button
              ElevatedButton(
                onPressed: isLoading ? null : loginUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFA500),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 60,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child:
                    isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                          "התחבר",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

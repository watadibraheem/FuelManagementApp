import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class CreateUserScreen extends StatefulWidget {
  final Dio dio;
  const CreateUserScreen({super.key, required this.dio});

  @override
  State<CreateUserScreen> createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends State<CreateUserScreen>
    with SingleTickerProviderStateMixin {
  // Controllers & Form Key
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _contactController = TextEditingController();
  final _businessNameController = TextEditingController();

  // Role selection
  String _selectedRole = 'worker';
  final List<String> roles = ['admin', 'user', 'worker'];

  // Tab controller
  late final TabController _tabController;

  // Create User
  bool _isSubmitting = false;

  // Manage Users
  List<Map<String, dynamic>> _users = [];
  bool _loadingUsers = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchUsers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Fetch all users
  Future<void> _fetchUsers() async {
    try {
      final res = await widget.dio.get("http://10.0.2.2:8801/users/Allusers",);
      final data = res.data as List;
      setState(() {
        _users = data.cast<Map<String, dynamic>>();
        _loadingUsers = false;
      });
    } catch (e) {
      setState(() => _loadingUsers = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("שגיאה בטעינת משתמשים")));
    }
  }

  // Submit form to create user
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final res = await widget.dio.post(
        "http://10.0.2.2:8801/users/register",
        data: {
          "email": _emailController.text.trim(),
          "password": _passwordController.text.trim(),
          "phone": _phoneController.text.trim(),
          "contact": _contactController.text.trim(),
          "role": _selectedRole,
          "business_name":
              _selectedRole == 'user'
                  ? _businessNameController.text.trim()
                  : null,
        },
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("✅ ${res.data['message']}")));
      _formKey.currentState?.reset();
      _selectedRole = 'worker';
      _businessNameController.clear();
      _fetchUsers(); // Refresh user list
    } on DioException catch (e) {
      final msg = e.response?.data['message'] ?? "שגיאה ביצירת משתמש";
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("⛔ $msg")));
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  // Toggle user active/inactive
  Future<void> _toggleUserStatus(int userId, bool activate) async {
    final endpoint =
        activate ? "http://10.0.2.2:8801/users/users/$userId/activate" : "http://10.0.2.2:8801/users/users/$userId/deactivate";
    try {
      await widget.dio.put(endpoint);
      _fetchUsers();
    } on DioException catch (_) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("שגיאה בעדכון סטטוס")));
    }
  }

  // Show Edit dialog
  Future<void> _showEditDialog(Map<String, dynamic> user) async {
    final businessController = TextEditingController(
      text: user['business_name'] ?? '',
    );
    final phoneController = TextEditingController(text: user['phone'] ?? '');
    final contactController = TextEditingController(
      text: user['contact'] ?? '',
    );
    final passwordController = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text("ערוך משתמש ${user['email']}"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                if (user['role'] == 'user')
                  TextField(
                    controller: businessController,
                    decoration: const InputDecoration(labelText: "שם עסק"),
                  ),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: "טלפון"),
                ),
                TextField(
                  controller: contactController,
                  decoration: const InputDecoration(labelText: "איש קשר"),
                ),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: "סיסמה חדשה"),
                  obscureText: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("ביטול"),
            ),
            ElevatedButton(
              onPressed: () async {
                final data = {
                  "business_name":
                      user['role'] == 'user'
                          ? businessController.text.trim()
                          : null,
                  "phone": phoneController.text.trim(),
                  "contact": contactController.text.trim(),
                };
                if (passwordController.text.isNotEmpty)
                  data['password'] = passwordController.text.trim();

                try {
                  await widget.dio.put("http://10.0.2.2:8801/users/users/${user['id']}", data: data);
                  Navigator.pop(context);
                  _fetchUsers();
                } on DioException catch (_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("שגיאה בעדכון משתמש")),
                  );
                }
              },
              child: const Text("שמירה"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final yellow = const Color(0xFFFFD10D);

    return Scaffold(
      appBar: AppBar(
        title: const Text("ניהול משתמשים"),
        backgroundColor: yellow,
        foregroundColor: Colors.black,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'צור משתמש'), Tab(text: 'הרשימה')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Create User
          Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  DropdownButtonFormField(
                    value: _selectedRole,
                    decoration: const InputDecoration(labelText: "סוג משתמש"),
                    items:
                        roles
                            .map(
                              (r) => DropdownMenuItem(value: r, child: Text(r)),
                            )
                            .toList(),
                    onChanged: (val) => setState(() => _selectedRole = val!),
                  ),
                  if (_selectedRole == 'user')
                    TextFormField(
                      controller: _businessNameController,
                      decoration: const InputDecoration(labelText: "שם עסק"),
                      validator:
                          (val) =>
                              val == null || val.isEmpty ? 'שדה חובה' : null,
                    ),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: "אימייל"),
                    keyboardType: TextInputType.emailAddress,
                    validator:
                        (val) =>
                            val == null || !val.contains('@')
                                ? 'אימייל לא תקין'
                                : null,
                  ),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: "סיסמה"),
                    obscureText: true,
                    validator:
                        (val) =>
                            val == null || val.length < 6
                                ? 'לפחות 6 תווים'
                                : null,
                  ),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(labelText: "טלפון"),
                    keyboardType: TextInputType.phone,
                    validator:
                        (val) =>
                            val == null || val.length < 9
                                ? 'טלפון לא תקין'
                                : null,
                  ),
                  TextFormField(
                    controller: _contactController,
                    decoration: const InputDecoration(labelText: "איש קשר"),
                    validator:
                        (val) => val == null || val.isEmpty ? 'שדה חובה' : null,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: yellow,
                      foregroundColor: Colors.black,
                    ),
                    child: Text(_isSubmitting ? 'שולח...' : 'צור משתמש'),
                  ),
                ],
              ),
            ),
          ),

          // Tab 2: Manage Users
          _loadingUsers
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                itemCount: _users.length,
                itemBuilder: (context, i) {
                  final user = _users[i];
                  final isActive = user['status'] == 2;
                  return ListTile(
                    title: Text(user['email']),
                    subtitle: Text(
                      "Role: ${user['role']} | Status: ${isActive ? 'Active' : 'Inactive'}",
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showEditDialog(user),
                        ),
                        IconButton(
                          icon: Icon(
                            isActive ? Icons.block : Icons.check_circle,
                            color: isActive ? Colors.red : Colors.green,
                          ),
                          onPressed:
                              () => _toggleUserStatus(user['id'], !isActive),
                        ),
                      ],
                    ),
                  );
                },
              ),
        ],
      ),
    );
  }
}

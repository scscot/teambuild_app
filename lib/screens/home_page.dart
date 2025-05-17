// lib/screens/home_page.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/app_user_model.dart';
import 'sign_in_screen.dart';

class HomePage extends StatefulWidget {
  final String email;

  HomePage({required this.email});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  AppUserModel? _user;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    print('⚠️ HomePage initState triggered');
    print('🧪 HomePage attempting to load user with email: ${widget.email}');
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = await _firestoreService.getUserByEmail(widget.email);
    setState(() {
      _user = user;
      _loading = false;
    });
  }

  Future<void> _signOut() async {
    await _authService.signOut();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => SignInScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TeamBuilder+ Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: _signOut,
          )
        ],
      ),
      body: Center(
        child: _loading
            ? CircularProgressIndicator()
            : _user == null
                ? const Text('Failed to load profile.')
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Welcome back!',
                        style: TextStyle(fontSize: 20),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _user!.name,
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _user!.email,
                        style: const TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
      ),
    );
  }
}

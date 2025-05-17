// CLEAN PATCH — login_screen.dart with biometric check and original layout

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:local_auth/local_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/session_manager.dart';
import 'dashboard_screen.dart';
import 'new_registration_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _attemptBiometricLogin();
  }

  Future<void> _attemptBiometricLogin() async {
    final isEnabled = await SessionManager().getBiometricEnabled();
    if (!isEnabled) return;

    final auth = LocalAuthentication();
    final canCheck = await auth.canCheckBiometrics;
    final didAuthenticate = canCheck
        ? await auth.authenticate(localizedReason: 'Please authenticate to login')
        : false;

    if (didAuthenticate) {
      final storedUser = await SessionManager().getCurrentUser();
      if (storedUser != null) {
        print('✅ Biometric login — restored user: \${storedUser.email}');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      } else {
        print('❌ Biometric login — no stored session found');
      }
    } else {
      print('❌ Biometric login — authentication failed');
    }
  }

  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      final user = await AuthService().signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      if (user != null) {
        final userData = await FirestoreService().getUserData(user.uid);
        if (userData != null) {
          final currentUser = UserModel.fromMap(userData).copyWith(uid: user.uid);
          SessionManager().setCurrentUser(currentUser);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
          );
        }
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _login,
              child: _isLoading ? const CircularProgressIndicator() : const Text('Login'),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NewRegistrationScreen()),
              ),
              child: const Text('Create Account'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 24),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ]
          ],
        ),
      ),
    );
  }
}

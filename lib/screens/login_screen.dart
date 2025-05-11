// FINAL REFINED: login_screen.dart — Restores locked-in visual layout

import 'package:flutter/material.dart';
import 'new_registration_screen.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final AuthService authService = AuthService();
  final FirestoreService firestoreService = FirestoreService();

  bool isLoading = false;
  String? errorMessage;

  Future<void> _login() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final success = await authService.signInWithEmailAndPassword(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      if (success) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => DashboardScreen()),
        );
      } else {
        setState(() {
          errorMessage = 'Login failed. Please check your credentials.';
        });
      }

    } catch (e) {
      setState(() {
        errorMessage = 'Login failed: $e';
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _navigateToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NewRegistrationScreen(
          authService: authService,
          firestoreService: firestoreService,
          referredBy: 'TEMP123',
          // referredBy: 'kn5eYjRM9sf7Scizh1F9AOfZU122',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: OutlinedButton(
                onPressed: isLoading ? null : _login,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.indigo),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.indigo)
                    : const Text(
                        'Log In',
                        style: TextStyle(fontSize: 16, color: Colors.indigo),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () {
                  // TODO: Forgot password flow
                },
                child: const Text('Forgot Password?'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 50,
              child: OutlinedButton(
                onPressed: _navigateToRegister,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.indigo),
                ),
                child: const Text(
                  'Create Account',
                  style: TextStyle(fontSize: 16, color: Colors.indigo),
                ),
              ),
            ),
            if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 24.0),
                child: Text(
                  errorMessage!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// PATCHED — login_screen.dart with UID propagation, Google & Apple Sign-In

import 'package:flutter/material.dart';
import 'package:tbp/models/user_model.dart';
import 'package:tbp/screens/dashboard_screen.dart';
import 'package:tbp/screens/new_registration_screen.dart';
import 'package:tbp/services/auth_service.dart';
import 'package:tbp/services/firestore_service.dart';
import 'package:tbp/services/session_manager.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final user = await AuthService().signInWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        if (user != null) {
          final userData = await FirestoreService().getUserData(user.uid);

          if (userData != null) {
            final loggedInUser = UserModel.fromMap(userData);
            final completeUser = loggedInUser.copyWith(uid: user.uid);
            SessionManager().setCurrentUser(completeUser);

            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const DashboardScreen()),
              );
            }
          } else {
            setState(() {
              _errorMessage = 'User profile not found.';
            });
          }
        } else {
          setState(() {
            _errorMessage = 'Login failed. Please try again.';
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = e.toString();
        });
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser != null) {
      print('🟢 Google Sign-In: ${googleUser.displayName}');
    } else {
      print('⚠️ Google Sign-In cancelled');
    }
  }

  Future<void> _signInWithApple() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
      );
      print('🍎 Apple Sign-In success: ${credential.userIdentifier}');
    } catch (e) {
      print('❌ Apple Sign-In failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 20),
              if (_isLoading) const CircularProgressIndicator(),
              if (_errorMessage != null) ...[
                Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 10),
              ],
              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                child: const Text('Login'),
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NewRegistrationScreen()),
                ),
                child: const Text('Create Account'),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const Text('or sign in with'),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _signInWithGoogle,
                icon: const Icon(Icons.login),
                label: const Text('Sign in with Google'),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _signInWithApple,
                icon: const Icon(Icons.apple),
                label: const Text('Sign in with Apple'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

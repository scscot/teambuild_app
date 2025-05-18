// PATCH START: explicitly import global constant 'statesByCountry' from states_by_country.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/session_manager.dart';
import '../data/states_by_country.dart';
import 'dashboard_screen.dart';

class NewRegistrationScreen extends StatefulWidget {
  const NewRegistrationScreen({super.key});

  @override
  State<NewRegistrationScreen> createState() => _NewRegistrationScreenState();
}

class _NewRegistrationScreenState extends State<NewRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _referralCodeController = TextEditingController();

  String? _selectedCountry;
  String? _selectedState;
  String? _sponsorName;
  bool _isLoading = false;

  List<String> get states => statesByCountry[_selectedCountry] ?? [];

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _referralCodeController.dispose();
    super.dispose();
  }

  Future<int> _getReferrerLevel(String? referralCode) async {
    if (referralCode == null || referralCode.isEmpty) return 1;
    final referrer = await FirestoreService().getUserByReferralCode(referralCode);
    if (referrer != null && referrer.level != null) {
      return referrer.level! + 1;
    }
    return 1;
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      UserModel user = await AuthService().register(email, password);

      final referralCode = _referralCodeController.text.trim();
      final referredBy = referralCode.isNotEmpty ? referralCode : null;
      final level = await _getReferrerLevel(referredBy);

      final newUser = UserModel(
        uid: user.uid,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: email,
        createdAt: DateTime.now(),
        country: _selectedCountry,
        state: _selectedState,
        referralCode: const Uuid().v4().substring(0, 8),
        referredBy: referredBy,
        level: level,
      );

      await FirestoreService().createUser(newUser.toMap());
      await SessionManager().setCurrentUser(newUser);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      }
    } catch (e) {
      print('❌ Registration error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration failed: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _lookupSponsor() async {
    final code = _referralCodeController.text.trim();
    if (code.isEmpty) return;

    try {
      final name = await FirestoreService().getSponsorNameByReferralCode(code);
      setState(() {
        _sponsorName = name;
      });
    } catch (e) {
      print('❌ Error retrieving sponsor name: $e');
      setState(() {
        _sponsorName = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(labelText: 'First Name'),
                validator: (value) => value == null || value.isEmpty ? 'Enter your first name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(labelText: 'Last Name'),
                validator: (value) => value == null || value.isEmpty ? 'Enter your last name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) =>
                    value == null || !value.contains('@') ? 'Enter a valid email' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) =>
                    value == null || value.length < 6 ? 'Password must be at least 6 characters' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: const InputDecoration(labelText: 'Confirm Password'),
                obscureText: true,
                validator: (value) =>
                    value != _passwordController.text ? 'Passwords do not match' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedCountry,
                hint: const Text('Select Country'),
                items: statesByCountry.keys
                    .map((country) => DropdownMenuItem(value: country, child: Text(country)))
                    .toList(),
                onChanged: (value) => setState(() {
                  _selectedCountry = value;
                  _selectedState = null;
                }),
                decoration: const InputDecoration(labelText: 'Country'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedState,
                items: states
                    .map((state) => DropdownMenuItem(value: state, child: Text(state)))
                    .toList(),
                onChanged: (value) => setState(() => _selectedState = value),
                decoration: const InputDecoration(labelText: 'State/Province'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _referralCodeController,
                decoration: const InputDecoration(labelText: 'Referral Code (optional)'),
                onChanged: (_) => _lookupSponsor(),
              ),
              if (_sponsorName != null && _sponsorName!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Referred by: $_sponsorName',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Create Account'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// PATCH END

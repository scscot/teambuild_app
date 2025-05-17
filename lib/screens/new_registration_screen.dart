// RESTORED — new_registration_screen.dart from uploaded file (225 lines)

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/session_manager.dart';
import '../models/user_model.dart';
import 'dashboard_screen.dart';
import '../data/states_by_country.dart';

class NewRegistrationScreen extends StatefulWidget {
  final String? referredBy;
  const NewRegistrationScreen({super.key, this.referredBy});

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
  final TextEditingController _cityController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedCountry = 'United States';
  String? _selectedState;
  String? _sponsorName;
  String? _referralCodeToSave;

  List<String> get _statesForSelectedCountry {
    return countryStateMap[_selectedCountry] ?? [];
  }

  @override
  void initState() {
    super.initState();
    _lookupSponsor();
  }

  Future<void> _lookupSponsor() async {
    if (widget.referredBy != null && widget.referredBy!.isNotEmpty) {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('referralCode', isEqualTo: widget.referredBy!)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        setState(() {
          _sponsorName = '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim();
          _referralCodeToSave = widget.referredBy;
        });
      }
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final success = await AuthService().register(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration failed. Please try again.')),
        );
        setState(() => _isLoading = false);
        return;
      }

      final user = await SessionManager().getCurrentUser();
      if (user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration error: \$e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _cityController.dispose();
    super.dispose();
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(labelText: 'First Name'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(labelText: 'Last Name'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirm Password'),
                validator: (value) => value != _passwordController.text
                    ? 'Passwords do not match'
                    : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(labelText: 'City'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedCountry,
                decoration: const InputDecoration(labelText: 'Country'),
                items: countryStateMap.keys
                    .map((country) => DropdownMenuItem(
                          value: country,
                          child: Text(country),
                        ))
                    .toList(),
                onChanged: (value) => setState(() {
                  _selectedCountry = value!;
                  _selectedState = null;
                }),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedState,
                decoration: const InputDecoration(labelText: 'State/Province'),
                items: _statesForSelectedCountry
                    .map((state) => DropdownMenuItem(
                          value: state,
                          child: Text(state),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _selectedState = value!),
              ),
              const SizedBox(height: 10),
              if (_sponsorName != null)
                Text('Sponsor: $_sponsorName'),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _register,
                  child: const Text('Register'),
                ),
              ),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

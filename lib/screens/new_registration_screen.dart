// FINAL PATCHED: new_registration_screen.dart — Conditional Sponsor Field Display

import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../data/states_by_country.dart';

class NewRegistrationScreen extends StatefulWidget {
  final AuthService authService;
  final FirestoreService firestoreService;
  final String referredBy;

  const NewRegistrationScreen({
    super.key,
    required this.authService,
    required this.firestoreService,
    required this.referredBy,
  });

  @override
  State<NewRegistrationScreen> createState() => _NewRegistrationScreenState();
}

class _NewRegistrationScreenState extends State<NewRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _cityController = TextEditingController();
  final _sponsorController = TextEditingController();
  String? _selectedCountry;
  String? _selectedState;
  bool _showSponsorField = false;

  @override
  void initState() {
    super.initState();
    if (widget.referredBy.isNotEmpty) {
      _fetchSponsorName();
    }
  }

  Future<void> _fetchSponsorName() async {
    final sponsor = await widget.firestoreService.getUserProfileByReferralCode(widget.referredBy);
    if (sponsor != null && sponsor['fullName'] != null && mounted) {
      setState(() {
        _sponsorController.text = sponsor['fullName'];
        _showSponsorField = true;
      });
    }
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      try {
        final result = await widget.authService.createUserWithEmail(
          _emailController.text.trim(),
          _passwordController.text.trim(),
          _fullNameController.text.trim(),
          widget.referredBy.isNotEmpty ? widget.referredBy : null,
        );

        if (result['uid'] != null && mounted) {
          await widget.firestoreService.createUserProfile(
            uid: result['uid']!,
            email: _emailController.text.trim(),
            fullName: _fullNameController.text.trim(),
            country: _selectedCountry ?? '',
            state: _selectedState ?? '',
            city: _cityController.text.trim(),
            referredBy: widget.referredBy.isNotEmpty ? widget.referredBy : null,
          );

          Navigator.of(context).pop();
        }
      } catch (e) {
        debugPrint('❌ Registration error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final statesForSelectedCountry = statesByCountry[_selectedCountry] ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: const InputDecoration(labelText: 'Confirm Password'),
                obscureText: true,
                validator: (value) =>
                    value != _passwordController.text ? 'Passwords do not match' : null,
              ),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Country'),
                value: _selectedCountry,
                items: countries
                    .map((country) => DropdownMenuItem(
                          value: country,
                          child: Text(country),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCountry = value;
                    _selectedState = null;
                  });
                },
                validator: (value) => value == null ? 'Required' : null,
              ),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'State/Province'),
                value: _selectedState,
                items: statesForSelectedCountry
                    .map((state) => DropdownMenuItem(
                          value: state,
                          child: Text(state),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() => _selectedState = value);
                },
                validator: (value) => value == null ? 'Required' : null,
              ),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(labelText: 'City'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              if (_showSponsorField)
                TextFormField(
                  controller: _sponsorController,
                  readOnly: true,
                  decoration: const InputDecoration(labelText: 'Your Sponsor'),
                ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _register,
                child: const Text('Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// PATCHED — new_registration_screen.dart with password confirmation, dynamic country/state dropdowns, sponsor display

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
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final user = await AuthService().registerWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        if (user != null) {
          final newUser = UserModel(
            uid: user.uid,
            email: _emailController.text.trim(),
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
            country: _selectedCountry,
            state: _selectedState,
            city: _cityController.text.trim(),
            referralCode: _generateReferralCode(_firstNameController.text.trim(), user.uid),
            referredBy: _referralCodeToSave,
            createdAt: DateTime.now(),
          );

          await FirestoreService().createUser(newUser.toMap());
          SessionManager().setCurrentUser(newUser);

          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const DashboardScreen()),
            );
          }
        } else {
          setState(() {
            _errorMessage = 'Registration failed. Please try again.';
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

  String _generateReferralCode(String name, String uid) {
    return '${name.toLowerCase()}-${uid.substring(0, 4)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 20),
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(labelText: 'First Name'),
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(labelText: 'Last Name'),
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: const InputDecoration(labelText: 'Confirm Password'),
                obscureText: true,
                validator: (value) => value != _passwordController.text ? 'Passwords do not match' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedCountry,
                items: countryStateMap.keys
                    .map((country) => DropdownMenuItem(
                          value: country,
                          child: Text(country),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCountry = value!;
                    _selectedState = null;
                  });
                },
                decoration: const InputDecoration(labelText: 'Country'),
              ),
              DropdownButtonFormField<String>(
                value: _selectedState,
                items: _statesForSelectedCountry
                    .map((state) => DropdownMenuItem(
                          value: state,
                          child: Text(state),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedState = value;
                  });
                },
                decoration: const InputDecoration(labelText: 'State/Province'),
              ),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(labelText: 'City'),
              ),
              if (_sponsorName != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0, bottom: 6.0),
                  child: Row(
                    children: [
                      const Text('Your Sponsor: ', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(_sponsorName!)
                    ],
                  ),
                ),
              const SizedBox(height: 20),
              if (_isLoading) const CircularProgressIndicator(),
              if (_errorMessage != null) ...[
                Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 10),
              ],
              ElevatedButton(
                onPressed: _isLoading ? null : _register,
                child: const Text('Create Account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

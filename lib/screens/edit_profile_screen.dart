// CLEAN PATCHED — edit_profile_screen.dart with null-safe assignments for all fields

import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/session_manager.dart';
import '../data/states_by_country.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();

  String _selectedCountry = 'United States';
  String _selectedState = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final currentUser = await SessionManager().getCurrentUser();
    if (currentUser != null) {
      print('🧠 EditProfileScreen — currentUser: ${currentUser.firstName}');
      setState(() {
        _firstNameController.text = currentUser.firstName ?? '';
        _lastNameController.text = currentUser.lastName ?? '';
        _cityController.text = currentUser.city ?? '';
        _selectedCountry = currentUser.country ?? 'United States';
        _selectedState = currentUser.state ?? '';
      });
    }
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      final currentUser = await SessionManager().getCurrentUser();
      if (currentUser != null) {
        print('📦 EditProfileScreen — calling updateUser with UID: ${currentUser.uid}');
        final updatedUser = currentUser.copyWith(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          city: _cityController.text.trim(),
          country: _selectedCountry,
          state: _selectedState,
        );
        await FirestoreService().updateUser(currentUser.uid, updatedUser.toMap());
        await SessionManager().setCurrentUser(updatedUser);
        if (mounted) Navigator.pop(context);
      }
    }
  }

  List<String> _getStatesForCountry(String country) {
    return countryStateMap[country] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final stateOptions = _getStatesForCountry(_selectedCountry);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
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
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCountry,
                items: countryStateMap.keys
                    .map((country) => DropdownMenuItem(
                          value: country,
                          child: Text(country),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCountry = value;
                      _selectedState = '';
                    });
                  }
                },
                decoration: const InputDecoration(labelText: 'Country'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedState.isNotEmpty ? _selectedState : null,
                items: stateOptions
                    .map((state) => DropdownMenuItem(
                          value: state,
                          child: Text(state),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _selectedState = value ?? ''),
                decoration: const InputDecoration(labelText: 'State/Province'),
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(labelText: 'City'),
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 30),
              Center(
                child: ElevatedButton.icon(
                  onPressed: _saveChanges,
                  icon: const Icon(Icons.save),
                  label: const Text('Save Changes'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                    textStyle: const TextStyle(fontSize: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
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

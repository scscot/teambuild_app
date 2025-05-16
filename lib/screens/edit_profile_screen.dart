// PATCHED — edit_profile_screen.dart with UID diagnostics in _saveChanges()

import 'package:flutter/material.dart';
import 'package:tbp/models/user_model.dart';
import 'package:tbp/services/firestore_service.dart';
import 'package:tbp/services/session_manager.dart';
import 'package:tbp/data/states_by_country.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _cityController;
  String? _selectedCountry;
  String? _selectedState;
  List<String> _states = [];

  @override
  void initState() {
    super.initState();
    final user = SessionManager().currentUser;
    _firstNameController = TextEditingController(text: user?.firstName ?? '');
    _lastNameController = TextEditingController(text: user?.lastName ?? '');
    _selectedCountry = user?.country;
    _selectedState = user?.state;
    _cityController = TextEditingController(text: user?.city ?? '');
    if (_selectedCountry != null) {
      _states = countryStateMap[_selectedCountry!] ?? [];
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      final currentUser = SessionManager().currentUser;
      print('🧠 EditProfileScreen — currentUser: $currentUser');
      if (currentUser == null) {
        print('❌ No current user found in session. Cannot save changes.');
        return;
      }
      if (currentUser.uid.isEmpty) {
        print('❌ EditProfileScreen — currentUser.uid is empty!');
        return;
      }

      final updatedUser = currentUser.copyWith(
  uid: currentUser.uid,
  firstName: _firstNameController.text.trim(),
  lastName: _lastNameController.text.trim(),
  country: _selectedCountry,
  state: _selectedState,
  city: _cityController.text.trim(),
);

      print('📦 EditProfileScreen — calling updateUser with UID: ${updatedUser.uid}');
      await FirestoreService().updateUser(updatedUser.uid, updatedUser.toMap());
      SessionManager().setCurrentUser(updatedUser);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
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
              DropdownButtonFormField<String>(
                value: _selectedCountry,
                decoration: const InputDecoration(labelText: 'Country'),
                items: countryStateMap.keys
                    .map((country) => DropdownMenuItem(
                          value: country,
                          child: Text(country),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCountry = value;
                    _states = countryStateMap[_selectedCountry!] ?? [];
                    _selectedState = null;
                  });
                },
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
              ),
              DropdownButtonFormField<String>(
                value: _selectedState,
                decoration: const InputDecoration(labelText: 'State/Province'),
                items: _states
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
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(labelText: 'City'),
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveChanges,
                child: const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

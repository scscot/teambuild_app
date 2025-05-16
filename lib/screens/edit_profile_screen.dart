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
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();

  String _selectedCountry = '';
  String _selectedState = '';
  List<String> _states = [];

  @override
  void initState() {
    super.initState();
    final user = SessionManager().currentUser;
    if (user != null) {
      print('🧠 EditProfileScreen — currentUser: ${user.firstName}');
      _firstNameController.text = user.firstName;
      _lastNameController.text = user.lastName;
      _selectedCountry = user.country ?? '';
      _selectedState = user.state ?? '';
      _cityController.text = user.city ?? '';
      _states = countryStateMap[_selectedCountry] ?? [];
    }
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      final currentUser = SessionManager().currentUser;
      if (currentUser != null) {
        print('📦 EditProfileScreen — calling updateUser with UID: ${currentUser.uid}');
        final updatedUser = currentUser.copyWith(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          country: _selectedCountry,
          state: _selectedState,
          city: _cityController.text.trim(),
        );

        await FirestoreService().updateUser(updatedUser.uid, updatedUser.toMap());
        SessionManager().setCurrentUser(updatedUser);
        if (mounted) Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        automaticallyImplyLeading: true,
      ),
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
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedCountry.isNotEmpty ? _selectedCountry : null,
                decoration: const InputDecoration(labelText: 'Country'),
                items: countryStateMap.keys.map((String country) {
                  return DropdownMenuItem<String>(
                    value: country,
                    child: Text(country),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCountry = newValue ?? '';
                    _states = countryStateMap[_selectedCountry] ?? [];
                    _selectedState = '';
                  });
                },
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedState.isNotEmpty ? _selectedState : null,
                decoration: const InputDecoration(labelText: 'State/Province'),
                items: _states.map((String state) {
                  return DropdownMenuItem<String>(
                    value: state,
                    child: Text(state),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedState = newValue ?? '';
                  });
                },
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
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

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _cityController.dispose();
    super.dispose();
  }
}

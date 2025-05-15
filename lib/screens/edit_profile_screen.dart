// FINAL PATCHED — edit_profile_screen.dart (replaced saveToStorage → persistUser)

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tbp/services/session_manager.dart';
import 'package:tbp/models/user_model.dart';
import '../data/states_by_country.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _cityController;
  String? _selectedCountry;
  String? _selectedState;

  bool _isSaving = false;
  String? _errorMessage;

  List<String> _statesForCountry = [];

  @override
  void initState() {
    super.initState();
    final initialUser = SessionManager.instance.currentUser;
    _nameController = TextEditingController(text: initialUser?.fullName ?? '');
    _emailController = TextEditingController(text: initialUser?.email ?? '');
    _cityController = TextEditingController(text: initialUser?.city ?? '');
    _selectedCountry = initialUser?.country;
    _selectedState = initialUser?.state;

    if (_selectedCountry != null && statesByCountry.containsKey(_selectedCountry)) {
      final rawList = statesByCountry[_selectedCountry!]!;
      _statesForCountry = rawList.map((s) => s.trim()).toSet().toList();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Full Name'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCountry,
              items: statesByCountry.keys.map((country) {
                return DropdownMenuItem(value: country, child: Text(country));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCountry = value;
                  _selectedState = null;
                  _statesForCountry = value != null && statesByCountry.containsKey(value)
                      ? statesByCountry[value]!.map((s) => s.trim()).toSet().toList()
                      : [];
                });
              },
              decoration: const InputDecoration(labelText: 'Country'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _statesForCountry.contains(_selectedState) ? _selectedState : null,
              items: _statesForCountry.map((state) {
                return DropdownMenuItem(value: state, child: Text(state));
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedState = value);
              },
              decoration: const InputDecoration(labelText: 'State / Province'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _cityController,
              decoration: const InputDecoration(labelText: 'City'),
            ),
            const SizedBox(height: 24),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              ),
            Center(
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveChanges,
                child: _isSaving ? const CircularProgressIndicator() : const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveChanges() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    await SessionManager.instance.loadFromStorage();
    var user = SessionManager.instance.currentUser;

    if (user == null || user.uid.isEmpty) {
      setState(() {
        _isSaving = false;
        _errorMessage = 'User session not available. Please log out and log back in.';
      });
      debugPrint('❌ Blocked update: UID was null or empty.');
      return;
    }

    debugPrint('🛰️ Attempting Firestore update with:');
    debugPrint(' - fullName: ${_nameController.text.trim()}');
    debugPrint(' - city: ${_cityController.text.trim()}');
    debugPrint(' - state: $_selectedState');
    debugPrint(' - country: $_selectedCountry');

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'fullName': _nameController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _selectedState ?? '',
        'country': _selectedCountry ?? '',
      });

      final refreshedDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final refreshedData = refreshedDoc.data() ?? {};

      if (refreshedData['email'] != null && refreshedData['fullName'] != null) {
        final updatedUser = UserModel.fromFirestore(refreshedData);

        SessionManager.instance.saveSession(
          user: updatedUser,
          idToken: SessionManager.instance.idToken ?? '',
          accessToken: SessionManager.instance.accessToken ?? '',
        );
        await SessionManager.instance.persistUser(updatedUser); // PATCHED: replaced saveToStorage()
        debugPrint('✅ User model refreshed successfully.');
      } else {
        debugPrint('❌ Refreshed Firestore data is missing required fields.');
      }

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _errorMessage = 'Failed to save changes. Please try again');
      debugPrint('❌ Firestore update failed with: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

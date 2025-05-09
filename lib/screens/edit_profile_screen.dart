import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tbp/services/session_manager.dart';
import 'package:tbp/models/user_model.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _cityController;
  late final TextEditingController _stateController;
  late final TextEditingController _countryController;

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final user = SessionManager.instance.currentUser;
    _nameController = TextEditingController(text: user?.fullName ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _cityController = TextEditingController(text: user?.city ?? '');
    _stateController = TextEditingController(text: user?.state ?? '');
    _countryController = TextEditingController(text: user?.country ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            _buildField('Full Name', _nameController),
            _buildField('Email', _emailController, readOnly: true),
            _buildField('City', _cityController),
            _buildField('State/Province', _stateController),
            _buildField('Country', _countryController),
            const SizedBox(height: 20),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              ),
            ElevatedButton(
              onPressed: _isSaving ? null : _saveChanges,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save Changes'),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _saveChanges() async {
    final user = SessionManager.instance.currentUser;
    if (user == null) {
      print('❌ No user in session manager.');
      return;
    }

    print('⚠️ user.uid = ${user.uid}');
    if (user.uid.isEmpty) {
      print('❌ user.uid is empty!');
      setState(() => _errorMessage = 'Missing user ID. Please re-login.');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      print('Attempting update for UID: ${user.uid}');

      final userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final docSnapshot = await userDocRef.get();

      if (!docSnapshot.exists) {
        print('Document does not exist for UID: ${user.uid}');
        setState(() {
          _errorMessage = 'User document not found in Firestore.';
        });
        return;
      }

      final updatedData = <String, dynamic>{
        'fullName': _nameController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'country': _countryController.text.trim(),
      };

      print('Updating with data: $updatedData');
      await userDocRef.update(updatedData);

      final refreshedDoc = await userDocRef.get();
      print('Refreshed document data: ${refreshedDoc.data()}');

      if (refreshedDoc.exists) {
        SessionManager.instance.currentUser = UserModel.fromJson({
          ...?refreshedDoc.data(),
          'uid': user.uid,
        });
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error during save: $e');
      setState(() {
        _errorMessage = 'Failed to save changes. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Widget _buildField(String label, TextEditingController controller, {bool readOnly = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

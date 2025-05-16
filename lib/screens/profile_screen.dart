// CLEAN PATCH — profile_screen.dart with full layout, sponsor resolution, image upload, biometrics toggle, and diagnostics

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/session_manager.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _user;
  String? _sponsorName;
  bool _biometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadBiometricSetting();
  }

  Future<void> _loadBiometricSetting() async {
    final enabled = await SessionManager().biometricEnabled;
    setState(() => _biometricEnabled = enabled);
  }

  Future<void> _loadUserData() async {
    final currentUser = SessionManager().currentUser;
    if (currentUser != null) {
      print('✅ Current user loaded: ${currentUser.firstName} ${currentUser.lastName}');
      setState(() => _user = currentUser);

      if (currentUser.referredBy != null && currentUser.referredBy!.isNotEmpty) {
        print('🔎 Looking up sponsor name by referralCode: ${currentUser.referredBy}');
        try {
          final sponsor = await FirebaseFirestore.instance
              .collection('users')
              .where('referralCode', isEqualTo: currentUser.referredBy)
              .limit(1)
              .get();

          if (sponsor.docs.isNotEmpty) {
            final sponsorData = sponsor.docs.first.data();
            setState(() => _sponsorName = '${sponsorData['firstName']} ${sponsorData['lastName']}');
            print('✅ Sponsor name resolved: $_sponsorName');
          }
        } catch (e) {
          print('❌ Failed to load sponsor data: $e');
        }
      }
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 600,
    );

    if (pickedFile != null && _user != null) {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child(_user!.uid)
          .child('profile_${DateTime.now().millisecondsSinceEpoch}.jpg');

      final uploadTask = storageRef.putFile(File(pickedFile.path));
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      final updatedUser = _user!.copyWith(photoUrl: downloadUrl);
      await FirestoreService().updateUser(updatedUser.uid, updatedUser.toMap());
      SessionManager().setCurrentUser(updatedUser);
      setState(() => _user = updatedUser);
    }
  }

  void _navigateToEditProfile() {
    print('✏️ Navigating to EditProfileScreen...');
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
    ).then((_) {
      print('🔁 Returned from EditProfileScreen. Refreshing profile data.');
      _loadUserData();
    });
  }

  void _toggleBiometric(bool value) async {
    await SessionManager().setBiometricEnabled(value);
    setState(() => _biometricEnabled = value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              SessionManager().clearSession();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          )
        ],
      ),
      body: _user == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: GestureDetector(
                      onTap: _pickAndUploadImage,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundImage: _user!.photoUrl != null && _user!.photoUrl!.isNotEmpty
                                ? NetworkImage(_user!.photoUrl!)
                                : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
                          ),
                          Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black54,
                            ),
                            padding: const EdgeInsets.all(6),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildInfoRow('Name', '${_user!.firstName} ${_user!.lastName}'),
                  _buildInfoRow('Email', _user!.email),
                  _buildInfoRow('City', _user!.city ?? 'N/A'),
                  _buildInfoRow('State/Province', _user!.state ?? 'N/A'),
                  _buildInfoRow('Country', _user!.country ?? 'N/A'),
                  _buildInfoRow(
                    'Join Date',
                    _user!.createdAt != null ? DateFormat.yMMMMd().format(_user!.createdAt!) : 'N/A',
                  ),
                  if (_sponsorName != null && _sponsorName!.isNotEmpty)
                    _buildInfoRow('Sponsor Name', _sponsorName!),
                  const SizedBox(height: 30),
                  SwitchListTile(
                    title: const Text('Enable Biometric Login'),
                    value: _biometricEnabled,
                    onChanged: _toggleBiometric,
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: _navigateToEditProfile,
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit Profile'),
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
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}

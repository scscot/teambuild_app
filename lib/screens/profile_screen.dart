// CLEAN PATCHED — profile_screen.dart with biometric availability check and improved toggle label

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:local_auth/local_auth.dart';
import 'dart:io';
import '../services/session_manager.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
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
  bool _biometricsAvailable = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadBiometricSetting();
    _checkBiometricSupport();
  }

  Future<void> _checkBiometricSupport() async {
    final auth = LocalAuthentication();
    final available = await auth.canCheckBiometrics;
    final supported = await auth.isDeviceSupported();
    setState(() {
      _biometricsAvailable = available && supported;
    });
  }

  Future<void> _loadUserData() async {
    final currentUser = await SessionManager().getCurrentUser();
    if (currentUser != null) {
      print('✅ Current user loaded: ${currentUser.firstName} ${currentUser.lastName}');
      setState(() => _user = currentUser);

      if (currentUser.referredBy != null && currentUser.referredBy!.isNotEmpty) {
        print('🔎 Looking up sponsor name by referralCode: ${currentUser.referredBy}');
        try {
          final sponsorName = await FirestoreService().getSponsorNameByReferralCode(currentUser.referredBy!);
          if (mounted) {
            print('✅ Sponsor name resolved: $sponsorName');
            setState(() => _sponsorName = sponsorName);
          }
        } catch (e) {
          print('❌ Failed to load sponsor data: $e');
        }
      }
    }
  }

  void _showImageSourceActionSheetWrapper() {
    _showImageSourceActionSheet(context);
  }

  Future<void> _showImageSourceActionSheet(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Take a Photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source != null) {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        final file = File(pickedFile.path);

        try {
          final authUser = FirebaseAuth.instance.currentUser;
          if (authUser == null) {
            print('❌ No FirebaseAuth user found. Cannot upload image.');
            return;
          }

          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => const Center(child: CircularProgressIndicator()),
          );

          final storageRef = FirebaseStorage.instance
              .ref()
              .child('profile_photos/${authUser.uid}/profile.jpg');

          await storageRef.putFile(file);
          final imageUrl = await storageRef.getDownloadURL();

          await FirestoreService().updateUserField(authUser.uid, 'photoUrl', imageUrl);

          final updatedUser = _user!.copyWith(photoUrl: imageUrl);
          await SessionManager().saveUser(updatedUser);
          setState(() => _user = updatedUser);

          print('✅ Image uploaded and profile updated successfully');
        } catch (e) {
          print('❌ Error uploading image: $e');
        } finally {
          Navigator.of(context).pop();
        }
      }
    }
  }

  Future<void> _loadBiometricSetting() async {
    final enabled = await SessionManager().getBiometricEnabled();
    setState(() => _biometricEnabled = enabled);
  }

  Future<void> _toggleBiometric(bool value) async {
    setState(() => _biometricEnabled = value);
    await SessionManager().setBiometricEnabled(value);
  }

  void _navigateToEditProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
    ).then((_) => _loadUserData());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        automaticallyImplyLeading: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await SessionManager().clearSession();
              if (mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
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
                      onTap: _showImageSourceActionSheetWrapper,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundImage: _user!.photoUrl != null && _user!.photoUrl!.isNotEmpty
                                ? NetworkImage(_user!.photoUrl!)
                                : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
                          ),
                          GestureDetector(
                            onTap: _showImageSourceActionSheetWrapper,
                            child: Container(
                              decoration: BoxDecoration(
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
                  _buildInfoRow('Join Date', _user!.createdAt != null
                      ? DateFormat.yMMMMd().format(_user!.createdAt!)
                      : 'N/A'),
                  if (_sponsorName != null && _sponsorName!.isNotEmpty)
                    _buildInfoRow('Sponsor Name', _sponsorName!),
                  const SizedBox(height: 30),
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
                  const SizedBox(height: 20),
                  if (_biometricsAvailable)
                    SwitchListTile(
                      title: const Text('Enable Face ID / Touch ID'),
                      value: _biometricEnabled,
                      onChanged: _toggleBiometric,
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

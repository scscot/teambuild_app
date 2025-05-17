// PATCHED — profile_screen.dart with fixed label rendering and name display

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
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

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadBiometricSetting();
  }

  Future<void> _loadUserData() async {
    final currentUser = await SessionManager().getCurrentUser();
    if (currentUser != null) {
      print('✅ Current user loaded: ${currentUser.firstName} ${currentUser.lastName}');
      setState(() {
        _user = currentUser;
      });
      if (currentUser.referredBy != null && currentUser.referredBy!.isNotEmpty) {
        print('🔎 Looking up sponsor name by referralCode: ${currentUser.referredBy}');
        try {
          final sponsorName = await FirestoreService().getSponsorNameByReferralCode(currentUser.referredBy!);
          if (mounted) {
            print('✅ Sponsor name resolved: $sponsorName');
            setState(() {
              _sponsorName = sponsorName;
            });
          }
        } catch (e) {
          print('❌ Failed to load sponsor data: $e');
        }
      } else {
        print('ℹ️ No referredBy code found for this user');
      }
    } else {
      print('❌ No current user found in SessionManager');
    }
  }

  final ImagePicker _picker = ImagePicker();

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
        File imageFile = File(pickedFile.path);
        try {
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('user_profile_photos/${_user!.uid}.jpg');

          await storageRef.putFile(imageFile);
          final downloadUrl = await storageRef.getDownloadURL();

          await FirestoreService().updateUserField(_user!.uid, 'photoUrl', downloadUrl);

          final updatedUser = _user!.copyWith(photoUrl: downloadUrl);
          await SessionManager().saveUser(updatedUser);
          setState(() {
            _user = updatedUser;
          });

          print('✅ Image uploaded and profile updated successfully');
        } catch (e) {
          print('❌ Error uploading image: $e');
        }
      }
    }
  }

  Future<void> _loadBiometricSetting() async {
    final enabled = await SessionManager().getBiometricEnabled();
    setState(() {
      _biometricEnabled = enabled;
    });
  }

  Future<void> _toggleBiometric(bool value) async {
    setState(() => _biometricEnabled = value);
    await SessionManager().setBiometricEnabled(value);
  }

  Future<void> _pickImage() async {
    if (_user == null) return;
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );

    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images/${_user!.uid}/profile_${DateTime.now().millisecondsSinceEpoch}.jpg');

      final uploadTask = await storageRef.putFile(file);
      final imageUrl = await uploadTask.ref.getDownloadURL();

      await FirestoreService().updateUser(_user!.uid, {'photoUrl': imageUrl});

      final updatedUser = _user!.copyWith(photoUrl: imageUrl);
      await SessionManager().setCurrentUser(updatedUser);

      if (mounted) {
        setState(() {
          _user = updatedUser;
        });
      }
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
              if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
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
                      onTap: _pickImage,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          GestureDetector(
                            onTap: () => _showImageSourceActionSheet(context),
                            child: CircleAvatar(
                              radius: 50,
                              backgroundImage: _user!.photoUrl != null && _user!.photoUrl!.isNotEmpty
                                  ? NetworkImage(_user!.photoUrl!)
                                  : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _showImageSourceActionSheet(context),
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
                  SwitchListTile(
                    title: const Text('Enable Biometric Login'),
                    value: _biometricEnabled,
                    onChanged: _toggleBiometric,
                  )
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

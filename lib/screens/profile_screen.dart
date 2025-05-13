// PATCHED: Added profile photo upload (camera + gallery) support, preserving original structure
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tbp/models/user_model.dart';
import 'package:tbp/services/session_manager.dart';
import 'package:tbp/services/firestore_service.dart';
import 'package:tbp/services/biometric_auth_service.dart';
import 'package:tbp/screens/edit_profile_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:tbp/screens/login_screen.dart';

String formatDate(DateTime? date) {
  if (date == null) return 'Unknown';
  return DateFormat.yMMMMd().format(date);
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? sponsorName;
  bool biometricsEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSponsorName();
    _loadBiometricPreference();
  }

  Future<void> _loadSponsorName() async {
    final referredBy = SessionManager.instance.currentUser?.referredBy;
    if (referredBy != null && referredBy.isNotEmpty) {
      try {
        final sponsorData = await FirestoreService().getUserProfileByReferralCode(referredBy);
        if (sponsorData != null && mounted) {
          setState(() {
            sponsorName = sponsorData['fullName'] ?? '';
          });
        }
      } catch (e) {
        debugPrint('Error fetching sponsor name: $e');
      }
    }
  }

  Future<void> _loadBiometricPreference() async {
    final enabled = await BiometricAuthService().getBiometricPreference();
    if (mounted) setState(() => biometricsEnabled = enabled);
  }

  Future<void> _toggleBiometric(bool enabled) async {
    if (enabled) {
      final available = await BiometricAuthService().isBiometricAvailable();
      if (!available) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Biometric authentication is not available on this device.')),
        );
        return;
      }
      await BiometricAuthService().setBiometricPreference(true);
    } else {
      await BiometricAuthService().clearBiometricPreference();
    }
    setState(() => biometricsEnabled = enabled);
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 70);
    if (pickedFile != null) {
      final photoUrl = pickedFile.path;
      final user = SessionManager.instance.currentUser;
      if (user != null) {
        await FirestoreService().updateUserProfile(user.uid, {'photoUrl': photoUrl});
        SessionManager.instance.persistUser(user.copyWith(photoUrl: photoUrl));
        setState(() {});
      }
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Library'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = SessionManager.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('No user data available')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await SessionManager.instance.signOut();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Center(
              child: GestureDetector(
                onTap: _showImageSourceSheet,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey.shade300,
                      backgroundImage: user.photoUrl != null ? FileImage(File(user.photoUrl!)) : null,
                      child: user.photoUrl == null ? const Icon(Icons.person, size: 40, color: Colors.white) : null,
                    ),
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.camera_alt, size: 18, color: Colors.grey.shade700),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _infoRow('Name', user.fullName ?? ''),
            _infoRow('Email', user.email ?? ''),
            if ((user.city ?? '').isNotEmpty) _infoRow('City', user.city!),
            if ((user.state ?? '').isNotEmpty) _infoRow('State/Province', user.state!),
            if ((user.country ?? '').isNotEmpty) _infoRow('Country', user.country!),
            _infoRow('Joined Date', formatDate(user.createdAt)),
            if (sponsorName != null && sponsorName!.isNotEmpty)
              _infoRow('Your Sponsor', sponsorName!),
            const SizedBox(height: 24),
            SwitchListTile(
              title: const Text('Enable Face ID / Touch ID Login'),
              value: biometricsEnabled,
              onChanged: _toggleBiometric,
              activeColor: Colors.indigo,
            ),
            const SizedBox(height: 12),
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EditProfileScreen(),
                    ),
                  );

                  final uid = SessionManager.instance.currentUser?.uid;
                  if (uid != null && uid.isNotEmpty) {
                    final updatedUser = await FirestoreService().getUserProfileById(uid);
                    if (updatedUser != null && mounted) {
                      SessionManager.instance.currentUser = updatedUser;
                      setState(() {});
                      _loadSponsorName();
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple.shade50,
                  foregroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text('Edit Profile'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool isLink = false, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          Expanded(
            child: isLink
                ? GestureDetector(
                    onTap: onTap,
                    child: Text(
                      value,
                      style: const TextStyle(color: Colors.deepPurple, decoration: TextDecoration.underline),
                    ),
                  )
                : Text(value),
          ),
        ],
      ),
    );
  }
}

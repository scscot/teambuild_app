// FINAL PATCHED: profile_screen.dart — Full Profile with Image Upload and Sponsor Display

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
import 'package:firebase_storage/firebase_storage.dart';

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
  UserModel? user;

  @override
  void initState() {
    super.initState();
    user = SessionManager.instance.currentUser;
    _forceRehydrateIfNeeded();
    _loadSponsorName();
    _loadBiometricPreference();
  }

  Future<void> _forceRehydrateIfNeeded() async {
    final current = SessionManager.instance.currentUser;
    if (current == null) return;

    final shouldRefresh = (current.fullName ?? '').isEmpty ||
        (current.city ?? '').isEmpty ||
        (current.country ?? '').isEmpty ||
        (current.photoUrl ?? '').isEmpty;

    if (shouldRefresh) {
      try {
        final updatedUser = await FirestoreService().getUserProfileById(current.uid);
        if (updatedUser != null && mounted) {
          SessionManager.instance.currentUser = updatedUser;
          await SessionManager.instance.persistUser(updatedUser);
          setState(() => user = updatedUser);
          debugPrint('♻️ Forced Firestore rehydrate on profile load');
        }
      } catch (e) {
        debugPrint('❌ Failed to rehydrate profile from Firestore: $e');
      }
    }
  }

  Future<void> _loadSponsorName() async {
    debugPrint('🔍 Entering _loadSponsorName');
    debugPrint('👤 referredBy (evaluated) = ${user?.referredBy}');
    final referredBy = user?.referredBy;
    if (referredBy != null && referredBy.isNotEmpty) {
      try {
        final sponsorData = await FirestoreService().getUserProfileByReferralCode(referredBy);
        debugPrint('📦 sponsorData (evaluated) = ${sponsorData.toString()}');
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

  void _toggleBiometric(bool enabled) async {
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
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source, imageQuality: 70);
      if (pickedFile != null) {
        final liveUser = SessionManager.instance.currentUser;
        final password = await SessionManager.instance.getStoredPassword();

        if (liveUser == null || liveUser.uid.isEmpty) {
          debugPrint('❌ Cannot upload — user UID is missing or null');
          return;
        }

        if (password != null) {
          await FirestoreService().ensureFirebaseAuthSession(email: liveUser.email ?? '', password: password);
          final file = File(pickedFile.path);
          debugPrint('📤 Uploading image from: ${file.path}');
          final url = await uploadProfileImage(file, liveUser.uid);
          if (url != null) {
            await FirestoreService().updateUserProfile(liveUser.uid, {'photoUrl': url});
            final updatedUser = await FirestoreService().getUserProfileById(liveUser.uid);
            if (updatedUser != null) {
              SessionManager.instance.currentUser = updatedUser;
              SessionManager.instance.persistUser(updatedUser);
              setState(() => user = updatedUser);
            }
          } else {
            debugPrint('❌ uploadProfileImage() returned null URL');
          }
        } else {
          debugPrint('❌ Cannot upload — password is null');
        }
      } else {
        debugPrint('⚠️ No image picked');
      }
    } catch (e, stack) {
      debugPrint('❌ Exception during _pickImage: $e');
      debugPrint('📍 Stack trace: $stack');
    }
  }

  Future<String?> uploadProfileImage(File imageFile, String uid) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'profile_$timestamp.jpg';
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images/$uid/$fileName');

      debugPrint('📂 Target storage path: profile_images/$uid/$fileName');

      final uploadTask = await storageRef.putFile(imageFile);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      debugPrint('❌ Upload error in uploadProfileImage: $e');
      return null;
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
    final currentUser = SessionManager.instance.currentUser;
    if (currentUser == null) {
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
                      backgroundImage: currentUser.photoUrl != null && currentUser.photoUrl!.startsWith('http')
                          ? NetworkImage(currentUser.photoUrl!)
                          : null,
                      child: currentUser.photoUrl == null
                          ? const Icon(Icons.person, size: 40, color: Colors.white)
                          : null,
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
            _infoRow('Name', currentUser.fullName ?? ''),
            _infoRow('Email', currentUser.email ?? ''),
            if ((currentUser.city ?? '').isNotEmpty) _infoRow('City', currentUser.city!),
            if ((currentUser.state ?? '').isNotEmpty) _infoRow('State/Province', currentUser.state!),
            if ((currentUser.country ?? '').isNotEmpty) _infoRow('Country', currentUser.country!),
            _infoRow('Joined Date', formatDate(currentUser.createdAt)),
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
                      setState(() => user = updatedUser);
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

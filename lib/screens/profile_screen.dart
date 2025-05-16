// FULLY RESTORED + PATCHED — profile_screen.dart with UI layout + sponsor first/last name logic (fixed FirebaseFirestore import)

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/session_manager.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import 'edit_profile_screen.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _user;
  String? _sponsorName;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final currentUser = SessionManager().currentUser;
    if (currentUser != null) {
      print('✅ Current user loaded: ${currentUser.firstName} ${currentUser.lastName}');
      setState(() {
        _user = currentUser;
      });
      if (currentUser.referredBy != null && currentUser.referredBy!.isNotEmpty) {
        print('🔎 Looking up sponsor name for UID: ${currentUser.referredBy}');
        final doc = await FirebaseFirestore.instance.collection('users').doc(currentUser.referredBy).get();
        final data = doc.data();
        if (data != null) {
          final first = data['firstName'] ?? '';
          final last = data['lastName'] ?? '';
          final name = '$first $last'.trim();
          if (mounted) {
            print('✅ Sponsor name resolved: $name');
            setState(() {
              _sponsorName = name.isEmpty ? null : name;
            });
          }
        } else {
          print('⚠️ Sponsor user doc not found');
        }
      } else {
        print('ℹ️ No referredBy code found for this user');
      }
    } else {
      print('❌ No current user found in SessionManager');
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
      ),
      body: _user == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
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
                      ],
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
                    _user!.createdAt != null
                        ? DateFormat.yMMMMd().format(_user!.createdAt!)
                        : 'N/A',
                  ),
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

// PATCHED — Fully restored from original REST-based profile_screen.dart layout with SDK sponsor support

import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final currentUser = SessionManager().currentUser;
    if (currentUser != null) {
      setState(() {
        _user = currentUser;
      });
      if (currentUser.referredBy != null && currentUser.referredBy!.isNotEmpty) {
        final sponsorName = await FirestoreService().getUserFullName(currentUser.referredBy!);
        if (mounted) {
          setState(() {
            _sponsorName = sponsorName;
          });
        }
      }
    }
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
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _navigateToEditProfile,
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
                  const Text('Account Info', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text('Name: ${_user!.firstName} ${_user!.lastName}'),
                  Text('Email: ${_user!.email}'),
                  Text('Country: ${_user!.country ?? 'N/A'}'),
                  Text('State/Province: ${_user!.state ?? 'N/A'}'),
                  Text('City: ${_user!.city ?? 'N/A'}'),
                  Text('Referral Code: ${_user!.referralCode ?? 'N/A'}'),
                  Text('Sponsor: ${_sponsorName ?? 'N/A'}'),
                ],
              ),
            ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:tbp/models/user_model.dart';
import 'package:tbp/services/session_manager.dart';
import 'package:tbp/services/firestore_service.dart';
import 'package:tbp/screens/edit_profile_screen.dart';
import 'package:tbp/screens/change_password_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? sponsorName;

  @override
  void initState() {
    super.initState();
    _loadSponsorName();
  }

  // PATCH START: use referralCode-based lookup instead of UID
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
        debugPrint('Error fetching sponsor name: \$e');
      }
    }
  }
  // PATCH END

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
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // PATCH START: Add profile picture at top of profile screen
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage: NetworkImage(
                      user.photoUrl ?? 'https://www.gravatar.com/avatar/placeholder?s=200&d=mp'
                    ),
                  ),
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.camera_alt, size: 18, color: Colors.grey.shade700),
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),
            // PATCH END
            _infoRow('Name', user.fullName ?? ''),
            _infoRow('Email', user.email ?? ''),
            _infoRow('Password', 'Change password', isLink: true, onTap: () => _openChangePasswordModal()),
            if ((user.city ?? '').isNotEmpty) _infoRow('City', user.city!),
            if ((user.state ?? '').isNotEmpty) _infoRow('State/Province', user.state!),
            if ((user.country ?? '').isNotEmpty) _infoRow('Country', user.country!),
            _infoRow('Joined Date', _formatDate(user.createdAt)),
            if (sponsorName != null && sponsorName!.isNotEmpty)
              _infoRow('Your Sponsor', sponsorName!),
            const SizedBox(height: 24),
            // PATCH START: Add centered Edit Profile button
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EditProfileScreen(),
                    ),
                  );
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
            // PATCH END
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

  void _openChangePasswordModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (_) => const ChangePasswordScreen(),
    );
  }

  // PATCH START: Format joined date as 'Month Day, Year'
  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final monthName = months[date.month - 1];
    return '$monthName ${date.day}, ${date.year}';
  }
  // PATCH END
}

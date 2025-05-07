import 'package:flutter/material.dart';
import 'package:tbp/models/user_model.dart';
import 'package:tbp/services/session_manager.dart';
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

  Future<void> _loadSponsorName() async {
    final referredBy = SessionManager.instance.currentUser?.referredBy;
    if (referredBy != null && referredBy.isNotEmpty) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(referredBy).get();
        if (doc.exists && mounted) {
          setState(() {
            sponsorName = doc.data()?['fullName'] ?? "";
          });
        }
      } catch (e) {
        debugPrint('Error fetching sponsor name: $e');
      }
    }
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
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple.shade100,
        child: const Icon(Icons.edit, color: Colors.deepPurple),
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const EditProfileScreen(),
          ));
        },
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow('Name', user.fullName ?? ''),
            _infoRow('Email', user.email ?? ''),
            _infoRow('Password', 'Change password', isLink: true, onTap: () => _openChangePasswordModal()),
            if ((user.city ?? '').isNotEmpty) _infoRow('City', user.city!),
            if ((user.state ?? '').isNotEmpty) _infoRow('State/Province', user.state!),
            if ((user.country ?? '').isNotEmpty) _infoRow('Country', user.country!),
            _infoRow('Joined Date', _formatDate(user.createdAt)),
            if (sponsorName != null && sponsorName!.isNotEmpty)
              _infoRow('Your Sponsor', sponsorName!),
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

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    return '${date.month}/${date.day}/${date.year}';
  }
}

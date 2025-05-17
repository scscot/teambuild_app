// FINAL PATCHED: dashboard_screen.dart — Logout icon in AppBar

import 'package:flutter/material.dart';
import '../services/session_manager.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import 'profile_screen.dart';
import 'downline_team_screen.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  UserModel? user;

  @override
  void initState() {
    super.initState();
    debugPrint("📍 Entered DashboardScreen");
    user = SessionManager.instance.currentUser;
    debugPrint("👤 Dashboard user: $user");

    final uid = user?.uid;
    if (uid != null && uid.isNotEmpty) {
      FirestoreService().getUserProfileById(uid).then((updatedUser) {
        if (updatedUser != null && mounted) {
          SessionManager.instance.currentUser = updatedUser;
          SessionManager.instance.persistUser(updatedUser);
          setState(() => user = updatedUser);
        }
      });
    }
  }

  void _logout(BuildContext context) {
    // AuthService().signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = user?.fullName ?? 'User';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
            tooltip: 'Log Out',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Welcome, $name\!',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfileScreen(),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: Colors.indigo),
              ),
              child: const Text(
                'View Profile',
                style: TextStyle(fontSize: 16, color: Colors.indigo),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DownlineTeamScreen(),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: Colors.indigo),
              ),
              child: const Text(
                'View Downline Team',
                style: TextStyle(fontSize: 16, color: Colors.indigo),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
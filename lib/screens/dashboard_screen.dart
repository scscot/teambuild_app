import 'package:flutter/material.dart';
import '../services/session_manager.dart';
import 'profile_screen.dart';
import 'downline_team_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = SessionManager().currentUser;
    final firstName = currentUser?.firstName ?? 'User';

    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome $firstName!'),
        automaticallyImplyLeading: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              SessionManager().clearSession();
              Navigator.popUntil(context, (route) => route.isFirst);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                ),
                child: const Text('View My Profile'),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DownlineTeamScreen()),
                ),
                child: const Text('View My Downline'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

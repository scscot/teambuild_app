import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/profile_screen.dart';
import '../screens/downline_team_screen.dart';
import '../screens/share_screen.dart';
import '../screens/login_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/join_opportunity_screen.dart';
import '../services/session_manager.dart';
import '../models/user_model.dart';
import 'package:flutter/foundation.dart';
class AppHeaderWithMenu extends StatefulWidget implements PreferredSizeWidget {
  const AppHeaderWithMenu({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<AppHeaderWithMenu> createState() => _AppHeaderWithMenuState();
}

class _AppHeaderWithMenuState extends State<AppHeaderWithMenu> {
  bool showJoinOpportunity = false;

  @override
  void initState() {
    super.initState();
    _checkJoinOpportunityEligibility();
  }

  Future<void> _checkJoinOpportunityEligibility() async {
    final user = await SessionManager().getCurrentUser();
    if (user == null || user.role == 'admin') return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final data = userDoc.data();
      if (data == null) return;

      final bizJoinDate = data['biz_join_date'];
      final directSponsorMin = data['direct_sponsor_min'] ?? 1;
      final totalTeamMin = data['total_team_min'] ?? 1;
      final directCount = data['direct_sponsor_count'] ?? 0;
      final teamCount = data['total_team_count'] ?? 0;

      if (bizJoinDate == null &&
          directCount >= directSponsorMin &&
          teamCount >= totalTeamMin) {
        setState(() => showJoinOpportunity = true);
      }
    } catch (e) {
      debugPrint('❌ Failed to evaluate join opportunity eligibility: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoginScreen =
        context.findAncestorWidgetOfExactType<LoginScreen>() != null;

    return AppBar(
      backgroundColor: const Color(0xFFEDE7F6),
      automaticallyImplyLeading: false,
      title: const Text(
        'TeamBuild Pro',
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
      ),
      centerTitle: true,
      actions: isLoginScreen
          ? null
          : [
              PopupMenuButton<String>(
                icon: const Icon(Icons.menu, color: Colors.black),
                onSelected: (String value) async {
                  switch (value) {
                    case 'dashboard':
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const DashboardScreen()));
                      break;
                    case 'profile':
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ProfileScreen()));
                      break;
                    case 'downline':
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const DownlineTeamScreen(
                                  referredBy: 'demo-user')));
                      break;
                    case 'share':
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => ShareScreen()));
                      break;
                    case 'join':
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const JoinOpportunityScreen()));
                      break;
                    case 'logout':
                      await SessionManager().clearSession();
                      await FirebaseAuth.instance.signOut();
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                      break;
                  }
                },
                itemBuilder: (BuildContext context) => [
                  if (showJoinOpportunity)
                    const PopupMenuItem<String>(
                      value: 'join',
                      child: Text('Join Now!'),
                    ),
                  const PopupMenuItem<String>(
                    value: 'dashboard',
                    child: Text('Dashboard'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'profile',
                    child: Text('Profile'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'downline',
                    child: Text('Downline'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'share',
                    child: Text('Share'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'logout',
                    child: Text('Logout'),
                  ),
                ],
              )
            ],
    );
  }
}

class AppHeaderWithBack extends StatelessWidget implements PreferredSizeWidget {
  const AppHeaderWithBack({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFFEDE7F6),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
      title: const Text(
        'TeamBuild Pro',
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
      ),
      centerTitle: true,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/downline_team_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/share_screen.dart';
import '../services/session_manager.dart';
import '../models/user_model.dart';
import '../widgets/header_widgets.dart';
import '../screens/settings_screen.dart';
import '../screens/join_opportunity_screen.dart';


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  UserModel? _user;
  int? _directSponsorMin;
  int? _totalTeamMin;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserAndSettings();
  }

  Future<void> _loadUserAndSettings() async {
    final sessionUser = await SessionManager().getCurrentUser();

    if (sessionUser == null || sessionUser.uid.isEmpty) {
      debugPrint('❌ Session user is null or has empty UID');
      setState(() => _isLoading = false);
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(sessionUser.uid)
          .get();
      final updatedUser = UserModel.fromFirestore(userDoc);

      final adminSettings = await FirebaseFirestore.instance
          .collection('admin_settings')
          .doc('global')
          .get();

      final int directSponsorMin =
          adminSettings.data()?['direct_sponsor_min'] ?? 1;
      final int totalTeamMin = adminSettings.data()?['total_team_min'] ?? 1;

      debugPrint('🔎 Firestore values:');
      debugPrint('  🔸 directSponsorMin: $directSponsorMin');
      debugPrint('  🔸 totalTeamMin:     $totalTeamMin');
      debugPrint('  🔹 user.directSponsorCount: ${updatedUser.directSponsorCount}');
      debugPrint('  🔹 user.totalTeamCount:     ${updatedUser.totalTeamCount}');

      setState(() {
        _user = updatedUser;
        _directSponsorMin = directSponsorMin;
        _totalTeamMin = totalTeamMin;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('🔥 Error loading dashboard data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final user = _user;

    return Scaffold(
      appBar: AppHeaderWithMenu(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 24.0),
            child: Center(
              child: Text(
                'Dashboard',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 32),
          if (user?.role == 'admin')
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.settings),
                label: const Text('Account Settings'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
              ),
            ),
          // PATCH START: Join Opportunity Button
          if (user?.role != 'admin' &&
              (user?.directSponsorCount ?? 0) >= (_directSponsorMin ?? 1) &&
              (user?.totalTeamCount ?? 0) >= (_totalTeamMin ?? 1))
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Join Opportunity'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const JoinOpportunityScreen()),
                    );
                  },
                ),
              ),
            ),
          // PATCH END
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.person),
              label: const Text('My Profile'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.group),
              label: const Text('My Downline'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const DownlineTeamScreen(referredBy: 'demo-user'),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.ios_share),
              label: const Text('Share App'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ShareScreen()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

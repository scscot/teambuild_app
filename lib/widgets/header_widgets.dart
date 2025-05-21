import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/profile_screen.dart';
import '../screens/downline_team_screen.dart';
import '../screens/share_screen.dart';
import '../screens/login_screen.dart';
import '../screens/dashboard_screen.dart';
import '../services/session_manager.dart';

class AppHeaderWithMenu extends StatelessWidget implements PreferredSizeWidget {
  const AppHeaderWithMenu({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final isLoginScreen = context.findAncestorWidgetOfExactType<LoginScreen>() != null;

    return AppBar(
      backgroundColor: const Color(0xFFEDE7F6), // Soft lavender tone
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
                        MaterialPageRoute(builder: (_) => const DashboardScreen()),
                      );
                      break;
                    case 'profile':
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ProfileScreen()),
                      );
                      break;
                    case 'downline':
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const DownlineTeamScreen(referredBy: 'demo-user')),
                      );
                      break;
                    case 'share':
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ShareScreen()),
                      );
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
      backgroundColor: const Color(0xFFEDE7F6), // Soft lavender tone
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

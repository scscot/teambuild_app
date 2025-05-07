import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/profile_screen.dart';
import 'services/session_manager.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: 'assets/env.prod');
  debugPrint("✅ .env loaded with GOOGLE_API_KEY: ${dotenv.env['GOOGLE_API_KEY']}");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TeamBuild+',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
      ),
      home: EntryPoint(),
    );
  }
}

class EntryPoint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = SessionManager.instance.currentUser;
    if (user == null) {
      return const LoginScreen();
    } else if ((user.fullName ?? '').isEmpty) {
      // Placeholder for profile completion screen if needed
      return ProfileScreen();
    } else {
      return const DashboardScreen();
    }
  }
}

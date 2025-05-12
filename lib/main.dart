import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/profile_screen.dart';
import 'services/session_manager.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: 'assets/env.prod');
  await Firebase.initializeApp(); // ✅ Firebase now initialized globally
  await SessionManager.instance.loadFromStorage(); // ✅ Load user session from storage
  await SessionManager.instance.clear(); // TEMP DISABLED for login/session testing
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
    if (user == null || user.email.isEmpty || user.uid.isEmpty) {
      return const LoginScreen();
    } else if ((user.country ?? '').isEmpty || (user.state ?? '').isEmpty) {
      return ProfileScreen(); // Country/state missing, prompt user to update
    } else {
      return const DashboardScreen();
    }
  }
}


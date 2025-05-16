import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:tbp/screens/login_screen.dart';
import 'package:tbp/services/session_manager.dart';
import 'package:tbp/screens/dashboard_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final loggedIn = await SessionManager().isLoggedIn();

  runApp(MyApp(isLoggedIn: loggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TeamBuild+',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: isLoggedIn ? const DashboardScreen() : const LoginScreen(),
    );
  }
}

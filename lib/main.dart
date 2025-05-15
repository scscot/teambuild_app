import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:tbp/screens/login_screen.dart';
import 'package:tbp/services/session_manager.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: SessionManager().isLoggedIn() ? SessionManager().getHomeScreen() : const LoginScreen(),
    );
  }
}

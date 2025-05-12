// PATCHED: main.dart with finalized biometric auth integration + debug trace safety
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/profile_screen.dart';
import 'services/session_manager.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/biometric_auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('🟢 App launched (pre-dotenv)');

  try {
    debugPrint('🟩 MAIN: Initializing');
    await dotenv.load(fileName: 'assets/env.prod');
    debugPrint('✅ .env loaded: ${dotenv.env['GOOGLE_API_KEY']}');

    await Firebase.initializeApp();
    debugPrint('✅ Firebase initialized');

    await SessionManager.instance.loadFromStorage();
    debugPrint('✅ SessionManager loaded: ${SessionManager.instance.currentUser}');

    try {
      final biometric = BiometricAuthService();
      final shouldPrompt = await biometric.getBiometricPreference();
      debugPrint('🔐 Biometric preference: $shouldPrompt');

      if (SessionManager.instance.currentUser != null && shouldPrompt) {
        debugPrint('🔐 Triggering biometric auth...');
        final success = await biometric.authenticate();
        debugPrint('🔐 Biometric result: $success');

        if (!success) {
          await SessionManager.instance.signOut();
          debugPrint('🔒 Biometric failed — session cleared');
        } else {
          debugPrint('✅ Biometric passed');
        }
      }
    } catch (bioError) {
      debugPrint('⚠️ Biometric auth error: $bioError');
    }

    runApp(const MyApp());
    debugPrint('✅ runApp executed');
  } catch (e, stack) {
    debugPrint('❌ Exception in main(): $e');
    debugPrint('📍 Stack: $stack');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TeamBuild+',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: const EntryPoint(),
    );
  }
}

class EntryPoint extends StatelessWidget {
  const EntryPoint({super.key});

  @override
  Widget build(BuildContext context) {
    final user = SessionManager.instance.currentUser;
    debugPrint('🟨 EntryPoint: currentUser = $user');

    if (user == null || user.email.isEmpty || user.uid.isEmpty) {
      return const LoginScreen();
    } else if ((user.country ?? '').isEmpty || (user.state ?? '').isEmpty) {
      return ProfileScreen();
    } else {
      return const DashboardScreen();
    }
  }
}

// FINAL PATCHED — main.dart (fix literal \$e and \$stack logging in catch block)

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/profile_screen.dart';
import 'services/session_manager.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/biometric_auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ✅ Needed for native sign-in

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

    // PATCH START: Native Firebase sign-in to rehydrate Storage/Photo support
    final restoredUser = SessionManager.instance.currentUser;
    final restoredPassword = await SessionManager.instance.getStoredPassword();

    debugPrint('🧪 Firebase re-auth precheck: user=${restoredUser?.email}, password=${restoredPassword != null}');

    if (restoredUser != null && restoredPassword != null) {
      try {
        debugPrint('🔁 Attempting Firebase re-auth for ${restoredUser.email}');
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: restoredUser.email ?? '', // PATCH: ensure non-null
          password: restoredPassword,
        );
        debugPrint('✅ Firebase native sign-in successful');
      } catch (e) {
        debugPrint('⚠️ Firebase native sign-in failed: $e');
      }
    }
    // PATCH END

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

          // ✅ PATCH START: Firebase native sign-in after biometric
          final restoredUser = SessionManager.instance.currentUser;
          final restoredPassword = await SessionManager.instance.getStoredPassword();

          debugPrint('🧪 Firebase re-auth precheck: user=${restoredUser?.email}, password=${restoredPassword != null}');

          if (restoredUser != null && restoredPassword != null) {
            try {
              debugPrint('🔁 Attempting Firebase re-auth for ${restoredUser.email}');
              await FirebaseAuth.instance.signInWithEmailAndPassword(
                email: restoredUser.email ?? '',
                password: restoredPassword,
              );
              debugPrint('✅ Firebase native sign-in successful');
            } catch (e) {
              debugPrint('⚠️ Firebase native sign-in failed: $e');
            }
          }
          // ✅ PATCH END
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

    if (user == null || user.email?.isEmpty != false || user.uid.isEmpty) {
      return const LoginScreen();
    } else if ((user.country ?? '').isEmpty || (user.state ?? '').isEmpty) {
      return ProfileScreen();
    } else {
      return const DashboardScreen();
    }
  }
}

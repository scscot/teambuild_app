// PATCHED: Restored and enhanced auth_service.dart with full Firestore hydration using fromFirestore()
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:tbp/models/user_model.dart';
import 'package:tbp/services/firestore_service.dart';
import 'package:tbp/services/session_manager.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final SessionManager _sessionManager = SessionManager.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final String apiKey = dotenv.env['GOOGLE_API_KEY']!;

  Future<bool> signInWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return false;

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      final response = await http.post(
        Uri.parse('https://identitytoolkit.googleapis.com/v1/accounts:signInWithIdp?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'postBody': 'id_token=$idToken&providerId=google.com',
          'requestUri': 'http://localhost',
          'returnSecureToken': true,
          'returnIdpCredential': true,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['email'] != null) {
        final doc = await FirestoreService().getUserProfileByEmail(data['email']);

        UserModel userModel;
        if (doc != null) {
          userModel = UserModel.fromFirestore(
            doc['fields'],
            docId: doc['name'].split('/').last,
          );
        } else {
          userModel = UserModel(
            uid: data['localId'] ?? '',
            email: data['email'],
            fullName: data['displayName'] ?? '',
            country: '',
            state: '',
            city: '',
            referredBy: '',
            createdAt: DateTime.now(),
          );
          await FirestoreService().createUserProfile(
            uid: userModel.uid,
            email: userModel.email ?? '',
            fullName: userModel.fullName ?? '',
            country: '',
            state: '',
            city: '',
            referredBy: '',
          );
        }

        SessionManager.instance.saveSession(
          user: userModel,
          idToken: data['idToken'],
          accessToken: data['accessToken'],
        );
        await _sessionManager.persistUser(userModel);

        return true;
      }
    } catch (e) {
      debugPrint('signInWithGoogle error: $e');
    }
    return false;
  }

  Future<bool> signInWithEmailAndPassword(String email, String pw) async {
    try {
      final url = Uri.parse(
        'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$apiKey',
      );

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': pw,
          'returnSecureToken': true,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['email'] != null) {
        final accessToken = await _exchangeRefreshToken(data['refreshToken']);

        final doc = await _firestoreService.getUserProfileByEmail(data['email']);
        UserModel userModel;

        if (doc != null) {
          userModel = UserModel.fromFirestore(
            doc['fields'],
            docId: doc['name'].split('/').last,
          );
        } else {
          userModel = UserModel(
            uid: data['localId'] ?? '',
            email: data['email'],
            fullName: '',
            country: '',
            state: '',
            city: '',
            referredBy: '',
            createdAt: DateTime.now(),
          );
        }

        await _sessionManager.saveSession(
          user: userModel,
          idToken: data['idToken'],
          accessToken: accessToken,
        );
        await _sessionManager.persistUser(userModel, password: pw);

        return true;
      }
    } catch (e) {
      debugPrint('signInWithEmailAndPassword error: $e');
    }

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: pw,
      );
      debugPrint('✅ Native Firebase Auth sign-in successful');
    } catch (e) {
      debugPrint('⚠️ Native Firebase Auth sign-in failed: $e');
    }

    return false;
  }

  Future<String> _exchangeRefreshToken(String refreshToken) async {
    final url = Uri.parse(
      'https://securetoken.googleapis.com/v1/token?key=$apiKey',
    );

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'grant_type': 'refresh_token',
        'refresh_token': refreshToken,
      }),
    );

    final data = json.decode(response.body);
    return data['access_token'] ?? '';
  }

  Future<void> signOut() async {
    await SessionManager.instance.signOut();
  }

  Future<bool> createUserWithEmail({
    required String email,
    required String password,
    required String fullName,
    required String country,
    required String state,
    required String city,
    String? referredBy,
  }) async {
    try {
      final url = Uri.parse(
        'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$apiKey',
      );

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
          'returnSecureToken': true,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        final uid = data['localId'];

        final user = await _firestoreService.getUserProfileById(uid);

        if (user != null) {
          await _sessionManager.persistUser(user, password: password);

          try {
            await FirebaseAuth.instance.signInWithEmailAndPassword(
              email: email,
              password: password,
            );
            debugPrint('✅ Native Firebase Auth sign-in successful');
          } catch (e) {
            debugPrint('⚠️ Native Firebase Auth sign-in failed: $e');
          }

          return true;
        }
      }
    } catch (e) {
      debugPrint('createUserWithEmail error: $e');
    }
    return false;
  }
}

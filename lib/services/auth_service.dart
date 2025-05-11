import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:tbp/models/user_model.dart';
import 'package:tbp/services/firestore_service.dart';
import 'package:tbp/services/session_manager.dart';

class AuthService {
  final String apiKey = dotenv.env['GOOGLE_API_KEY']!;

  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    try {
      final url = Uri.parse(
        'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$apiKey',
      );

      final response = await http.post(
        url,
        body: json.encode({
          'email': email,
          'password': password,
          'returnSecureToken': true,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['email'] != null) {
        final accessToken = await _exchangeRefreshToken(data['refreshToken']);

        final userProfileMap = await FirestoreService().getUserProfileByEmail(data['email']);

        if (userProfileMap != null) {
          final userModel = UserModel.fromJson({
            ...userProfileMap,
            'uid': data['localId'] ?? '',
          });

          final session = SessionManager.instance;
          session.saveSession(
            user: userModel,
            idToken: data['idToken'],
            accessToken: accessToken,
          );

          return true;
        }
      } else {
        debugPrint("Login failed: ${data['error']?['message'] ?? 'Unknown error'}");
      }
    } catch (e) {
      debugPrint('AuthService error: $e');
    }
    
    debugPrint('❌ Login failed: user profile not found or session not saved.');
    return false;

  }

  Future<String> _exchangeRefreshToken(String refreshToken) async {
    final url = Uri.parse(
      'https://securetoken.googleapis.com/v1/token?key=$apiKey',
    );

    final response = await http.post(
      url,
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
        body: json.encode({
          'email': email,
          'password': password,
          'returnSecureToken': true,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        final uid = data['localId'];

        await FirestoreService().createUserProfile(
          uid: uid,
          email: email,
          fullName: fullName,
          country: country,
          state: state,
          city: city,
          referredBy: referredBy,
        );

        SessionManager.instance.currentUser = UserModel.fromJson({
          'uid': uid,
          'email': email,
          'fullName': fullName,
          'country': country,
          'state': state,
          'city': city,
          'referredBy': referredBy ?? '',
        });


        return true;
      } else {
        debugPrint("Registration failed: ${data['error']?['message'] ?? 'Unknown error'}");
      }
    } catch (e) {
      debugPrint('createUserWithEmail error: $e');
    }
    return false;
  }
}

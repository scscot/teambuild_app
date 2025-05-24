
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'session_manager.dart';

class FirebaseAuthService {
  final String apiKey;

  FirebaseAuthService({required this.apiKey});

  Future<bool> signIn(String email, String password) async {
    final url = 'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$apiKey';

    final response = await http.post(
      Uri.parse(url),
      body: json.encode({
        'email': email,
        'password': password,
        'returnSecureToken': true,
      }),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      await SessionManager.instance.saveSession(data['localId'], data['idToken']);
      return true;
    } else {
      print('Login failed: ${response.body}');
      return false;
    }
  }
}

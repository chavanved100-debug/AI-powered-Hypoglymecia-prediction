import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthUser {
  const AuthUser({required this.name, required this.email});

  final String name;
  final String email;
}

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const _usersKey = 'auth_users';
  static const _sessionKey = 'auth_session_email';

  Future<AuthUser?> currentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString(_sessionKey);
      if (email == null) return null;
      final users = _readUsers(prefs);
      final record = users[email];
      if (record is! Map) return null;
      return AuthUser(
        name: '${record['name']}',
        email: email,
      );
    } catch (_) {
      return null;
    }
  }

  Future<bool> isLoggedIn() async => (await currentUser()) != null;

  Future<String?> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final trimmedName = name.trim();
    final trimmedEmail = email.trim().toLowerCase();
    if (trimmedName.isEmpty) return 'Enter your name';
    if (!_validEmail(trimmedEmail)) return 'Enter a valid email';
    if (password.length < 6) return 'Password must be at least 6 characters';

    final prefs = await SharedPreferences.getInstance();
    final users = _readUsers(prefs);
    if (users.containsKey(trimmedEmail)) return 'An account already exists';

    final salt = DateTime.now().millisecondsSinceEpoch.toString();
    users[trimmedEmail] = {
      'name': trimmedName,
      'salt': salt,
      'hash': _hash(password, salt),
    };
    await prefs.setString(_usersKey, jsonEncode(users));
    await prefs.setString(_sessionKey, trimmedEmail);
    return null;
  }

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    final trimmedEmail = email.trim().toLowerCase();
    final prefs = await SharedPreferences.getInstance();
    final users = _readUsers(prefs);
    final record = users[trimmedEmail];
    if (record is! Map) return 'No account found for this email';
    final salt = '${record['salt']}';
    if (_hash(password, salt) != '${record['hash']}') {
      return 'Incorrect password';
    }
    await prefs.setString(_sessionKey, trimmedEmail);
    return null;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }

  Map<String, dynamic> _readUsers(SharedPreferences prefs) {
    final raw = prefs.getString(_usersKey);
    if (raw == null || raw.isEmpty) return {};
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) {
      return decoded.map((key, value) => MapEntry('$key', value));
    }
    return {};
  }

  bool _validEmail(String email) =>
      RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);

  String _hash(String password, String salt) {
    return sha256.convert(utf8.encode('$salt::$password')).toString();
  }
}

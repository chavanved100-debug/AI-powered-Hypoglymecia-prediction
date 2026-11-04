import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthUser {
  const AuthUser({required this.name, required this.email});

  final String name;
  final String email;
}

class AuthService {
  AuthService._();

  static AuthService instance = AuthService._();

  static const _sessionKey = 'auth_session_profile';
  static const _legacySessionKey = 'auth_session_email';
  static const _legacyUsersKey = 'auth_users';
  static const _secureStoragePrefix = 'local_account_';

  static final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  /// Derive a simple password verifier using SHA256.
  /// Returns a string "salt|hashHex" where salt is base64-encoded and hashHex is hex of the SHA256 hash.
  static String _derivePasswordVerifier(String password, {int iterations = 1}) {
    final salt = _randomSalt();
    final passwordBytes = utf8.encode(password);
    final digestBytes = sha256.convert(passwordBytes).bytes;
    final hashHex = digestBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '$salt|$hashHex';
  }

  /// Verify a password against a stored verifier.
  static bool _verifyPassword(String password, String verifier) {
    final parts = verifier.split('|');
    if (parts.length != 2) return false;
    final salt = parts[0];
    final storedHex = parts[1];
    final passwordBytes = utf8.encode(password);
    final digestBytes = sha256.convert(passwordBytes).bytes;
    final computedHex = digestBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return computedHex == storedHex;
  }

  static String _randomSalt() {
    final random = List<int>.generate(16, (_) => Random().nextInt(256));
    return base64Encode(random);
  }

  /// Migrate any legacy `auth_users` records from SharedPreferences into secure storage.
  /// Idempotent: will not re‑migrate if already done.
  Future<void> _migrateLegacyAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final already = prefs.getBool('_migrated_flag') ?? false;
    if (already) return;
    final raw = prefs.getString(_legacyUsersKey);
    if (raw == null || raw.isEmpty) {
      await prefs.setBool('_migrated_flag', true);
      return;
    }
    final legacyMap = jsonDecode(raw) as Map<String, dynamic>;
    for (final entry in legacyMap.entries) {
      final email = entry.key; // already normalized lower case
      final name = entry.value['name'] as String?;
      final salt = entry.value['salt'] as String?;
      final hash = entry.value['hash'] as String?; // expected sha256 digest (hex)
      if (salt != null && hash != null) {
        final verifier = '$salt|$hash';
        final secureKey = '$_secureStoragePrefix$email';
        await _secureStorage.write(key: secureKey, value: verifier);
      }
    }
    // Mark migration as done; legacy key will be cleaned up later (e.g., after first login).
    await prefs.setBool('_migrated_flag', true);
  }

  /// Register a new local account without contacting a server.
  Future<String?> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final trimmedName = name.trim();
    final trimmedEmail = email.trim().toLowerCase();
    if (trimmedName.isEmpty) return 'Enter your name';
    if (!_validEmail(trimmedEmail)) return 'Enter a valid email';
    if (password.length < 6) return 'Password must be at least 6 characters';

    // Check for duplicate email among existing local accounts.
    final secureKey = '$_secureStoragePrefix$trimmedEmail';
    final existing = await _secureStorage.read(key: secureKey);
    if (existing != null) return 'An account already exists';

    final verifier = _derivePasswordVerifier(password);
    await _secureStorage.write(key: secureKey, value: verifier);

    // Persist session profile as before.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _sessionKey,
      jsonEncode({'name': trimmedName, 'email': trimmedEmail}),
    );
    return null;
  }

  /// Log in with a local account.
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    final trimmedEmail = email.trim().toLowerCase();
    final secureKey = '$_secureStoragePrefix$trimmedEmail';
    final verifier = await _secureStorage.read(key: secureKey);
    if (verifier == null) return 'No account found for this email';

    if (_verifyPassword(password, verifier)) {
      // Successful login – persist session.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _sessionKey,
        jsonEncode({'name': '', 'email': trimmedEmail}),
      );
      return null;
    } else {
      return 'Incorrect password';
    }
  }

  /// Check if there is an active session.
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_sessionKey);
  }

  /// Get the current logged-in user email.
  Future<String?> currentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_sessionKey);
    if (raw == null) return null;
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return map['email'] as String?;
  }

  /// Clear the active session but **must not** delete registered account records.
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
    // We intentionally do NOT remove _legacyUsersKey here;
    // migration will clean it up after a successful login or on next app start.
  }

  bool _validEmail(String email) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
}
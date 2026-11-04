import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:glucose_guard/services/api_client.dart';
import 'package:glucose_guard/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<String> requests;

  http.Response ok(Map<String, Object> body, {int status = 200}) =>
      http.Response(
        jsonEncode(body),
        status,
        headers: {'content-type': 'application/json'},
      );

  AuthService buildAuth(
    Future<http.Response> Function(http.Request request) handler,
  ) {
    final client = MockClient((request) {
      requests.add('${request.method} ${request.url.path}');
      return handler(request);
    });
    return AuthService.withClient(
      ApiClient(client: client, baseUrl: 'http://test'),
    );
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    requests = [];
  });

  group('registration workflow', () {
    test('registration creates an active session without verification',
        () async {
      final auth = buildAuth((request) async {
        final path = request.url.path;
        if (path == '/auth/register') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['name'], 'Test User');
          expect(body['email'], 'user@example.com');
          expect(body['password'], 'secret123');
          return ok(
            {
              'status': 'registered',
              'name': 'Test User',
              'email': 'user@example.com',
            },
            status: 201,
          );
        }
        return fail('Unexpected request: $path');
      });

      expect(await auth.isLoggedIn(), isFalse);

      final error = await auth.register(
        name: ' Test User ',
        email: ' USER@Example.com ',
        password: 'secret123',
      );
      expect(error, isNull);
      expect(requests, contains('POST /auth/register'));
      expect(requests, isNot(contains('POST /auth/register/start')));

      final user = await auth.currentUser();
      expect(user?.name, 'Test User');
      expect(user?.email, 'user@example.com');
      expect(await auth.isLoggedIn(), isTrue);
    });

    test('backend error codes map to existing user-facing messages', () async {
      const cases = <String, String>{
        'account_exists': 'An account already exists',
        'invalid_name': 'Enter your name',
        'invalid_email': 'Enter a valid email',
        'weak_password': 'Password must be at least 6 characters',
        'user_not_found': 'No account found for this email',
        'invalid_password': 'Incorrect password',
        'login_limited': 'Too many failed attempts. Try again later.',
      };

      for (final entry in cases.entries) {
        final auth = buildAuth((request) async {
          return ok({'error': entry.key, 'message': 'server text'},
              status: 400);
        });
        final error = await auth.register(
          name: 'Test User',
          email: 'user@example.com',
          password: 'secret123',
        );
        expect(error, entry.value, reason: 'code ${entry.key}');
      }
    });

    test('frontend validation short-circuits before any request', () async {
      final auth = buildAuth((request) async {
        return fail('Network must not be called for invalid input');
      });

      expect(
        await auth.register(
            name: '', email: 'a@b.com', password: 'secret123'),
        'Enter your name',
      );
      expect(
        await auth.register(
            name: 'A', email: 'bad-email', password: 'secret123'),
        'Enter a valid email',
      );
      expect(
        await auth.register(
            name: 'A', email: 'a@b.com', password: 'short'),
        'Password must be at least 6 characters',
      );
      expect(requests, isEmpty);
    });
  });

  group('login', () {
    test('registered user logs in and can log out', () async {
      final auth = buildAuth((request) async {
        expect(request.url.path, '/auth/login');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['email'], 'user@example.com');
        expect(body['password'], 'secret123');
        return ok({
          'status': 'ok',
          'name': 'Test User',
          'email': 'user@example.com',
        });
      });

      expect(
        await auth.login(email: 'User@Example.com', password: 'secret123'),
        isNull,
      );
      expect((await auth.currentUser())?.name, 'Test User');
      expect(await auth.isLoggedIn(), isTrue);

      await auth.logout();
      expect(await auth.isLoggedIn(), isFalse);
      expect(await auth.currentUser(), isNull);
    });

    test('unknown email keeps existing message', () async {
      final auth = buildAuth((request) async {
        return ok({'error': 'user_not_found', 'message': 'nobody'},
            status: 404);
      });
      expect(
        await auth.login(email: 'nobody@example.com', password: 'secret123'),
        'No account found for this email',
      );
    });

    test('wrong password keeps existing message', () async {
      final auth = buildAuth((request) async {
        return ok({'error': 'invalid_password', 'message': 'nope'},
            status: 401);
      });
      expect(
        await auth.login(email: 'user@example.com', password: 'wrong-one'),
        'Incorrect password',
      );
    });

    test('network failure surfaces a connection message', () async {
      final client = MockClient((request) async {
        throw http.ClientException('no network');
      });
      final auth = AuthService.withClient(
        ApiClient(client: client, baseUrl: 'http://test'),
      );
      expect(
        await auth.login(email: 'user@example.com', password: 'secret123'),
        'Could not reach the server. Check your connection.',
      );
    });
  });
}

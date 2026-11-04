import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:glucose_guard/screens/auth_screen.dart';
import 'package:glucose_guard/services/api_client.dart';
import 'package:glucose_guard/services/auth_service.dart';
import 'package:glucose_guard/services/dataset_service.dart';
import 'package:glucose_guard/services/feature_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AuthService originalAuth;

  setUpAll(() async {
    originalAuth = AuthService.instance;
    await DatasetService.instance.ensureLoaded();
    await FeatureService.instance.ensureLoaded();
  });

  tearDownAll(() {
    AuthService.instance = originalAuth;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  void useMockApi(
    Future<http.Response> Function(http.Request request) handler,
  ) {
    AuthService.instance = AuthService.withClient(
      ApiClient(client: MockClient(handler), baseUrl: 'http://test'),
    );
  }

  http.Response ok(Map<String, Object> body, {int status = 200}) =>
      http.Response(
        jsonEncode(body),
        status,
        headers: {'content-type': 'application/json'},
      );

  Future<void> fillSignUpForm(WidgetTester tester) async {
    await tester.tap(find.text('New here? Create an account'));
    await tester.pump();
    await tester.enterText(find.byType(TextFormField).at(0), 'Test User');
    await tester.enterText(
        find.byType(TextFormField).at(1), 'user@example.com');
    await tester.enterText(find.byType(TextFormField).at(2), 'secret123');
  }

  testWidgets(
      'registration flow: form submits, account is created, app opens',
      (tester) async {
    final calls = <String>[];
    useMockApi((request) async {
      calls.add(request.url.path);
      if (request.url.path == '/auth/register') {
        return ok(
          {
            'status': 'registered',
            'name': 'Test User',
            'email': 'user@example.com',
          },
          status: 201,
        );
      }
      return ok({'error': 'unexpected'}, status: 500);
    });

    await tester.pumpWidget(const MaterialApp(home: AuthScreen()));
    await tester.pump();
    await fillSignUpForm(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Sign up'));
    await tester.pumpAndSettle();

    expect(calls, contains('/auth/register'));
    expect(calls, isNot(contains('/auth/register/start')));
    expect(await AuthService.instance.isLoggedIn(), isTrue);
    expect((await AuthService.instance.currentUser())?.email,
        'user@example.com');
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Meal'), findsOneWidget);
  });

  testWidgets('duplicate email shows a clear error and stays on the form',
      (tester) async {
    useMockApi((request) async {
      return ok(
        {'error': 'account_exists', 'message': 'An account already exists'},
        status: 409,
      );
    });

    await tester.pumpWidget(const MaterialApp(home: AuthScreen()));
    await tester.pump();
    await fillSignUpForm(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Sign up'));
    await tester.pump();

    expect(find.text('An account already exists'), findsOneWidget);
    expect(find.text('Create your account'), findsOneWidget);
    expect(await AuthService.instance.isLoggedIn(), isFalse);
  });

  testWidgets(
      'network failure during sign up shows the connection error and does not '
      'navigate away', (tester) async {
    useMockApi((request) async {
      throw http.ClientException('connection refused');
    });

    await tester.pumpWidget(const MaterialApp(home: AuthScreen()));
    await tester.pump();
    await fillSignUpForm(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Sign up'));
    await tester.pumpAndSettle();

    expect(
      find.text('Could not reach the server. Check your connection.'),
      findsOneWidget,
    );
    expect(find.text('Create your account'), findsOneWidget);
    expect(await AuthService.instance.isLoggedIn(), isFalse);
  });

  testWidgets('submit button shows a loading state while sending',
      (tester) async {
    useMockApi((request) async {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      return ok(
        {
          'status': 'registered',
          'name': 'Test User',
          'email': 'user@example.com',
        },
        status: 201,
      );
    });

    await tester.pumpWidget(const MaterialApp(home: AuthScreen()));
    await tester.pump();
    await fillSignUpForm(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Sign up'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsWidgets);

    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
  });
}

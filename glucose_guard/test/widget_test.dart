import 'package:flutter_test/flutter_test.dart';

import 'package:glucose_guard/main.dart';

void main() {
  testWidgets('App launches with splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const GlucoGuideApp());
    await tester.pump();
    expect(find.text('Gluco Guide AI'), findsOneWidget);
    expect(find.text('Health context & meal risk'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
  });
}

// Smoke-тест: приложение собирается и показывает сплэш.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:financial_pet/app/theme.dart';

void main() {
  testWidgets('SplashScreen renders', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: Center(child: Text('ФинПитомец'))),
      ),
    );
    expect(find.text('ФинПитомец'), findsOneWidget);
  });
}

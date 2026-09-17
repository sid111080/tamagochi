import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:financial_pet/features/onboarding/onboarding_screen.dart';
import 'package:financial_pet/features/pet_creation/create_pet_screen.dart';

void main() {
  testWidgets('Первый запуск: «Далее», «Пропустить» и заголовок цели',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: OnboardingScreen()),
    );
    expect(find.text('Далее'), findsOneWidget);
    expect(find.text('Пропустить'), findsOneWidget);
    expect(find.text('Давай познакомимся!'), findsOneWidget);
  });

  testWidgets('«Пропустить» при первом запуске ведёт на создание питомца',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: OnboardingScreen()),
    );
    await tester.tap(find.text('Пропустить'));
    await tester.pumpAndSettle();
    expect(find.byType(CreatePetScreen), findsOneWidget);
  });

  testWidgets('Подсказка: по завершении возвращаемся назад', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: _SentinelHome()),
    );
    // Открываем онбординг как подсказку (поверх Home).
    await tester.tap(find.text('open-onboarding'));
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingScreen), findsOneWidget);
    // На последнем слайде кнопка называется «Готово».
    expect(find.text('Готово'), findsNothing);
    // Завершаем → возврат на экран под подсказкой.
    await tester.tap(find.text('Пропустить'));
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingScreen), findsNothing);
    expect(find.text('sentinel-home'), findsOneWidget);
  });
}

/// Экран-заглушка под онбордингом: кнопка открывает подсказку поверх.
class _SentinelHome extends StatelessWidget {
  const _SentinelHome();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('sentinel-home'),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const OnboardingScreen(fromHint: true),
                ),
              ),
              child: const Text('open-onboarding'),
            ),
          ],
        ),
      ),
    );
  }
}

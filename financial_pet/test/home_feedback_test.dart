import 'package:financial_pet/core/models/task.dart';
import 'package:financial_pet/core/services/demo_service.dart';
import 'package:financial_pet/core/services/feedback_service.dart';
import 'package:financial_pet/core/services/period_service.dart';
import 'package:financial_pet/core/services/pet_service.dart';
import 'package:financial_pet/core/services/piggy_bank_service.dart';
import 'package:financial_pet/core/services/purchase_service.dart';
import 'package:financial_pet/core/services/task_service.dart';
import 'package:financial_pet/core/services/wallet_service.dart';
import 'package:financial_pet/features/home/home_screen.dart';
import 'package:financial_pet/widgets/feedback_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// «Сквозные» тесты обратной связи (ТЗ §8.9): действие на главном
/// экране → карточка → «Понятно» скрывает, история сохраняется.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  void setUpView(WidgetTester tester) {
    // Крупный «экран», чтобы все элементы таба были видны.
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
    });
  }

  /// Полный набор сервисов (как в main.dart). Возвращает виджет, питомца,
  /// обратную связь и список сервисов для dispose в конце теста.
  Future<(Widget, PetService, FeedbackService, List<ChangeNotifier>)>
      buildApp() async {
    final prefs = await SharedPreferences.getInstance();
    final wallet = WalletService(prefs);
    final pet = PetService(prefs, wallet);
    final tasks = TaskService(prefs, wallet, pet, const <Task>[]);
    final piggy =
        PiggyBankService(prefs, wallet, pet);
    final purchase = PurchaseService(wallet, pet);
    final feedback = FeedbackService();
    final period = PeriodService(prefs, wallet, pet);
    pet.spendReporter = period;
    piggy.spendReporter = period;
    purchase.spendReporter = period;
    final demo =
        DemoService(prefs, wallet, pet, tasks, piggy, period);

    final app = MultiProvider(
      providers: [
        ChangeNotifierProvider<WalletService>.value(value: wallet),
        ChangeNotifierProvider<PetService>.value(value: pet),
        ChangeNotifierProvider<TaskService>.value(value: tasks),
        ChangeNotifierProvider<PiggyBankService>.value(value: piggy),
        ChangeNotifierProvider<PurchaseService>.value(value: purchase),
        ChangeNotifierProvider<FeedbackService>.value(value: feedback),
        ChangeNotifierProvider<PeriodService>.value(value: period),
        ChangeNotifierProvider<DemoService>.value(value: demo),
      ],
      child: const MaterialApp(home: HomeScreen()),
    );
    return (
      app,
      pet,
      feedback,
      [
        wallet,
        pet,
        tasks,
        piggy,
        purchase,
        feedback,
        period,
        demo,
      ]
    );
  }

  /// Размонтировать дерево и освободить сервисы: иначе периодический
  /// таймер PetService «висел» бы к концу теста — binding проверяет
  /// timersPending до запуска teardown-колбэков.
  Future<void> cleanup(WidgetTester tester, List<ChangeNotifier> services) async {
    await tester.pumpWidget(const SizedBox());
    for (final service in services) {
      service.dispose();
    }
  }

  testWidgets('забота → карточка с балансом и статусом → «Понятно»',
      (tester) async {
    setUpView(tester);
    final (app, pet, feedback, services) = await buildApp();
    pet.createPet('Муся', 'kitten');

    await tester.pumpWidget(app);
    await tester.pump();
    expect(find.byType(FeedbackCard), findsNothing);

    // Кормление: −15 монеток, сытость 80 → 100.
    await tester.tap(find.text('Кормить'));
    // pumpAndSettle: доводим анимацию появления до конца (в рамках теста).
    await tester.pumpAndSettle();

    expect(find.byType(FeedbackCard), findsOneWidget);
    expect(find.text('Покормил(а) питомца'), findsOneWidget);
    expect(find.text('Сытость: 80 → 100'), findsOneWidget);
    expect(find.text('🪙 −15 монеток'), findsOneWidget);
    expect(feedback.isShowing, isTrue);

    // «Понятно» прячет карточку, история сохраняется.
    await tester.tap(find.text('Понятно'));
    // Дожидаемся завершения анимации выхода (AnimatedSwitcher).
    await tester.pumpAndSettle();
    expect(find.byType(FeedbackCard), findsNothing);
    expect(feedback.isShowing, isFalse);
    expect(feedback.history, hasLength(1));
    await cleanup(tester, services);
  });

  testWidgets('покупка → карточка «Купил(а)» с ценой', (tester) async {
    setUpView(tester);
    final (app, pet, feedback, services) = await buildApp();
    pet.createPet('Муся', 'kitten');

    await tester.pumpWidget(app);
    await tester.pump();

    // Переключаемся на вкладку «Покупки»: в IndexedStack неактивные
    // табы offstage, и обычный find их не видит.
    await tester.tap(find.text('Покупки'));
    await tester.pumpAndSettle();

    // Товар «Корм» (15) → диалог-подтверждение → «Купить».
    await tester.tap(find.text('Корм'));
    await tester.pumpAndSettle();
    expect(find.text('Купить'), findsOneWidget);
    await tester.tap(find.text('Купить'));
    await tester.pumpAndSettle();

    expect(find.byType(FeedbackCard), findsOneWidget);
    expect(find.text('Купил(а): Корм'), findsOneWidget);
    expect(find.text('🪙 −15 монеток'), findsOneWidget);
    expect(feedback.history, hasLength(1));

    // Скрываем карточку: отменяем таймер автоскрытия (тесты без «висячих»
    // таймеров).
    await tester.tap(find.text('Понятно'));
    await tester.pumpAndSettle();
    await cleanup(tester, services);
  });
}

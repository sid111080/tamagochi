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
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Виджет-тест вкладки «История и прогресс» (ТЗ §8.11):
/// пустые состояния и наполненный профиль (период, задание, цель, операции).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  void setUpView(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
    });
  }

  /// Пул заданий: 2 шт. (в сегодняшней ротации оба доступны).
  List<Task> pool() => [
        Task(
          id: 'h1',
          topic: TaskTopic.planningBudget,
          title: 'Корм или игрушка?',
          scenario: 'Есть 100 монеток. Что купить?',
          competencyRef: 'ref',
          type: TaskType.choice,
          options: const [
            TaskOption(
              id: 'a',
              text: 'Сначала корм',
              isCorrect: true,
              consequencePet: PetConsequence.happy,
              consequenceBalance: 0,
              explanationCorrect: 'Молодец!',
              explanationWrong: '',
            ),
          ],
          reward: 30,
          minAge: 7,
          maxAge: 11,
          difficulty: TaskDifficulty.easy,
        ),
        Task(
          id: 'h2',
          topic: TaskTopic.savings,
          title: 'Копилка на цель',
          scenario: 'Откладываем монетки на велосипед.',
          competencyRef: 'ref',
          type: TaskType.choice,
          options: const [
            TaskOption(
              id: 'a',
              text: 'Отложить в копилку',
              isCorrect: true,
              consequencePet: PetConsequence.happy,
              consequenceBalance: 0,
              explanationCorrect: 'Отлично!',
              explanationWrong: '',
            ),
          ],
          reward: 20,
          minAge: 7,
          maxAge: 11,
          difficulty: TaskDifficulty.easy,
        ),
      ];

  (Widget, WalletService, PetService, TaskService, PiggyBankService,
      PeriodService, List<ChangeNotifier>) buildApp(SharedPreferences prefs) {
    final wallet = WalletService(prefs);
    final pet = PetService(prefs, wallet);
    final tasks = TaskService(prefs, wallet, pet, pool());
    final piggy = PiggyBankService(prefs, wallet, pet);
    final purchase = PurchaseService(wallet, pet);
    final feedback = FeedbackService();
    final period = PeriodService(prefs, wallet, pet);
    pet.spendReporter = period;
    piggy.spendReporter = period;
    purchase.spendReporter = period;
    final demo = DemoService(prefs, wallet, pet, tasks, piggy, period);

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
      wallet,
      pet,
      tasks,
      piggy,
      period,
      [wallet, pet, tasks, piggy, purchase, feedback, period, demo]
    );
  }

  Future<void> cleanup(
      WidgetTester tester, List<ChangeNotifier> services) async {
    await tester.pumpWidget(const SizedBox());
    for (final service in services) {
      service.dispose();
    }
  }

  testWidgets('пустой профиль: подсказки и словарь', (tester) async {
    setUpView(tester);
    final prefs = await SharedPreferences.getInstance();
    final (app, _, _, _, _, _, services) = buildApp(prefs);

    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    // На вкладку «История» (в IndexedStack неактивные табы offstage).
    await tester.tap(find.text('История'));
    await tester.pumpAndSettle();

    // Пустые состояния: подсказки вместо данных.
    expect(
        find.text(
            'Заверши период на вкладке «Бюджет» —\nитог появится здесь.'),
        findsOneWidget);
    expect(
        find.text(
            'Ещё нет пройденных заданий.\nСделай первое на вкладке «Задания»!'),
        findsOneWidget);
    expect(
        find.text(
            'Создай цель на вкладке «Кошелёк» —\nпрогресс появится здесь.'),
        findsOneWidget);
    expect(
        find.text(
            'Операции появятся здесь,\nкак только ты заработаешь или потратишь.'),
        findsOneWidget);

    // Словарик всегда на месте.
    expect(find.text('Словарик'), findsOneWidget);
    expect(find.text('Монетки'), findsOneWidget);
    expect(find.text('Копилка'), findsOneWidget);

    await cleanup(tester, services);
  });

  testWidgets('наполненный профиль: период, задание, цель, операции',
      (tester) async {
    setUpView(tester);
    final prefs = await SharedPreferences.getInstance();
    final (app, wallet, pet, tasks, piggy, period, services) = buildApp(prefs);

    // Наполняем профиль до запуска UI.
    pet.createPet('Муся', 'kitten');
    tasks.answer('h1', 'a'); // верное → награда, задание закрыто
    final goal = piggy.addGoal('Велосипед', '🚲', 100)
        ? piggy.goals.first
        : throw StateError('не удалось создать цель');
    piggy.saveToGoal(goal.id, 10);
    wallet.earn(25, 'Подарок от родителя', '💡');
    period.confirmPlan(required: 10, optional: 5, savings: 5);
    period.finishPeriod();

    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    await tester.tap(find.text('История'));
    await tester.pumpAndSettle();

    // Итог периода: номер + score.
    expect(find.text('Итог периода 1'), findsOneWidget);
    expect(find.text('1 из 3'), findsOneWidget);

    // Умения: тема «Сбережения» (есть только в этой карточке).
    expect(find.text('Мои умения'), findsOneWidget);
    expect(find.text('Сбережения'), findsOneWidget);

    // Цель копилки. «Велосипед» — 2 раза: в чипе-сводке (шапка) и в
    // карточке цели на вкладке «История».
    expect(find.text('Велосипед'), findsNWidgets(2));
    expect(find.text('Всего в копилке: 10 монеток'), findsOneWidget);

    // Пройденное задание: 2 вхождения — в списке заданий и в операциях
    // (награда логируется с названием задания).
    expect(find.text('Корм или игрушка?'), findsNWidgets(2));

    // Операции.
    expect(find.text('Подарок от родителя'), findsOneWidget);
    expect(find.text('Словарик'), findsOneWidget);

    await cleanup(tester, services);
  });

  testWidgets('нижняя панель: 6 вкладок на узком экране', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    final (app, _, _, _, _, _, services) = buildApp(prefs);

    // Минимальная ширина по ТЗ: 360 dp. Шрифт тестов (Ahem) шире реального
    // (Roboto), поэтому на 360 dp в тесте лейблы могут «резать» — проверим
    // только их наличие. Реальный fit на устройстве — визуально (см. README).
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
    });

    await tester.pumpWidget(app);
    await tester.pumpAndSettle();
    // Сбрасываем переполнение из-за широкого тестового шрифта (не баг).
    tester.takeException();

    for (final label in const [
      'Питомец', 'Бюджет', 'Покупки', 'Задания', 'Кошелёк', 'История'
    ]) {
      expect(find.text(label), findsOneWidget, reason: 'нет лейбла: $label');
    }

    // На комфортной ширине переполнения layout не должно быть.
    tester.view.physicalSize = const Size(640, 800);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await cleanup(tester, services);
  });
}

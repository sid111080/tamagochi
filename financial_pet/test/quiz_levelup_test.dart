import 'package:financial_pet/core/models/task.dart';
import 'package:financial_pet/core/services/pet_service.dart';
import 'package:financial_pet/core/services/task_service.dart';
import 'package:financial_pet/core/services/wallet_service.dart';
import 'package:financial_pet/features/tasks/quiz_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ТЗ §8.10: момент роста виден там, где опыт заработан.
/// Квиз: верный ответ, давший новый уровень → блок «🎉 Уровень N!».
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Task makeTask() => Task(
        id: 't1',
        topic: TaskTopic.savings,
        title: 'Тестовое задание',
        scenario: 'Ситуация',
        competencyRef: 'ref',
        type: TaskType.choice,
        options: [
          const TaskOption(
            id: 'a',
            text: 'верный',
            isCorrect: true,
            consequencePet: PetConsequence.happy,
            consequenceBalance: 0,
            explanationCorrect: 'молодец',
            explanationWrong: '',
          ),
          const TaskOption(
            id: 'b',
            text: 'неверный',
            isCorrect: false,
            consequencePet: PetConsequence.sad,
            consequenceBalance: 0,
            explanationCorrect: '',
            explanationWrong: 'попробуй ещё',
          ),
        ],
        reward: 30,
        minAge: 7,
        maxAge: 11,
        difficulty: TaskDifficulty.easy,
      );

  /// Питомец с 50 XP: одно задание (+20) поднимет до уровня 2.
  Future<(Widget, List<ChangeNotifier>, PetService)> buildApp(
      WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
    });

    final prefs = await SharedPreferences.getInstance();
    final wallet = WalletService(prefs);
    final pet = PetService(prefs, wallet);
    pet.createPet('Муся', 'kitten');
    pet.addXp(50);
    final tasks = TaskService(prefs, wallet, pet, [makeTask()]);

    final app = MultiProvider(
      providers: [
        ChangeNotifierProvider<WalletService>.value(value: wallet),
        ChangeNotifierProvider<PetService>.value(value: pet),
        ChangeNotifierProvider<TaskService>.value(value: tasks),
      ],
      child: MaterialApp(home: QuizScreen(task: makeTask())),
    );
    return (
      app,
      [wallet, pet, tasks],
      pet
    );
  }

  Future<void> cleanup(WidgetTester tester, List<ChangeNotifier> services) async {
    await tester.pumpWidget(const SizedBox());
    for (final service in services) {
      service.dispose();
    }
  }

  testWidgets('новый уровень → блок празднования с уровнем питомца',
      (tester) async {
    final (app, services, pet) = await buildApp(tester);
    expect(pet.pet!.level, 1);

    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    await tester.tap(find.text('верный'));
    await tester.pumpAndSettle();

    expect(pet.pet!.level, 2);
    expect(find.text('Молодец!'), findsOneWidget);
    expect(
      find.textContaining('Уровень 2'),
      findsOneWidget,
      reason: 'празднование уровня видно в панели обратной связи',
    );
    await cleanup(tester, services);
  });

  testWidgets('без нового уровня → празднования нет', (tester) async {
    final (app, services, pet) = await buildApp(tester);
    // 50 + 20 = 70 XP — уровень 2, но в этом сценарии сбрасываем до 10:
    // 10 + 20 = 30 XP — уровень не меняется.
    pet.pet!.totalXp = 10;

    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    await tester.tap(find.text('верный'));
    await tester.pumpAndSettle();

    expect(pet.pet!.level, 1);
    expect(find.text('Молодец!'), findsOneWidget);
    expect(find.textContaining('Уровень'), findsNothing);
    await cleanup(tester, services);
  });
}

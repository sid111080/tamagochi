import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:financial_pet/core/models/task.dart';
import 'package:financial_pet/core/services/demo_service.dart';
import 'package:financial_pet/core/services/period_service.dart';
import 'package:financial_pet/core/services/pet_service.dart';
import 'package:financial_pet/core/services/piggy_bank_service.dart';
import 'package:financial_pet/core/services/task_service.dart';
import 'package:financial_pet/core/services/wallet_service.dart';

/// Пять тестовых заданий: в обычной ротации показывается 3, в демо — все 5.
List<Task> _sampleTasks() => [
      for (var i = 0; i < 5; i++)
        Task(
          id: 't$i',
          topic: const [
            TaskTopic.planningBudget,
            TaskTopic.savings,
            TaskTopic.payments
          ][i % 3],
          title: 'Task $i',
          scenario: 's',
          competencyRef: 'c',
          type: TaskType.choice,
          options: const [
            TaskOption(
              id: 'o',
              text: 'x',
              isCorrect: true,
              consequencePet: PetConsequence.neutral,
              consequenceBalance: 0,
              explanationCorrect: 'ok',
              explanationWrong: 'no',
            ),
          ],
          reward: 10,
          minAge: 7,
          maxAge: 11,
          difficulty: TaskDifficulty.easy,
        ),
    ];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late WalletService wallet;
  late PetService pet;
  late TaskService tasks;
  late PiggyBankService piggy;
  late PeriodService period;
  late DemoService demo;

  final content = _sampleTasks();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    wallet = WalletService(prefs);
    pet = PetService(prefs, wallet);
    tasks = TaskService(prefs, wallet, pet, content);
    piggy = PiggyBankService(prefs, wallet, pet);
    period = PeriodService(prefs, wallet, pet);
    demo = DemoService(prefs, wallet, pet, tasks, piggy, period);
  });

  tearDown(() {
    demo.dispose();
    period.dispose();
    piggy.dispose();
    tasks.dispose();
    pet.dispose();
    wallet.dispose();
  });

  test('в обычной ротации доступно 3 из 5 заданий', () {
    expect(demo.isDemo, isFalse);
    expect(tasks.availableCount, 3);
  });

  test('enterDemo: тестовый профиль со всё включённым', () {
    demo.enterDemo();

    expect(demo.isDemo, isTrue);
    // Питомец по умолчанию.
    expect(pet.hasPet, isTrue);
    expect(pet.pet!.name, DemoService.demoPetName);
    expect(pet.pet!.speciesId, DemoService.demoPetSpecies);
    // Стартовый баланс, пустая копилка, период 1 в планировании.
    expect(wallet.balance, WalletService.startingBalance);
    expect(piggy.goals, isEmpty);
    expect(period.period.index, 1);
    expect(period.isPlanning, isTrue);
    // В демо без реального времени и все задания доступны.
    expect(pet.demoMode, isTrue);
    expect(tasks.allTasksAvailable, isTrue);
    expect(tasks.availableCount, content.length); // 5, не 3.
  });

  test('exitDemo: чистый профиль, демо выключено', () {
    demo.enterDemo();
    wallet.earn(100, 'x', '🪙');
    piggy.addGoal('Вело', '🚲', 50);

    demo.exitDemo();

    expect(demo.isDemo, isFalse);
    expect(pet.hasPet, isFalse); // питомец удалён.
    expect(pet.demoMode, isFalse);
    expect(tasks.allTasksAvailable, isFalse);
    expect(wallet.balance, WalletService.startingBalance); // снова 50.
    expect(piggy.goals, isEmpty);
    // Ротация вернулась к 3 заданиям в день.
    expect(tasks.availableCount, 3);
  });

  test('resetDemo: заново пройти сценарий, демо остаётся', () {
    demo.enterDemo();
    wallet.earn(100, 'x', '🪙');
    piggy.addGoal('Вело', '🚲', 50);

    demo.resetDemo();

    expect(demo.isDemo, isTrue); // демо не выключается.
    expect(pet.pet!.name, DemoService.demoPetName);
    expect(wallet.balance, WalletService.startingBalance);
    expect(piggy.goals, isEmpty);
    expect(tasks.allTasksAvailable, isTrue);
  });

  test('персистентность: флаг и демо-режим переживают перезапуск', () async {
    demo.enterDemo();

    // Эмулируем перезапуск приложения: свежие сервисы из тех же prefs.
    final wallet2 = WalletService(prefs);
    final pet2 = PetService(prefs, wallet2);
    final tasks2 = TaskService(prefs, wallet2, pet2, content);
    final piggy2 = PiggyBankService(prefs, wallet2, pet2);
    final period2 = PeriodService(prefs, wallet2, pet2);
    final demo2 = DemoService(prefs, wallet2, pet2, tasks2, piggy2, period2);

    expect(demo2.isDemo, isTrue);
    expect(pet2.demoMode, isTrue);
    expect(tasks2.allTasksAvailable, isTrue);
    expect(tasks2.availableCount, content.length);

    demo2.dispose();
    period2.dispose();
    piggy2.dispose();
    tasks2.dispose();
    pet2.dispose();
    wallet2.dispose();
  });
}

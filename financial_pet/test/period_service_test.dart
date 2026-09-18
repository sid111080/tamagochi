import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:financial_pet/core/models/budget.dart';
import 'package:financial_pet/core/services/pet_service.dart';
import 'package:financial_pet/core/services/period_service.dart';
import 'package:financial_pet/core/services/wallet_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PetService petService;
  late WalletService walletService;
  late PeriodService periodService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    walletService = WalletService(prefs);
    petService = PetService(prefs, walletService);
    periodService = PeriodService(prefs, walletService, petService);
  });

  tearDown(() {
    periodService.dispose();
    petService.dispose();
    walletService.dispose();
  });

  group('Начальное состояние', () {
    test('новый сервис: период 1, фаза планирования, стадия beginner', () {
      expect(periodService.period.index, 1);
      expect(periodService.isPlanning, isTrue);
      expect(periodService.isActive, isFalse);
      expect(periodService.stage, FinancialStage.beginner);
      expect(periodService.points, 0);
      expect(periodService.lastResult, isNull);
    });

    test('доступный бюджет отражает баланс кошелька', () {
      expect(periodService.availableBudget, walletService.balance);
      // 50 (старт) — ещё ничего не потрачено.
      expect(periodService.availableBudget, 50);
      expect(periodService.unallocated, 50); // план пока пуст.
    });
  });

  group('confirmPlan (ТЗ §8.5)', () {
    test('допустимое распределение: активная фаза, план сохранён, остаток',
        () {
      periodService.confirmPlan(required: 30, optional: 10, savings: 5);
      expect(periodService.isActive, isTrue);
      expect(periodService.period.plan.required, 30);
      expect(periodService.period.plan.optional, 10);
      expect(periodService.period.plan.savings, 5);
      // 50 − (30+10+5) = 5 остаётся в свободном остатке.
      expect(periodService.unallocated, 5);
    });

    test('перерасход сверх бюджета: отказ, остаёмся на планировании', () {
      // 40 + 40 = 80 > 50 — больше доступного бюджета.
      final ok = periodService.confirmPlan(required: 40, optional: 40);
      expect(ok, isFalse);
      expect(periodService.isPlanning, isTrue);
      expect(periodService.isActive, isFalse);
    });

    test('повторное подтверждение вне фазы планирования: отказ', () {
      periodService.confirmPlan(required: 10); // активна.
      expect(periodService.confirmPlan(required: 5), isFalse);
      // План не переписан вторым подтверждением.
      expect(periodService.period.plan.required, 10);
    });
  });

  group('reportSpend (факт периода)', () {
    test('до плана расход не учитывается', () {
      periodService.reportSpend(BudgetDirection.required, 10);
      expect(periodService.period.fact.required, 0);
    });

    test('в активной фазе расход копится в факт', () {
      periodService.confirmPlan(required: 20, optional: 10, savings: 10);
      periodService.reportSpend(BudgetDirection.required, 10);
      periodService.reportSpend(BudgetDirection.required, 5);
      periodService.reportSpend(BudgetDirection.optional, 10);
      expect(periodService.period.fact.required, 15);
      expect(periodService.period.fact.optional, 10);
      expect(periodService.period.fact.savings, 0);
    });

    test('неположительный расход игнорируется', () {
      periodService.confirmPlan(required: 20);
      periodService.reportSpend(BudgetDirection.required, 0);
      periodService.reportSpend(BudgetDirection.required, -5);
      expect(periodService.period.fact.required, 0);
    });
  });

  group('finishPeriod: критерии развития (ТЗ §8.10)', () {
    test('все три критерия выполнены: score 3, питомец рад, очки', () {
      petService.createPet('Муся', 'kitten');
      final hungerBefore = petService.pet!.hunger; // 80
      periodService
        ..confirmPlan(required: 20, optional: 10, savings: 10)
        ..reportSpend(BudgetDirection.required, 20)
        ..reportSpend(BudgetDirection.optional, 5)
        ..reportSpend(BudgetDirection.savings, 10);

      final result = periodService.finishPeriod();

      expect(result.requiredCovered, isTrue);
      expect(result.optionalWithinPlan, isTrue);
      expect(result.savingsConsistent, isTrue);
      expect(result.score, 3);
      expect(result.moodDelta, 15);
      expect(periodService.points, 3);
      expect(periodService.isFinished, isTrue);
      expect(result.explanation, isNotEmpty);
      // Питомец стал чуть счастливее.
      expect(petService.pet!.hunger, greaterThan(hungerBefore));
    });

    test('ни один критерий: score 0, питомец грустит (обратимо)', () {
      petService.createPet('Муся', 'kitten');
      final hungerBefore = petService.pet!.hunger; // 80
      // План: обязательные 10, необязательные 5, накопления 10.
      // Факт: обязательные не покрыты, необязательные перерасход, копилку не трогали.
      periodService
        ..confirmPlan(required: 10, optional: 5, savings: 10)
        ..reportSpend(BudgetDirection.optional, 10); // перерасход: 10 > 5

      final result = periodService.finishPeriod();

      expect(result.requiredCovered, isFalse);
      expect(result.optionalWithinPlan, isFalse);
      expect(result.savingsConsistent, isFalse);
      expect(result.score, 0);
      expect(result.moodDelta, -10);
      expect(result.explanation, isNotEmpty);
      // Слегка расстроен, но не «обнулён» (безопасная ошибка).
      expect(petService.pet!.hunger, lessThan(hungerBefore));
      expect(petService.pet!.hunger, greaterThan(0));
    });

    test('score 2: мягкое улучшение', () {
      periodService
        ..confirmPlan(required: 10, optional: 5, savings: 10)
        ..reportSpend(BudgetDirection.required, 10)
        ..reportSpend(BudgetDirection.optional, 8) // перерасход → false
        ..reportSpend(BudgetDirection.savings, 10);
      // requiredCovered true, optionalWithinPlan false, savingsConsistent true.
      final result = periodService.finishPeriod();
      expect(result.score, 2);
      expect(result.moodDelta, 5);
    });

    test('план накоплений 0, но положил: считает за регулярность', () {
      periodService
        ..confirmPlan(required: 20, optional: 10, savings: 0)
        ..reportSpend(BudgetDirection.required, 20)
        ..reportSpend(BudgetDirection.savings, 5);
      // optional: 0 <= 10 true, required true, savings 0→5>0 true.
      expect(periodService.finishPeriod().score, 3);
    });
  });

  group('Рост стадии и цикл периодов (ТЗ §8.10, §9)', () {
    test('стадия по накопленным очкам', () {
      expect(FinancialStageX.fromPoints(0), FinancialStage.beginner);
      expect(FinancialStageX.fromPoints(4), FinancialStage.beginner);
      expect(FinancialStageX.fromPoints(5), FinancialStage.confident);
      expect(FinancialStageX.fromPoints(9), FinancialStage.confident);
      expect(FinancialStageX.fromPoints(10), FinancialStage.master);
    });

    test('прогресс внутри стадии: шкала 0..1 по порогам (для UI)', () {
      expect(FinancialStage.beginner.progressToNextStage(0), 0.0);
      expect(FinancialStage.beginner.progressToNextStage(2), closeTo(0.4, 0.001));
      expect(FinancialStage.beginner.progressToNextStage(4), closeTo(0.8, 0.001));
      expect(FinancialStage.confident.progressToNextStage(5), 0.0);
      expect(FinancialStage.confident.progressToNextStage(8), closeTo(0.6, 0.001));
      // У мастера шкала заполнена.
      expect(FinancialStage.master.progressToNextStage(10), 1.0);
      expect(FinancialStage.master.progressToNextStage(20), 1.0);
    });

    test('два идеальных периода подводят к confident (6 очков)', () {
      for (var i = 0; i < 2; i++) {
        periodService
          ..confirmPlan(required: 10, optional: 10, savings: 10)
          ..reportSpend(BudgetDirection.required, 10)
          ..reportSpend(BudgetDirection.optional, 5)
          ..reportSpend(BudgetDirection.savings, 10)
          ..finishPeriod()
          ..nextPeriod();
      }
      expect(periodService.points, 6);
      expect(periodService.stage, FinancialStage.confident);
    });

    test('nextPeriod переходит на следующий период в планирование', () {
      periodService
        ..confirmPlan(required: 10)
        ..finishPeriod();
      expect(periodService.isFinished, isTrue);
      periodService.nextPeriod();
      expect(periodService.period.index, 2);
      expect(periodService.isPlanning, isTrue);
      expect(periodService.period.plan.total, 0);
      expect(periodService.period.fact.total, 0);
    });

    test('сезон из 5 периодов: после 5-го цикл возвращается к 1-му', () {
      for (var i = 0; i < 4; i++) {
        periodService
          ..confirmPlan(required: 1)
          ..finishPeriod()
          ..nextPeriod();
      }
      expect(periodService.period.index, 5);
      periodService
        ..confirmPlan(required: 1)
        ..finishPeriod()
        ..nextPeriod();
      expect(periodService.period.index, 1);
      expect(periodService.isPlanning, isTrue);
    });

    test('nextPeriod вне фазы finished ничего не делает', () {
      expect(periodService.period.index, 1);
      periodService.nextPeriod(); // ещё на планировании.
      expect(periodService.period.index, 1);
      expect(periodService.isPlanning, isTrue);
    });
  });

  group('reset (демо-режим / сброс)', () {
    test('обнуляет очки, результат и возвращает период 1', () {
      petService.createPet('Муся', 'kitten');
      periodService
        ..confirmPlan(required: 20, optional: 10, savings: 10)
        ..reportSpend(BudgetDirection.required, 20)
        ..finishPeriod()
        ..nextPeriod();
      expect(periodService.points, greaterThan(0));
      expect(periodService.period.index, 2);

      periodService.reset();

      expect(periodService.points, 0);
      expect(periodService.lastResult, isNull);
      expect(periodService.period.index, 1);
      expect(periodService.isPlanning, isTrue);
    });
  });

  group('Персистентность (ТЗ §8.13)', () {
    test('новый сервис видит завершённый период и накопленные очки', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final wallet = WalletService(prefs);
      final pet = PetService(prefs, wallet);
      pet.createPet('Муся', 'kitten');
      final period = PeriodService(prefs, wallet, pet);
      period
        ..confirmPlan(required: 20, optional: 5, savings: 5)
        ..reportSpend(BudgetDirection.required, 20)
        ..finishPeriod();

      // Эмулируем перезапуск приложения.
      final period2 = PeriodService(prefs, wallet, pet);
      expect(period2.period.phase, PeriodPhase.finished);
      expect(period2.lastResult, isNotNull);
      expect(period2.lastResult!.periodIndex, 1);
      expect(period2.points, period.lastResult!.score);
      expect(period2.lastResult!.requiredCovered, isTrue);

      period.dispose();
      period2.dispose();
      pet.dispose();
      wallet.dispose();
    });
  });
}

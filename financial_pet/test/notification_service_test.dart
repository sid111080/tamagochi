import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:financial_pet/core/services/demo_service.dart';
import 'package:financial_pet/core/services/notification_service.dart';
import 'package:financial_pet/core/services/period_service.dart';
import 'package:financial_pet/core/services/pet_service.dart';
import 'package:financial_pet/core/services/piggy_bank_service.dart';
import 'package:financial_pet/core/services/task_service.dart';
import 'package:financial_pet/core/services/wallet_service.dart';

/// Фейк бэкенда: записывает вызовы показов (плагин в unit-тестах не нужен).
class FakeNotificationBackend implements NotificationBackend {
  final calls = <(int, String, String)>[];

  @override
  Future<void> init() async {}

  @override
  Future<void> show({
    required int id,
    required String title,
    required String body,
  }) async {
    calls.add((id, title, body));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late WalletService wallet;
  late PetService pet;
  late TaskService tasks;
  late PiggyBankService piggy;
  late PeriodService period;
  late DemoService demo;
  late FakeNotificationBackend backend;
  late NotificationService notifications;
  late DateTime now;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    wallet = WalletService(prefs);
    pet = PetService(prefs, wallet);
    tasks = TaskService(prefs, wallet, pet, const []);
    piggy = PiggyBankService(prefs, wallet, pet);
    period = PeriodService(prefs, wallet, pet);
    demo = DemoService(prefs, wallet, pet, tasks, piggy, period);
    backend = FakeNotificationBackend();
    now = DateTime(2026, 9, 23, 12);
    notifications = NotificationService(
      prefs,
      pet,
      demo,
      backend: backend,
      clock: () => now,
    );
  });

  tearDown(() {
    notifications.dispose();
    demo.dispose();
    period.dispose();
    piggy.dispose();
    tasks.dispose();
    pet.dispose();
    wallet.dispose();
  });

  /// Питомец с низким статусом: «нуждается в заботе».
  void neglectedPet() {
    pet.createPet('Финни', 'kitten');
    final p = pet.pet!;
    p.hunger = 20;
    p.fun = 10;
    p.cleanliness = 80;
  }

  /// Пометить прошлое открытие: [ago] назад (ISO-строка в хранилище).
  void setLastOpen(Duration ago) {
    prefs.setString(
        NotificationService.lastOpenKey, now.subtract(ago).toIso8601String());
  }

  test('нет питомца — уведомлений нет, открытие записано', () async {
    await notifications.checkLaunchEvents();
    expect(backend.calls, isEmpty);
    expect(prefs.getString(NotificationService.lastOpenKey),
        isNotNull);
  });

  test('короткое отсутствие (< 30 мин) — без пуша (анти-спам)', () async {
    pet.createPet('Финни', 'kitten');
    setLastOpen(const Duration(minutes: 5));
    await notifications.checkLaunchEvents();
    expect(backend.calls, isEmpty);
  });

  test('долгое отсутствие + низкие статусы — один обобщённый пуш',
      () async {
    neglectedPet();
    setLastOpen(const Duration(hours: 2));
    await notifications.checkLaunchEvents();

    expect(backend.calls, hasLength(1));
    final (id, title, body) = backend.calls.first;
    expect(id, 1);
    expect(title, 'Финни нуждается в заботе');
    // Только статусы ниже порога: сытость и веселье, чистота — нет.
    expect(body, contains('проголодался'));
    expect(body, contains('поскучал'));
    expect(body, isNot(contains('испачкался')));
    // Открытие обновлено.
    expect(prefs.getString(NotificationService.lastOpenKey),
        now.toIso8601String());
  });

  test('новый день — пуш о новых заданиях', () async {
    pet.createPet('Финни', 'kitten'); // статусы 80 — забота не нужна
    // Прошлый вчерашний запуск: день сменился.
    prefs.setString(NotificationService.lastOpenKey,
        DateTime(2026, 9, 22, 10).toIso8601String());
    await notifications.checkLaunchEvents();

    expect(backend.calls, hasLength(1));
    final (id, title, body) = backend.calls.first;
    expect(id, 2);
    expect(title, 'Новые задания');
    expect(body, contains('📚'));
  });

  test('тот же день + низкие статусы — только забота, без заданий',
      () async {
    neglectedPet();
    setLastOpen(const Duration(hours: 2));
    await notifications.checkLaunchEvents();

    expect(backend.calls, hasLength(1));
    expect(backend.calls.first.$2, contains('заботе'));
  });

  test('выключенные уведомления — ничего не показываем', () async {
    neglectedPet();
    setLastOpen(const Duration(hours: 2));
    notifications.toggle();
    expect(notifications.enabled, isFalse);
    await notifications.checkLaunchEvents();
    expect(backend.calls, isEmpty);
  });

  test('демо-режим — уведомления отключены', () async {
    demo.enterDemo();
    final p = pet.pet!;
    p.hunger = 20;
    p.fun = 10;
    setLastOpen(const Duration(hours: 2));
    await notifications.checkLaunchEvents();
    expect(backend.calls, isEmpty);
  });

  test('toggle переживает перезапуск (персистится)', () {
    notifications.toggle();
    expect(prefs.getBool(NotificationService.enabledKey), isFalse);
    final reloaded = NotificationService(
      prefs,
      pet,
      demo,
      backend: backend,
      clock: () => now,
    );
    expect(reloaded.enabled, isFalse);
    reloaded.dispose();
  });
}

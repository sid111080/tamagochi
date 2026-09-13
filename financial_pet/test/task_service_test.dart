import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:financial_pet/models/streak_badge.dart';
import 'package:financial_pet/models/task.dart';
import 'package:financial_pet/services/pet_service.dart';
import 'package:financial_pet/services/task_service.dart';
import 'package:financial_pet/services/wallet_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late WalletService wallet;
  late PetService pet;
  late TaskService tasks;
  late DateTime now;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    wallet = WalletService(prefs);
    pet = PetService(prefs, wallet);
    pet.createPet('Муся', 'kitten');
    tasks = TaskService(prefs, wallet, pet);
    now = tasks.clock();
    tasks.clock = () => now;
  });

  tearDown(() {
    tasks.dispose();
    pet.dispose();
    wallet.dispose();
  });

  test('свежий набор: 3 ежедневных + 2 еженедельных', () {
    expect(tasks.dailyTasks, hasLength(3));
    expect(tasks.weeklyTasks, hasLength(2));
    expect(tasks.availableCount, 5);
  });

  test('ротация детерминирована: два сервиса выбирают одинаково', () {
    final a = tasks.selectedIds;
    final b = TaskService(prefs, wallet, pet).selectedIds;
    expect(a, b);
  });

  test('выполнение: награда в кошелёк и опыт питомцу', () {
    final t = tasks.availableTasks.first;
    final balanceBefore = wallet.balance;
    final xpBefore = pet.pet!.totalXp;

    expect(tasks.completeTask(t.id), isTrue);

    expect(wallet.balance, balanceBefore + t.coinReward);
    expect(pet.pet!.totalXp, xpBefore + t.xpReward);
    expect(tasks.completedTasks, contains(t));
  });

  test('повторное выполнение в тот же период отклоняется', () {
    final t = tasks.availableTasks.first;
    final balanceAfterFirst = wallet.balance + t.coinReward;

    expect(tasks.completeTask(t.id), isTrue);
    expect(tasks.completeTask(t.id), isFalse);
    expect(wallet.balance, balanceAfterFirst);
  });

  test('стрик: подряд два дня — 2, пропуск дня — сброс в 1', () {
    final daily = TaskFrequency.daily;

    tasks.completeTask(
        tasks.availableTasks.firstWhere((t) => t.frequency == daily).id);
    expect(tasks.streak, 1);

    now = now.add(const Duration(days: 1));
    tasks.completeTask(
        tasks.availableTasks.firstWhere((t) => t.frequency == daily).id);
    expect(tasks.streak, 2);

    // Пропустили день: вчера стрика не было — сброс.
    now = now.add(const Duration(days: 2));
    tasks.completeTask(
        tasks.availableTasks.firstWhere((t) => t.frequency == daily).id);
    expect(tasks.streak, 1);
  });

  test('повторное выполнение в тот же день не дублирует стрик', () {
    final daily = TaskFrequency.daily;
    tasks.completeTask(
        tasks.availableTasks.firstWhere((t) => t.frequency == daily).id);
    tasks.completeTask(
        tasks.availableTasks.firstWhere((t) => t.frequency == daily).id);
    expect(tasks.streak, 1);
  });

  test('выполненное «вчера» задание на следующий день снова доступно', () {
    final t = tasks.availableTasks.first;
    tasks.completeTask(t.id);
    now = now.add(const Duration(days: 1));
    expect(t.isAvailableNow(now), isTrue);
  });

  test('повторное выполнение в пределах одного дня отклоняется', () {
    final t = tasks.availableTasks.first;
    tasks.completeTask(t.id);
    // Тот же день — задание выполнено и недоступно.
    expect(t.isAvailableNow(now), isFalse);
    expect(tasks.completeTask(t.id), isFalse);
  });

  test('максимальный стрик не сбрасывается: бейджи считаются по лучшему', () {
    final daily = TaskFrequency.daily;

    tasks.completeTask(
        tasks.availableTasks.firstWhere((t) => t.frequency == daily).id);
    now = now.add(const Duration(days: 1));
    tasks.completeTask(
        tasks.availableTasks.firstWhere((t) => t.frequency == daily).id);
    expect(tasks.maxStreak, 2);

    // Пропустили несколько дней: стрик сброшен, а рекорд сохранился.
    now = now.add(const Duration(days: 3));
    tasks.completeTask(
        tasks.availableTasks.firstWhere((t) => t.frequency == daily).id);
    expect(tasks.streak, 1);
    expect(tasks.maxStreak, 2);
    expect(StreakBadge.all.first.isEarned(tasks.maxStreak), isFalse);
  });

  test('бейдж начисляется при достижении порога', () {
    final bronze = StreakBadge.all.first;
    expect(bronze.isEarned(2), isFalse);
    expect(bronze.isEarned(3), isTrue);
  });

  test('история сохраняется: новый сервис видит выполнения и стрик', () {
    final t = tasks.availableTasks
        .firstWhere((t) => t.frequency == TaskFrequency.daily);
    tasks.completeTask(t.id);

    tasks.dispose();
    tasks = TaskService(prefs, wallet, pet);
    tasks.clock = () => now;

    expect(tasks.streak, 1);
    expect(tasks.completedTasks.map((t) => t.id), contains(t.id));
  });
}

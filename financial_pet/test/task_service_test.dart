import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:financial_pet/core/models/task.dart';
import 'package:financial_pet/core/services/pet_service.dart';
import 'package:financial_pet/core/services/task_service.dart';
import 'package:financial_pet/core/services/wallet_service.dart';

/// Пул заданий для теста: 5 штук (ротация забирает 3).
List<Task> _pool() => [
      for (var i = 0; i < 5; i++)
        Task(
          id: 't$i',
          topic: TaskTopic.values[i % TaskTopic.values.length],
          title: 'Задание $i',
          scenario: 'Ситуация $i',
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
        ),
    ];

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
    tasks = TaskService(prefs, wallet, pet, _pool());
    now = tasks.clock();
    tasks.clock = () => now;
  });

  tearDown(() {
    tasks.dispose();
    pet.dispose();
    wallet.dispose();
  });

  test('свежий набор: из пула 5 выбираются 3', () {
    expect(tasks.tasks, hasLength(3));
    expect(tasks.availableCount, 3);
    expect(tasks.completedTasks, isEmpty);
  });

  test('ротация детерминирована: два сервиса на тот же день выбирают одинаково',
      () {
    final a = tasks.selectedIds;
    final b = TaskService(prefs, wallet, pet, _pool()).selectedIds;
    expect(a, b);
    expect(a, hasLength(3)); // _tasksPerDay
    expect(tasks.availableCount, 3);
  });

  test('после полуночи выполнившееся задание снова доступно (повтор)', () {
    final t = tasks.availableTasks.first;
    tasks.answer(t.id, 'a');
    expect(tasks.availableTasks.map((x) => x.id), isNot(contains(t.id)));
    // Новый день: задание выполнено «вчера» → доступно для повторного обзора.
    now = now.add(const Duration(days: 1));
    expect(tasks.availableTasks.map((x) => x.id), contains(t.id));
  });

  test('верный ответ: награда, опыт, питомец рад, задание закрыто', () {
    final t = tasks.availableTasks.first;
    final balanceBefore = wallet.balance;
    final xpBefore = pet.pet!.totalXp;
    final funBefore = pet.pet!.fun;

    final result = tasks.answer(t.id, 'a');

    expect(result, isNotNull);
    expect(result!.isCorrect, isTrue);
    expect(result.reward, t.reward);
    expect(wallet.balance, balanceBefore + t.reward);
    expect(pet.pet!.totalXp, xpBefore + quizXp);
    expect(pet.pet!.fun, greaterThan(funBefore)); // питомец рад
    expect(tasks.completedTasks.map((x) => x.id), contains(t.id));
    expect(tasks.streak, 1);
  });

  test('неверный ответ: без награды, питомец грустит, можно повторить', () {
    final t = tasks.availableTasks.first;
    final balanceBefore = wallet.balance;
    final funBefore = pet.pet!.fun;

    final result = tasks.answer(t.id, 'b');

    expect(result, isNotNull);
    expect(result!.isCorrect, isFalse);
    expect(result.reward, 0);
    expect(wallet.balance, balanceBefore); // без последствий баланса
    expect(pet.pet!.fun, lessThan(funBefore)); // питомец грустит
    // Задание ещё доступно — можно попробовать ещё раз.
    expect(tasks.availableTasks.map((x) => x.id), contains(t.id));
    expect(tasks.completedTasks, isEmpty);
  });

  test('повторное верное в тот же день отклоняется', () {
    final t = tasks.availableTasks.first;
    tasks.answer(t.id, 'a');
    expect(tasks.answer(t.id, 'a'), isNull);
  });

  test('ответ на не-существующий вариант → null', () {
    final t = tasks.availableTasks.first;
    expect(tasks.answer(t.id, 'nope'), isNull);
  });

  test('повторное верное на следующий день: награда и стрик растёт', () {
    final t = tasks.availableTasks.first;
    tasks.answer(t.id, 'a');
    expect(tasks.streak, 1);

    now = now.add(const Duration(days: 1));
    // Вчера выполняли — стрик продолжится при новом выполнении.
    expect(tasks.availableTasks, isNotEmpty);
    tasks.answer(tasks.availableTasks.first.id, 'a');
    expect(tasks.streak, 2);
  });

  test('максимальный стрик не сбрасывается при пропуске дней', () {
    tasks.answer(tasks.availableTasks.first.id, 'a');
    expect(tasks.maxStreak, 1);
    now = now.add(const Duration(days: 1));
    tasks.answer(tasks.availableTasks.first.id, 'a');
    expect(tasks.maxStreak, 2);

    // Пропустили несколько дней: стрик сбросился, рекорд сохранился.
    now = now.add(const Duration(days: 3));
    tasks.answer(tasks.availableTasks.first.id, 'a');
    expect(tasks.streak, 1);
    expect(tasks.maxStreak, 2);
  });

  test('история сохраняется: новый сервис видит выполнения и стрик', () {
    final t = tasks.availableTasks.first;
    tasks.answer(t.id, 'a');
    expect(tasks.streak, 1);

    tasks.dispose();
    tasks = TaskService(prefs, wallet, pet, _pool());
    tasks.clock = () => now;

    expect(tasks.streak, 1);
    expect(tasks.completedTasks.map((x) => x.id), contains(t.id));
  });

  test('completedHistory: новые выполнения первыми, count растёт', () {
    final available = tasks.availableTasks;
    expect(available, hasLength(greaterThanOrEqualTo(2)));

    tasks.answer(available.first.id, 'a');
    expect(tasks.completedCount, 1);
    expect(tasks.completedHistory, hasLength(1));
    expect(tasks.completedHistory.first.$1.id, available.first.id);

    // Второе выполнение позже по времени → становится первым в истории.
    now = now.add(const Duration(hours: 1));
    final second = available[1];
    tasks.answer(second.id, 'a');
    expect(tasks.completedCount, 2);
    expect(tasks.completedHistory, hasLength(2));
    expect(tasks.completedHistory.first.$1.id, second.id);
  });

  test('resetProgress: очищает выполнения, стрик и историю', () {
    tasks.answer(tasks.availableTasks.first.id, 'a');
    expect(tasks.completedTasks, isNotEmpty);
    expect(tasks.streak, 1);
    expect(tasks.completedCount, greaterThanOrEqualTo(1));

    tasks.resetProgress();
    expect(tasks.streak, 0);
    expect(tasks.maxStreak, 0);
    expect(tasks.completedTasks, isEmpty);
    expect(tasks.completedCount, 0);
    expect(tasks.completedHistory, isEmpty);
    expect(tasks.availableCount, 3);
  });

  test('пустой контент: ничего не предлагает, answer → null', () {
    final empty = TaskService(prefs, wallet, pet, const []);
    expect(empty.availableCount, 0);
    expect(empty.answer('t0', 'a'), isNull);
  });

  group('Раунды дня: новые задания без ожидания завтра', () {
    test('после 3 выполненных открывается следующий срез пула', () {
      expect(tasks.availableTasks, hasLength(3));

      // Выполняем весь текущий набор.
      for (final t in List.of(tasks.availableTasks)) {
        tasks.answer(t.id, 'a');
      }
      expect(tasks.completedTasks, hasLength(3));

      // Раунд 1: из пула 5 осталось 2 задания — без пересечений
      // с пройденными.
      final next = tasks.availableTasks;
      expect(next, hasLength(2));
      final doneIds = tasks.completedTasks.map((t) => t.id).toSet();
      expect(next.every((t) => !doneIds.contains(t.id)), isTrue);
    });

    test('пул исчерпан: новых нет, «приходи завтра»', () {
      // Пул 5: раунд 0 (3) + раунд 1 (2) = всё.
      var guard = 0;
      while (tasks.availableTasks.isNotEmpty && guard < 10) {
        for (final t in List.of(tasks.availableTasks)) {
          tasks.answer(t.id, 'a');
        }
        guard++;
      }
      expect(tasks.availableTasks, isEmpty);
      expect(tasks.completedTasks, hasLength(5));
    });

    test('набор детерминирован: раунд 1 одинаков для двух сервисов', () {
      for (final t in List.of(tasks.availableTasks)) {
        tasks.answer(t.id, 'a');
      }
      final roundOne = tasks.selectedIds;
      final other = TaskService(prefs, wallet, pet, _pool());
      expect(other.selectedIds, roundOne);
    });
  });

  group('Уровень питомца через квиз', () {
    test('3 верных (3×20 XP = 60) → уровень 2, празднование в итоге', () {
      final results = [
        tasks.answer(tasks.availableTasks.first.id, 'a'), // 20 XP
        tasks.answer(tasks.availableTasks.first.id, 'a'), // 40 XP
        tasks.answer(tasks.availableTasks.first.id, 'a'), // 60 XP → ур. 2
      ];
      expect(results.map((r) => r!.leveledUp), [false, false, true]);
      expect(results.last!.level, 2);
      expect(results.last!.petName, 'Муся');
    });

    test('неверный ответ: без опыта и без празднования', () {
      final result = tasks.answer(tasks.availableTasks.first.id, 'b');
      expect(result!.isCorrect, isFalse);
      expect(result.leveledUp, isFalse);
      expect(pet.pet!.totalXp, 0);
    });
  });
}

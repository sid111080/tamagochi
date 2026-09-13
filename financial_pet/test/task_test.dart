import 'package:flutter_test/flutter_test.dart';

import 'package:financial_pet/models/task.dart';

void main() {
  group('TaskPool', () {
    test('пул содержит 12 ежедневных и 6 еженедельных заданий', () {
      final daily =
          TaskPool.all.where((t) => t.frequency == TaskFrequency.daily);
      final weekly =
          TaskPool.all.where((t) => t.frequency == TaskFrequency.weekly);
      expect(daily, hasLength(12));
      expect(weekly, hasLength(6));
    });

    test('идентификаторы уникальны', () {
      final ids = TaskPool.all.map((t) => t.id).toSet();
      expect(ids.length, TaskPool.all.length);
    });

    test('в пуле есть задания всех уровней сложности', () {
      final difficulties =
          TaskPool.all.map((t) => t.difficulty).toSet();
      expect(difficulties, containsAll(TaskDifficulty.values));
    });
  });

  group('Task', () {
    test('новое задание доступно', () {
      final t = TaskPool.all.first;
      expect(t.isAvailableNow(DateTime.now()), isTrue);
    });

    test('выполненное сегодня (daily) недоступно', () {
      final t = TaskPool.all.first.cloneFresh();
      t.completed = true;
      t.completedAt = DateTime.now();
      expect(t.isAvailableNow(DateTime.now()), isFalse);
    });

    test('выполненное вчера (daily) снова доступно', () {
      final t = TaskPool.all.first.cloneFresh();
      t.completed = true;
      t.completedAt = DateTime.now().subtract(const Duration(days: 1));
      expect(t.isAvailableNow(DateTime.now()), isTrue);
    });

    test('resetIfStale сбрасывает устаревшее выполнение', () {
      final t = TaskPool.all.first.cloneFresh();
      t.completed = true;
      t.completedAt = DateTime.now().subtract(const Duration(days: 2));
      t.resetIfStale(DateTime.now());
      expect(t.completed, isFalse);
      expect(t.completedAt, isNull);
    });

    test('cloneFresh очищает выполнение, сохраняет id и сложность', () {
      final t = TaskPool.all
          .firstWhere((t) => t.difficulty == TaskDifficulty.hard)
        ..completed = true;
      final fresh = t.cloneFresh();
      expect(fresh.completed, isFalse);
      expect(fresh.id, t.id);
      expect(fresh.difficulty, t.difficulty);
    });

    test('сложность переживает сериализацию', () {
      final hard =
          TaskPool.all.firstWhere((t) => t.difficulty == TaskDifficulty.hard);
      final restored = Task.fromJson(hard.toJson());
      expect(restored.difficulty, TaskDifficulty.hard);
    });

    test('старый json без difficulty читается как easy', () {
      final t = TaskPool.all.first.toJson()
        ..remove('difficulty');
      final restored = Task.fromJson(t);
      expect(restored.difficulty, TaskDifficulty.easy);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';

import 'package:financial_pet/models/task.dart';

void main() {
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

    test('cloneFresh очищает выполнение, сохраняет id', () {
      final t = TaskPool.all.first.cloneFresh()..completed = true;
      final fresh = t.cloneFresh();
      expect(fresh.completed, isFalse);
      expect(fresh.id, t.id);
    });
  });
}

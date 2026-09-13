import 'package:flutter_test/flutter_test.dart';

import 'package:financial_pet/models/wallet.dart';

void main() {
  group('Wallet', () {
    test('старт: баланс 50', () {
      expect(Wallet().balance, 50);
    });

    test('earn: добавляет монеты и пишет операцию', () {
      final w = Wallet();
      w.earn(30, 'Задание', '📅');
      expect(w.balance, 80);
      expect(w.transactions.single.amount, 30);
    });

    test('trySpend: списывает, если хватает', () {
      final w = Wallet(balance: 50);
      expect(w.trySpend(30, 'Корм', '🍎'), isTrue);
      expect(w.balance, 20);
    });

    test('trySpend: не хватает — отказ', () {
      final w = Wallet(balance: 10);
      expect(w.trySpend(30, 'Корм', '🍎'), isFalse);
      expect(w.balance, 10);
    });

    test('canAfford: сравнивает с балансом', () {
      final w = Wallet(balance: 15);
      expect(w.canAfford(15), isTrue);
      expect(w.canAfford(16), isFalse);
    });

    test('сериализация: круговой путь', () {
      final w = Wallet(balance: 50)..earn(20, 'x', '🪙');
      final restored = Wallet.fromJson(w.toJson());
      expect(restored.balance, 70);
      expect(restored.transactions, hasLength(1));
    });
  });
}

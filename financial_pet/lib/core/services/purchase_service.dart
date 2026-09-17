import 'package:flutter/foundation.dart';

import '../models/budget.dart';
import '../models/purchase.dart';
import '../../data/content/purchases.dart';
import 'pet_service.dart';
import 'wallet_service.dart';

/// Итог покупки: для обратной связи в UI (тост/диалог).
class PurchaseResult {
  const PurchaseResult({
    required this.success,
    required this.message,
    this.emoji,
  });

  /// Куплено ли (успешное списание и применение эффекта).
  final bool success;

  /// Детское объяснение: что купили и что изменилось / чего не хватает.
  final String message;

  /// Эмодзи для тоста (эмодзи товара или 🪙 при нехватке).
  final String? emoji;
}

/// Магазин: каталог товаров (обязательные + необязательные) и покупка (ТЗ §8.6).
///
/// Покупка: списание монет + влияние на питомца + фиксация в факте периода.
/// Как и [PetService]/[PiggyBankService] — реализует [SpendReporter], чтобы
/// расход попадал в текущий период (направление по категории).
class PurchaseService extends ChangeNotifier {
  PurchaseService(this._wallet, this._pet) : catalog = purchaseCatalog;

  final WalletService _wallet;
  final PetService _pet;

  /// Каталог товаров (учебный контент, отдельный слой данных).
  final List<Purchase> catalog;

  /// Кто фиксирует расходы (движок периодов). Nullable — без него покупка
  /// работает, но не попадает в факт периода.
  SpendReporter? spendReporter;

  List<Purchase> get required => catalog
      .where((p) => p.category == PurchaseCategory.required)
      .toList();

  List<Purchase> get optional => catalog
      .where((p) => p.category == PurchaseCategory.optional)
      .toList();

  /// Найти товар по [id] (null, если нет).
  Purchase? byId(String id) {
    for (final p in catalog) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Хватает ли на товар (для состояния «купить» в UI).
  bool canAfford(Purchase product) => _wallet.canAfford(product.price);

  /// Купить товар: списать монеты, применить эффект, зафиксировать в периоде.
  ///
  /// При нехватке средств — объяснение и варианты (ТЗ §8.6), баланс не
  /// уйдёт в минус.
  PurchaseResult buy(String id) {
    final product = byId(id);
    if (product == null) {
      return const PurchaseResult(
        success: false,
        message: 'Такого товара нет в магазине',
      );
    }
    if (!_wallet.canAfford(product.price)) {
      final short = product.price - _wallet.balance;
      return PurchaseResult(
        success: false,
        emoji: '🪙',
        message:
            'Не хватает $short монеток. Сделай задание или подожди — и купи!',
      );
    }
    // Списание: кошелёк сам не уходит в минус.
    final spent = _wallet.trySpend(
        product.price, 'Покупка: ${product.name}', product.emoji);
    if (!spent) {
      return const PurchaseResult(
        success: false,
        emoji: '🪙',
        message: 'Не хватило монеток. Сделай задание!',
      );
    }
    // Влияние на питомца.
    _pet.applyPurchaseEffect(
      hunger: product.hunger.toDouble(),
      fun: product.fun.toDouble(),
      cleanliness: product.cleanliness.toDouble(),
    );
    // Фиксация в факте периода: направление по категории.
    spendReporter?.reportSpend(
      product.category == PurchaseCategory.required
          ? BudgetDirection.required
          : BudgetDirection.optional,
      product.price,
    );
    return PurchaseResult(
      success: true,
      emoji: product.emoji,
      message: 'Купил(а): ${product.name}! ${product.effectLabel}.',
    );
  }
}

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/piggy_bank_goal.dart';
import 'pet_service.dart';
import 'wallet_service.dart';

/// Ключ хранилища.
const String _kPiggyBank = 'piggy_bank_v1';

/// Опыт питомца, когда цель копилки достигнута.
const int goalReachedXp = 20;

/// Копилка: цели, на которые ребёнок откладывает монетки.
/// Отложенные монеты уходят из баланса кошелька — это настоящие «накопления».
class PiggyBankService extends ChangeNotifier {
  PiggyBankService(this._prefs, this._wallet, this._pet) {
    _goals = _load();
  }

  final SharedPreferences _prefs;
  final WalletService _wallet;
  final PetService _pet;

  late List<PiggyBankGoal> _goals;

  List<PiggyBankGoal> get goals => List.unmodifiable(_goals);

  /// Всего накоплено по всем целям.
  int get totalSaved => _goals.fold(0, (sum, g) => sum + g.saved);

  /// Создать цель. [target] — сколько монеток нужно собрать.
  bool addGoal(String title, String emoji, int target) {
    if (title.trim().isEmpty || target <= 0) return false;
    _goals.add(PiggyBankGoal(
      id: 'goal_${DateTime.now().microsecondsSinceEpoch}',
      title: title.trim(),
      emoji: emoji,
      target: target,
    ));
    _save();
    return true;
  }

  /// Отложить [amount] монеток в цель. False, если их не хватает в кошельке.
  bool saveToGoal(String goalId, int amount) {
    final goal =
        _goals.where((g) => g.id == goalId && !g.isReached).firstOrNull;
    if (goal == null || amount <= 0) return false;
    final toSave = amount > goal.target - goal.saved
        ? goal.target - goal.saved
        : amount;
    if (toSave <= 0) return false;
    if (!_wallet.trySpend(
        toSave, 'Копилка: ${goal.title}', goal.emoji)) {
      return false;
    }
    final before = goal.isReached;
    goal.saved += toSave;
    if (!before && goal.isReached) {
      goal.rewarded = true;
      _pet.addXp(goalReachedXp);
    }
    _save();
    return true;
  }

  /// Достигнута ли цель последним пополнением (для празднования в UI).
  bool justReached(String goalId) =>
      _goals.where((g) => g.id == goalId).firstOrNull?.isReached ?? false;

  List<PiggyBankGoal> _load() {
    final raw = _prefs.getString(_kPiggyBank);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) =>
              PiggyBankGoal.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  void _save() {
    _prefs.setString(
        _kPiggyBank, jsonEncode(_goals.map((g) => g.toJson()).toList()));
    notifyListeners();
  }
}

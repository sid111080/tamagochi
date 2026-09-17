import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/budget.dart';
import '../models/pet.dart';
import 'wallet_service.dart';

/// Ключ хранилища.
const String _kPet = 'pet_v1';

/// Стоимость заботы за действие (монетками).
class CareCosts {
  static const int feed = 15;
  static const int play = 10;
  static const int wash = 10;
}

/// Управляет питомцем: создание, забота, рост, время.
/// Зависит от [WalletService], чтобы действия тратили монетки.
class PetService extends ChangeNotifier {
  PetService(this._prefs, this._wallet) {
    _pet = _load();
    _applyOfflineDecay();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _tick());
  }

  final SharedPreferences _prefs;
  final WalletService _wallet;
  Pet? _pet;
  late final Timer _timer;

  /// Кто получает сведения о тратах (движок периодов). Nullable —
  /// без него забота работает как раньше (старые сценарии/тесты).
  SpendReporter? spendReporter;

  /// Демо-режим: без реального времени — периодический спад статусов
  /// отключён, чтобы питомец не «старел», пока идут этапы.
  bool demoMode = false;

  bool _justLeveledUp = false;

  Pet? get pet => _pet;
  bool get hasPet => _pet != null;

  /// Флаг: произошло повышение уровня при последнем действии.
  bool get justLeveledUp => _justLeveledUp;
  void consumeLevelUp() => _justLeveledUp = false;

  Pet? _load() {
    final raw = _prefs.getString(_kPet);
    if (raw == null) return null;
    try {
      return Pet.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Создать нового питомца.
  void createPet(String name, String speciesId) {
    final trimmed = name.trim();
    _pet = Pet(
      id: 'pet_${DateTime.now().microsecondsSinceEpoch}',
      name: trimmed.isEmpty ? 'Питомец' : trimmed,
      speciesId: speciesId,
      hunger: 80,
      fun: 80,
      cleanliness: 80,
    );
    _save();
  }

  /// Удалить питомца (сброс профиля / выход из демо-режима).
  void removePet() {
    _pet = null;
    _save();
  }

  void _applyOfflineDecay() {
    final p = _pet;
    if (p == null) return;
    final since = DateTime.now().difference(p.lastDecayAt);
    // Ограничиваем, чтобы питомец не "умер" за долгое отсутствие.
    p.decay(since > const Duration(hours: 6)
        ? const Duration(hours: 6)
        : since);
    _save();
  }

  void _tick() {
    if (demoMode) return; // демо-режим: без реального времени.
    final p = _pet;
    if (p == null) return;
    final since = DateTime.now().difference(p.lastDecayAt);
    if (since.inSeconds < 30) return;
    p.decay(since);
    _save();
  }

  // --- Забота: тратим монеты, восстанавливаем статусы, даём опыт ---

  bool feed() => _performCare(
      () => _pet?.canFeed ?? false, CareCosts.feed,
      (p) => p.feed(), 'Покормил(а) питомца', '🍎');

  bool play() => _performCare(
      () => _pet?.canPlay ?? false, CareCosts.play,
      (p) => p.play(), 'Поиграл(а) с питомцем', '🎾');

  bool wash() => _performCare(
      () => _pet?.canWash ?? false, CareCosts.wash,
      (p) => p.wash(), 'Помыл(а) питомца', '🫧');

  bool _performCare(
    bool Function() wanted,
    int cost,
    void Function(Pet) action,
    String reason,
    String emoji,
  ) {
    final p = _pet;
    if (p == null || !wanted() || !_wallet.canAfford(cost)) return false;
    if (!_wallet.trySpend(cost, reason, emoji)) return false;
    final beforeLevel = p.level;
    action(p);
    _justLeveledUp = p.level > beforeLevel;
    // Забота — обязательные расходы (еда, уход): фиксируем в периоде.
    spendReporter?.reportSpend(BudgetDirection.required, cost);
    _save();
    return true;
  }

  /// Начислить опыт (за задание, цель копилки и т.д.).
  void addXp(int amount) {
    final p = _pet;
    if (p == null || amount <= 0) return;
    final beforeLevel = p.level;
    p.addXp(amount);
    _justLeveledUp = p.level > beforeLevel;
    _save();
  }

  /// Реакция питомца на результат квиза: [moodDelta] > 0 — рад, < 0 — грустит.
  /// Настроение обратимо, без страха и стыда (принцип «безопасной ошибки» ТЗ §6).
  void reactToQuiz(double moodDelta) {
    final p = _pet;
    if (p == null || moodDelta == 0) return;
    p.fun = (p.fun + moodDelta).clamp(0, 100);
    p.hunger = (p.hunger + moodDelta * 0.4).clamp(0, 100);
    p.lastDecayAt = DateTime.now();
    _save();
  }

  /// Эмоциональная реакция на завершение периода: [moodDelta] > 0 — доволен,
  /// < 0 — расстроен. Затрагивает все три статуса (общее настроение дня).
  /// Обратимо, без страха и стыда (принцип «безопасной ошибки», ТЗ §6):
  /// плохой период лишь слегка опустит питомца, а не «обнулит» его.
  void applyPeriodResult(double moodDelta) {
    final p = _pet;
    if (p == null || moodDelta == 0) return;
    p.hunger = (p.hunger + moodDelta).clamp(0, 100);
    p.fun = (p.fun + moodDelta).clamp(0, 100);
    p.cleanliness = (p.cleanliness + moodDelta * 0.6).clamp(0, 100);
    p.lastDecayAt = DateTime.now();
    _save();
  }

  /// Применить эффект покупки (ТЗ §8.6): изменить статусы на дельты.
  /// Возвращает false, если питомец ещё не создан.
  bool applyPurchaseEffect({
    double hunger = 0,
    double fun = 0,
    double cleanliness = 0,
  }) {
    final p = _pet;
    if (p == null) return false;
    p.applyEffect(
      hunger: hunger,
      fun: fun,
      cleanliness: cleanliness,
    );
    _save();
    return true;
  }

  /// Начислить опыт за выполнение задания.
  void addXpForTask(int amount) => addXp(amount);

  void _save() {
    final p = _pet;
    if (p == null) {
      _prefs.remove(_kPet);
    } else {
      _prefs.setString(_kPet, jsonEncode(p.toJson()));
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
}

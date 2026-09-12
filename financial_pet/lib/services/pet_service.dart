import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    _save();
    return true;
  }

  /// Начислить опыт за выполнение задания.
  void addXpForTask(int amount) {
    final p = _pet;
    if (p == null || amount <= 0) return;
    final beforeLevel = p.level;
    p.addXp(amount);
    _justLeveledUp = p.level > beforeLevel;
    _save();
  }

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

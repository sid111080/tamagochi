import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'period_service.dart';
import 'pet_service.dart';
import 'piggy_bank_service.dart';
import 'task_service.dart';
import 'wallet_service.dart';

/// Демо-режим (ТЗ §8.13, §4): тестовый профиль, обязательные этапы
/// проходятся подряд без ожидания реального времени, профиль сбрасывается
/// к исходному состоянию.
///
/// Сам по себе ничего не хранит по существу — оркестрирует сброс всех
/// сервисов профиля (кошелёк, питомец, задания, копилка, периоды) и лишь
/// флаг [isDemo] держит в хранилище. Создаётся последним в дереве
/// провайдеров, чтобы иметь доступ ко всем остальным.
class DemoService extends ChangeNotifier {
  DemoService(
    this._prefs,
    this._wallet,
    this._pet,
    this._tasks,
    this._piggy,
    this._period,
  ) {
    _isDemo = _prefs.getBool(_key) ?? false;
    if (_isDemo) _applyDemoFlags();
  }

  final SharedPreferences _prefs;
  final WalletService _wallet;
  final PetService _pet;
  final TaskService _tasks;
  final PiggyBankService _piggy;
  final PeriodService _period;

  static const String _key = 'demo_mode_v1';

  /// Имя и вид демо-питомца: фиксированные, чтобы сценарий воспроизводился
  /// одинаково при каждом запуске.
  static const String demoPetName = 'Муся';
  static const String demoPetSpecies = 'kitten';

  bool _isDemo = false;

  /// Включён ли демо-режим.
  bool get isDemo => _isDemo;

  /// В демо-режиме питомец не «стареет», а все задания доступны сразу.
  void _applyDemoFlags() {
    _pet.demoMode = true;
    _tasks.setDemoAll(true);
  }

  void _releaseDemoFlags() {
    _pet.demoMode = false;
    _tasks.setDemoAll(false);
  }

  /// Войти в демо-режим: чистый тестовый профиль со всё включённым.
  void enterDemo() {
    _seedDemoProfile();
    _applyDemoFlags();
    _isDemo = true;
    _persist();
  }

  /// Сбросить демо-профиль к исходному состоянию — заново пройти сценарий.
  void resetDemo() {
    _seedDemoProfile();
    notifyListeners();
  }

  /// Выйти из демо: вернуть чистый исходный профиль (без питомца).
  void exitDemo() {
    _cleanSlate();
    _releaseDemoFlags();
    _isDemo = false;
    _persist();
  }

  /// Тестовый профиль: питомец по умолчанию, стартовый баланс, все задания
  /// доступны, копилка и периоды свежие.
  void _seedDemoProfile() {
    _wallet.reset();
    _piggy.reset();
    _period.reset();
    _tasks.resetProgress();
    _pet
      ..removePet()
      ..createPet(demoPetName, demoPetSpecies);
    notifyListeners();
  }

  /// Чистый исходный профиль: стартовый баланс, без питомца, без целей.
  void _cleanSlate() {
    _wallet.reset();
    _piggy.reset();
    _period.reset();
    _tasks.resetProgress();
    _pet.removePet();
    notifyListeners();
  }

  void _persist() {
    _prefs.setBool(_key, _isDemo);
    notifyListeners();
  }
}

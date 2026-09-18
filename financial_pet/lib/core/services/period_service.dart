import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/budget.dart';
import 'pet_service.dart';
import 'wallet_service.dart';

/// Ключ хранилища (состояние игровой экономики периодов).
const String _kPeriods = 'periods_v1';

/// Сколько игровых периодов в «сезоне» (ТЗ §9: 5 последовательных).
const int periodsPerSeason = 5;

/// Движок игровой экономики: игровые периоды и план бюджета (ТЗ §8.5, §8.10).
///
/// Связывает кошелёк (доступный бюджет), питомца (последствия решений) и
/// тратопредупреждающие сервисы через [SpendReporter]. Сам период — это:
/// план → факт → сравнение план/факт → влияние на питомца → следующий период.
class PeriodService extends ChangeNotifier implements SpendReporter {
  PeriodService(this._prefs, this._wallet, this._pet) {
    _load();
  }

  final SharedPreferences _prefs;
  final WalletService _wallet;
  final PetService _pet;

  late Period _period;

  /// Номер текущего периода (1..periodsPerSeason, далее продолжается).
  int _seasonPeriod = 1;

  /// Накопленные очки финансовой ответственности (рост стадии).
  int _points = 0;

  /// Сколько периодов завершено в текущем сезоне.
  int _completed = 0;

  /// Номер сезона (цикл из [periodsPerSeason] периодов).
  int _season = 1;

  /// Итог последнего завершённого периода (показываем в UI).
  PeriodResult? _lastResult;

  // --- Доступ для UI и других сервисов ---

  /// Текущий период (после вызова — не мутировать напрямую).
  Period get period => _period;

  /// Стадия финансовой ответственности питомца (3 стадии, ТЗ §8.10).
  FinancialStage get stage => FinancialStageX.fromPoints(_points);

  /// Накопленные очки ответственности (0..15 за сезон).
  int get points => _points;

  /// Итог последнего периода (null, если ещё не завершён ни одного).
  PeriodResult? get lastResult => _lastResult;

  /// Номер текущего сезона (1..N): растёт после каждого 5-го периода.
  int get season => _season;

  bool get isPlanning => _period.phase == PeriodPhase.planning;
  bool get isActive => _period.phase == PeriodPhase.active;
  bool get isFinished => _period.phase == PeriodPhase.finished;

  /// Доступный бюджет для планирования (текущий баланс кошелька).
  int get availableBudget => _wallet.balance;

  /// Остаток, не распределённый по плану (показ при планировании).
  int get unallocated => _period.unallocated;

  // --- Планирование бюджета (ТЗ §8.5) ---

  /// Распределить [required]/[optional]/[savings] по направлениям и
  /// подтвердить план. План редактируется до подтверждения.
  ///
  /// Контроль (ТЗ §8.5): сумма распределения не превышает доступный бюджет
  /// (живой баланс кошелька). Возвращает false (период остаётся на
  /// планировании), если распределено больше, чем есть.
  bool confirmPlan({
    required int required,
    int optional = 0,
    int savings = 0,
  }) {
    if (_period.phase != PeriodPhase.planning) return false;
    final budget = _wallet.balance;
    final r = required.clamp(0, budget);
    final o = optional.clamp(0, budget);
    final s = savings.clamp(0, budget);
    // Ограничение: распределённая сумма не превышает доступный бюджет.
    if (r + o + s > budget) return false;

    // Отражаем актуальный бюджет для отображения «остатка» в UI.
    _period.budget = budget;
    _period.plan
      ..required = r
      ..optional = o
      ..savings = s;
    _period.phase = PeriodPhase.active;
    _save();
    return true;
  }

  // --- Факт: реальные траты периода ---

  /// [SpendReporter]: зафиксировать расход. Учитываем только в активной фазе
  /// (до плана и после завершения период не накапливает факт).
  @override
  void reportSpend(BudgetDirection direction, int amount) {
    if (_period.phase != PeriodPhase.active || amount <= 0) return;
    _period.fact.add(direction, amount);
    _save();
  }

  // --- Завершение периода: план vs факт → питомец ---

  /// Завершить период: вычислить итог (план vs факт), применить к питомцу
  /// и перевести период в фазу [PeriodPhase.finished]. Следующий период
  /// открывается отдельным [nextPeriod] — так UI может показать сравнение.
  /// Возвращает вычисленный итог (для обратной связи).
  PeriodResult finishPeriod() {
    if (_period.phase == PeriodPhase.finished) return _lastResult!;

    final result = _computeResult();
    _applyToPet(result);

    _lastResult = result;
    _points += result.score;
    _completed++;
    _period.phase = PeriodPhase.finished;
    _save();
    return result;
  }

  /// Открыть следующий период (цикл 1..5) в фазе планирования.
  /// Вызывается из UI после просмотра итога.
  void nextPeriod() {
    if (_period.phase != PeriodPhase.finished) return;
    _openNextPeriod();
    _save();
  }

  /// Вычислить итог периода из плана и факта (ТЗ §8.10, §6 — «безопасная ошибка»).
  PeriodResult _computeResult() {
    final requiredCovered = _period.fact.required > 0;
    // Перерасход на необязательном — мягкий минус, не катастрофа.
    final optionalWithinPlan =
        _period.fact.optional <= _period.plan.optional;
    // Регулярность накоплений: отложил что-то (или уложился в план).
    final savingsConsistent =
        _period.plan.savings == 0
            ? _period.fact.savings > 0
            : _period.fact.savings >= _period.plan.savings;

    final score = [requiredCovered, optionalWithinPlan, savingsConsistent]
        .where((v) => v)
        .length;

    final moodDelta = switch (score) {
      3 => 15.0,
      2 => 5.0,
      1 => 0.0,
      _ => -10.0,
    };

    return PeriodResult(
      periodIndex: _period.index,
      requiredCovered: requiredCovered,
      optionalWithinPlan: optionalWithinPlan,
      savingsConsistent: savingsConsistent,
      score: score,
      moodDelta: moodDelta,
      explanation: _explain(
        requiredCovered,
        optionalWithinPlan,
        savingsConsistent,
      ),
    );
  }

  /// Короткое детское объяснение: что получилось и что поправить (без стыда).
  String _explain(
    bool requiredCovered,
    bool optionalWithinPlan,
    bool savingsConsistent,
  ) {
    final good = <String>[];
    final toImprove = <String>[];

    if (requiredCovered) {
      good.add('позаботился о нужном');
    } else {
      toImprove.add('обязательные — сначала');
    }
    if (optionalWithinPlan) {
      good.add('не переплатил за лишнее');
    } else {
      toImprove.add('в следующий раз по плану');
    }
    if (savingsConsistent) {
      good.add('пополнил копилку');
    } else {
      toImprove.add('не забывай о копилке');
    }

    if (good.isEmpty) {
      return 'В этом периоде всё сложно. ${toImprove.first}!';
    }
    final head = switch (good.length) {
      3 => 'Отличный период: ',
      2 => 'Хорошо: ',
      _ => 'Неплохо: ',
    };
    final body = good.join(', ');
    final tail = toImprove.isEmpty
        ? ''
        : ' В следующий раз: ${toImprove.join(', ')}.';
    return '$head$body.$tail';
  }

  /// Применить результат периода к питомцу (обратимо, безопасно).
  void _applyToPet(PeriodResult result) {
    _pet.applyPeriodResult(result.moodDelta);
  }

  /// Открыть следующий период (цикл 1..5) в фазе планирования.
  /// Номер берём из завершённого [_period]: 5 → 1 (новый сезон), иначе +1.
  void _openNextPeriod() {
    _seasonPeriod = (_period.index % periodsPerSeason) + 1;
    if (_seasonPeriod == 1) _season++;
    _period = Period(index: _seasonPeriod, budget: _wallet.balance);
  }

  /// Сброс экономики периодов (демо-режим / сброс профиля).
  void reset() {
    _seasonPeriod = 1;
    _season = 1;
    _points = 0;
    _completed = 0;
    _lastResult = null;
    _period = Period(index: 1, budget: _wallet.balance);
    _save();
  }

  // --- Хранилище ---

  void _load() {
    final raw = _prefs.getString(_kPeriods);
    final fallback = Period(index: 1, budget: _wallet.balance);
    if (raw == null) {
      _period = fallback;
      return;
    }
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      _seasonPeriod =
          ((json['seasonPeriod'] as num? ?? 1).clamp(1, periodsPerSeason))
              .toInt();
      _season = ((json['season'] as num? ?? 1).clamp(1, 9999)).toInt();
      _points = (json['points'] as num? ?? 0).toInt();
      _completed = (json['completed'] as num? ?? 0).toInt();
      _lastResult = (json['lastResult'] as Map?) == null
          ? null
          : PeriodResult.fromJson(
              (json['lastResult'] as Map).cast<String, dynamic>());
      _period = Period.fromJson(
          (json['period'] as Map).cast<String, dynamic>());
    } catch (_) {
      _period = fallback;
    }
  }

  void _save() {
    final json = <String, dynamic>{
      'seasonPeriod': _seasonPeriod,
      'season': _season,
      'points': _points,
      'completed': _completed,
      'lastResult': _lastResult?.toJson(),
      'period': _period.toJson(),
    };
    _prefs.setString(_kPeriods, jsonEncode(json));
    notifyListeners();
  }
}

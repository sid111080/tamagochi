import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/task.dart';
import 'pet_service.dart';
import 'wallet_service.dart';

/// Ключ хранилища (квиз-версия системы заданий).
const String _kTasks = 'quiz_tasks_v1';

/// Сколько заданий из пула предлагаем за день.
const int _tasksPerDay = 3;

/// Как долго храним историю выполнений (чтобы файл не рос бесконечно).
const int _historyDays = 30;

/// Опыт питомца за выполненное задание (рост через обучение).
const int quizXp = 20;

/// Итог ответа на квиз: для UI-обратной связи.
class QuizResult {
  const QuizResult({
    required this.task,
    required this.option,
    required this.isCorrect,
    required this.reward,
  });

  final Task task;
  final TaskOption option;

  /// Верно ли выбран вариант.
  final bool isCorrect;

  /// Награда, начисленная за верный ответ (0, если ошибка).
  final int reward;
}

/// Управляет заданиями по финансовой грамотности в формате квиза.
///
/// Учебный контент (список заданий) приходит из [ContentRepository]
/// и отделён от этой логики. Каждые сутки из пула детерминированно
/// (по дате) выбираются [_tasksPerDay] задания — «приходи завтра за
/// новыми» остаётся правдой.
///
/// Ответ на задание: верный — питомец радуется, награда, задание закрыто;
/// неверный — питомец грустит, объяснение, можно попробовать ещё
/// (принцип «безопасной ошибки», ТЗ §6).
class TaskService extends ChangeNotifier {
  TaskService(this._prefs, this._wallet, this._pet, this.content) {
    _contentIndex = {for (final t in content) t.id: t};
    _refresh();
  }

  final SharedPreferences _prefs;
  final WalletService _wallet;
  final PetService _pet;

  /// Учебный контент: все задания (квизы) приложения.
  final List<Task> content;

  late final Map<String, Task> _contentIndex;

  /// Источник текущего времени (в тестах подменяется).
  DateTime Function() clock = DateTime.now;

  /// Демо-режим: все задания из контента доступны сразу (ТЗ §8.8, §8.13) —
  /// без ежедневной ротации и ожидания «завтра».
  bool _demoAll = false;

  /// Включить/выключить демо-режим набора заданий.
  void setDemoAll(bool value) {
    if (_demoAll == value) return;
    _demoAll = value;
    notifyListeners();
  }

  /// Включён ли демо-режим набора (все задания доступны сразу).
  bool get allTasksAvailable => _demoAll;

  // Идентификаторы текущего набора (сегодняшняя ротация).
  List<String> _selectedIds = const [];
  // Ключи периода (день в формате ГГГГ-ММ-ДД).
  late String _day;
  // id задания → ISO-дата выполнения.
  final Map<String, String> _completed = {};
  // Ежедневный стрик: сколько дней подряд выполняли задания.
  int _streak = 0;
  // Лучший стрик за всё время (по нему — бейджи).
  int _maxStreak = 0;
  String _lastStreakDay = '';

  late List<Task> _selected;

  /// Весь сегодняшний набор заданий (с состоянием выполнения).
  List<Task> get tasks => _selected;

  /// Идентификаторы текущей ротации (используется в тестах).
  List<String> get selectedIds => List.unmodifiable(_selectedIds);

  /// Задания, доступные к выполнению прямо сейчас.
  /// В демо-режиме — все задания из контента.
  List<Task> get availableTasks {
    final now = clock();
    final pool = _demoAll ? content : _selected;
    return pool.where((t) => _isAvailable(t.id, now)).toList();
  }

  /// Выполненные в текущем периоде (в демо — за день-сессию).
  List<Task> get completedTasks {
    final now = clock();
    final pool = _demoAll ? content : _selected;
    return pool.where((t) => !_isAvailable(t.id, now)).toList();
  }

  int get availableCount => availableTasks.length;

  int get streak => _streak;

  /// Лучший стрик за всё время (бейджи считаются по нему).
  int get maxStreak => _maxStreak;

  /// Прогресс по каждой теме: (выполнено, всего) по всем заданиям контента.
  /// Для раздела для взрослого (ТЗ §8.12: «пройденные темы»).
  Map<TaskTopic, (int, int)> get topicProgress {
    final progress = <TaskTopic, (int, int)>{};
    for (final t in content) {
      final (done, all) = progress[t.topic] ?? (0, 0);
      progress[t.topic] =
          (done + (_completed.containsKey(t.id) ? 1 : 0), all + 1);
    }
    return progress;
  }

  /// Найти задание по id из сегодняшнего набора.
  Task? taskById(String id) =>
      _selected.where((t) => t.id == id).firstOrNull;

  // --- Построение текущего набора ---

  void _refresh() {
    final now = clock();
    _day = _dayKey(now);

    final stored = _loadRaw();
    if (stored != null && stored['day'] == _day) {
      _selectedIds = _stringList(stored['ids']);
      _streak = (stored['streak'] as num?)?.toInt() ?? 0;
      _maxStreak = (stored['maxStreak'] as num?)?.toInt() ?? _streak;
      _lastStreakDay = stored['lastStreakDay'] as String? ?? '';
      if (_streak > _maxStreak) _maxStreak = _streak;
      _completed
        ..clear()
        ..addAll(_stringMap(stored['completed']));
    } else {
      _selectedIds = _selectForPeriod(_day);
      if (stored != null) {
        _streak = (stored['streak'] as num?)?.toInt() ?? 0;
        _maxStreak = (stored['maxStreak'] as num?)?.toInt() ?? _streak;
        _lastStreakDay = stored['lastStreakDay'] as String? ?? '';
        if (_streak > _maxStreak) _maxStreak = _streak;
        _completed
          ..clear()
          ..addAll(_stringMap(stored['completed']));
      }
    }

    _selected = _selectedIds
        .map((id) => _contentIndex[id])
        .whereType<Task>()
        .toList();
  }

  /// Детерминированный выбор из пула: одинаковое зерно (ключ даты)
  /// даёт одинаковый набор.
  List<String> _selectForPeriod(String day) {
    if (content.isEmpty) return const [];
    final ids = content.map((t) => t.id).toList()..shuffle(Random(_intKey(day)));
    return ids.sublist(0, _tasksPerDay.clamp(0, ids.length));
  }

  // --- Выполнение ---

  bool _isAvailable(String id, DateTime now) {
    // В демо-режиме задание закрывается до сброса профиля:
    // «без ожидания реального времени» — правило «приходи завтра» не применяется.
    if (_demoAll) return !_completed.containsKey(id);
    final at = _completed[id];
    if (at == null) return true;
    // Выполнено раньше сегодняшнего дня => снова доступно (повторный обзор).
    return _dayKey(DateTime.parse(at)) != _dayKey(now);
  }

  /// Ответ на задание. Возвращает null, если задание недоступно
  /// (не в сегодняшнем наборе или уже выполнено) или вариант не найден.
  QuizResult? answer(String taskId, String optionId) {
    final now = clock();
    final task = taskById(taskId);
    if (task == null || !_isAvailable(taskId, now)) return null;
    final option = task.optionById(optionId);
    if (option == null) return null;

    // Эмоциональное последствие: питомец реагирует на выбор.
    _pet.reactToQuiz(option.consequencePet.moodDelta);

    if (!option.isCorrect) {
      // Ошибка: без награды, но с объяснением и путём исправления.
      _save();
      return QuizResult(task: task, option: option, isCorrect: false, reward: 0);
    }

    // Верный ответ: последствие баланса (обычно 0) + награда + опыт.
    if (option.consequenceBalance != 0) {
      final abs = option.consequenceBalance.abs();
      if (option.consequenceBalance > 0) {
        _wallet.earn(abs, task.title, task.topic.badge);
      } else {
        _wallet.trySpend(abs, task.title, task.topic.badge);
      }
    }
    _wallet.earn(task.reward, task.title, task.topic.badge);
    _pet.addXp(quizXp);

    _completed[taskId] = now.toIso8601String();
    _updateStreak(now);
    _save();
    return QuizResult(
        task: task, option: option, isCorrect: true, reward: task.reward);
  }

  /// Стрик: +1, если вчера тоже выполняли; сброс в 1, если был пропуск.
  void _updateStreak(DateTime now) {
    final today = _dayKey(now);
    if (_lastStreakDay == today) return;
    final yesterday = _dayKey(now.subtract(const Duration(days: 1)));
    _streak = _lastStreakDay == yesterday ? _streak + 1 : 1;
    if (_streak > _maxStreak) _maxStreak = _streak;
    _lastStreakDay = today;
  }

  /// Полный сброс прогресса заданий (сброс профиля / демо-режим).
  void resetProgress() {
    _streak = 0;
    _maxStreak = 0;
    _lastStreakDay = '';
    _completed.clear();
    _selectedIds = _selectForPeriod(_dayKey(clock()));
    _save();
  }

  // --- Хранилище ---

  Map<String, dynamic>? _loadRaw() {
    final raw = _prefs.getString(_kTasks);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  void _save() {
    final now = clock();
    final json = <String, dynamic>{
      'day': _day,
      'ids': _selectedIds,
      'streak': _streak,
      'maxStreak': _maxStreak,
      'lastStreakDay': _lastStreakDay,
      'completed': {
        for (final e in _completed.entries)
          if (now.difference(DateTime.parse(e.value)).inDays <= _historyDays)
            e.key: e.value,
      },
    };
    _prefs.setString(_kTasks, jsonEncode(json));
    notifyListeners();
  }

  // --- Ключи периодов и утилиты ---

  /// ГГГГ-ММ-ДД текущей даты (без времени).
  static String _dayKey(DateTime d) =>
      _format(DateTime(d.year, d.month, d.day));

  static String _format(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// '2026-09-13' → 20260913: стабильное числовое зерно (в отличие от hashCode).
  static int _intKey(String key) => int.parse(key.replaceAll('-', ''));

  static List<String> _stringList(Object? raw) =>
      (raw as List?)?.map((e) => e.toString()).toList() ?? const [];

  static Map<String, String> _stringMap(Object? raw) {
    if (raw is! Map) return {};
    return raw.map((k, v) => MapEntry(k.toString(), v.toString()));
  }
}

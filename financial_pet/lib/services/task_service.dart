import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/task.dart';
import 'pet_service.dart';
import 'wallet_service.dart';

/// Ключи хранилища.
const String _kTasks = 'tasks_v2';
const String _kTasksLegacy = 'tasks_v1';

/// Сколько заданий выдаём из пула за период.
const int _dailyPerDay = 3;
const int _weeklyPerWeek = 2;

/// Как долго храним историю выполнений (чтобы файл не рос бесконечно).
const int _historyDays = 30;

/// Управляет заданиями по финансовой грамотности.
///
/// Каждые сутки из пула детерминированно (по дате) выбираются
/// [_dailyPerDay] ежедневных и раз в неделю — [_weeklyPerWeek]
/// еженедельных. Поэтому набор заданий каждый день новый и
/// «приходи завтра» — правда.
///
/// Выполнение приносит монеты (кошелёк) и опыт (питомец).
/// Ежедневный стрик растёт за выполненное ежедневное задание.
class TaskService extends ChangeNotifier {
  TaskService(this._prefs, this._wallet, this._pet) {
    _refresh();
  }

  final SharedPreferences _prefs;
  final WalletService _wallet;
  final PetService _pet;

  /// Источник текущего времени (в тестах подменяется).
  DateTime Function() clock = DateTime.now;

  static final Map<String, Task> _poolIndex = {
    for (final t in TaskPool.all) t.id: t,
  };

  // Текущий набор заданий (идентификаторы из пула).
  List<String> _ids = const [];
  // Ключи текущего периода (день и понедельник недели в формате ГГГГ-ММ-ДД).
  late String _day;
  late String _week;
  // id → ISO-время выполнения (история).
  final Map<String, String> _completedAt = {};
  // Ежедневный стрик: сколько дней подряд выполняли ежедневные задания.
  int _streak = 0;
  // Лучший стрик за всё время: по нему начисляются бейджи.
  int _maxStreak = 0;
  String _lastStreakDay = '';

  late List<Task> _tasks;

  List<Task> get tasks => _tasks;

  /// Идентификаторы текущей ротации (используется в тестах).
  List<String> get selectedIds => List.unmodifiable(_ids);

  /// Задания, доступные к выполнению прямо сейчас.
  List<Task> get availableTasks {
    final now = clock();
    return _tasks.where((t) => t.isAvailableNow(now)).toList();
  }

  /// Выполненные в текущем периоде.
  List<Task> get completedTasks {
    final now = clock();
    return _tasks.where((t) => t.completed && !t.isAvailableNow(now)).toList();
  }

  int get availableCount => availableTasks.length;

  int get streak => _streak;

  /// Лучший стрик за всё время (бейджи считаются по нему).
  int get maxStreak => _maxStreak;

  List<Task> get dailyTasks =>
      _tasks.where((t) => t.frequency == TaskFrequency.daily).toList();

  List<Task> get weeklyTasks =>
      _tasks.where((t) => t.frequency == TaskFrequency.weekly).toList();

  // --- Построение текущего набора ---

  void _refresh() {
    final now = clock();
    _day = _dayKey(now);
    _week = _weekKey(now);

    final stored = _loadRaw();
    if (stored != null) {
      _ids = _currentIds(stored);
      _streak = (stored['streak'] as num?)?.toInt() ?? 0;
      _maxStreak = (stored['maxStreak'] as num?)?.toInt() ?? _streak;
      _lastStreakDay = stored['lastStreakDay'] as String? ?? '';
      if (_streak > _maxStreak) _maxStreak = _streak;
      _completedAt
        ..clear()
        ..addAll(_stringMap(stored['completed']));
    } else {
      _ids = _selectForPeriod(_day, _week);
    }

    _tasks =
        _ids.map((id) => _fromPool(id)).whereType<Task>().toList();
    for (final t in _tasks) {
      final at = _completedAt[t.id];
      if (at != null) {
        t.completedAt = DateTime.parse(at);
        t.completed = true;
      }
    }
  }

  /// Ключи периода совпадают с сохранёнными — берём сохранённый набор,
  /// иначе формируем новый (новый день или новая неделя).
  List<String> _currentIds(Map<String, dynamic> stored) {
    if (stored['day'] == _day && stored['week'] == _week) {
      final saved = ((stored['ids'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList();
      if (saved.isNotEmpty && saved.every(_poolIndex.containsKey)) {
        return saved;
      }
    }
    return _selectForPeriod(_day, _week);
  }

  /// Детерминированный выбор из пула: одно и то же зерно (ключ даты)
  /// даёт один и тот же набор.
  List<String> _selectForPeriod(String day, String week) {
    final daily = _pick(
      TaskPool.all.where((t) => t.frequency == TaskFrequency.daily).toList(),
      _dailyPerDay,
      _intKey(day),
    );
    final weekly = _pick(
      TaskPool.all.where((t) => t.frequency == TaskFrequency.weekly).toList(),
      _weeklyPerWeek,
      _intKey(week),
    );
    return [...daily, ...weekly];
  }

  List<String> _pick(List<Task> pool, int count, int seed) {
    final ids = pool.map((t) => t.id).toList()..shuffle(Random(seed));
    return ids.sublist(0, count.clamp(0, ids.length));
  }

  Task? _fromPool(String id) {
    final t = _poolIndex[id];
    return t?.cloneFresh();
  }

  // --- Выполнение ---

  /// Выполнить задание: наградить монетами и опытом, вести стрик.
  bool completeTask(String id) {
    final now = clock();
    final t = _tasks.where((t) => t.id == id).firstOrNull;
    if (t == null || !t.isAvailableNow(now)) return false;

    t.completed = true;
    t.completedAt = now;
    _completedAt[t.id] = now.toIso8601String();
    if (t.frequency == TaskFrequency.daily) {
      _updateStreak(now);
    }

    _wallet.earn(t.coinReward, t.title, t.emoji);
    _pet.addXpForTask(t.xpReward);
    _save();
    return true;
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

  // --- Хранилище ---

  Map<String, dynamic>? _loadRaw() {
    final raw = _prefs.getString(_kTasks);
    if (raw != null) {
      try {
        return jsonDecode(raw) as Map<String, dynamic>;
      } catch (_) {
        // Повреждённые данные — начинаем заново.
      }
    }
    // Миграция со старой версии: переносим историю выполнений.
    final legacy = _prefs.getString(_kTasksLegacy);
    if (legacy != null) {
      try {
        final list = (jsonDecode(legacy) as List).cast<Map<String, dynamic>>();
        return {
          'day': '',
          'week': '',
          'ids': <String>[],
          'streak': 0,
          'maxStreak': 0,
          'lastStreakDay': '',
          'completed': <String, String>{
            for (final m in list)
              if ((m['completed'] as bool? ?? false) &&
                  m['completedAt'] != null)
                m['id'] as String: m['completedAt'] as String,
          },
        };
      } catch (_) {
        // Игнорируем — просто начнём с чистого набора.
      }
    }
    return null;
  }

  void _save() {
    final now = clock();
    final json = <String, dynamic>{
      'day': _day,
      'week': _week,
      'ids': _ids,
      'streak': _streak,
      'maxStreak': _maxStreak,
      'lastStreakDay': _lastStreakDay,
      'completed': {
        for (final e in _completedAt.entries)
          if (now.difference(DateTime.parse(e.value)).inDays <= _historyDays)
            e.key: e.value,
      },
    };
    _prefs.setString(_kTasks, jsonEncode(json));
    notifyListeners();
  }

  // --- Ключи периодов ---

  /// ГГГГ-ММ-ДД текущей даты (без времени).
  static String _dayKey(DateTime d) =>
      _format(DateTime(d.year, d.month, d.day));

  /// Ключ текущей недели: понедельник.
  static String _weekKey(DateTime d) {
    final monday =
        DateTime(d.year, d.month, d.day - (d.weekday - 1));
    return _format(monday);
  }

  static String _format(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// '2026-09-13' → 20260913: стабильное числовое зерно (в отличие от hashCode).
  static int _intKey(String key) => int.parse(key.replaceAll('-', ''));

  static Map<String, String> _stringMap(Object? raw) {
    if (raw is! Map) return {};
    return raw.map((k, v) => MapEntry(k.toString(), v.toString()));
  }
}

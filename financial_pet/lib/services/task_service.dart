import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/task.dart';
import 'pet_service.dart';
import 'wallet_service.dart';

/// Ключ хранилища.
const String _kTasks = 'tasks_v1';

/// Управляет заданиями по финансовой грамотности.
/// Выполнение приносит монеты (кошелёк) и опыт (питомец).
class TaskService extends ChangeNotifier {
  TaskService(this._prefs, this._wallet, this._pet) {
    _tasks = _load();
    _resetStale();
  }

  final SharedPreferences _prefs;
  final WalletService _wallet;
  final PetService _pet;
  late List<Task> _tasks;

  List<Task> get tasks => _tasks;

  /// Задания, доступные к выполнению прямо сейчас.
  List<Task> get availableTasks =>
      _tasks.where((t) => t.isAvailableNow(DateTime.now())).toList();

  List<Task> get completedTasks =>
      _tasks.where((t) => t.completed).toList();

  int get availableCount => availableTasks.length;

  List<Task> get dailyTasks =>
      _tasks.where((t) => t.frequency == TaskFrequency.daily).toList();

  List<Task> get weeklyTasks =>
      _tasks.where((t) => t.frequency == TaskFrequency.weekly).toList();

  List<Task> _load() {
    final raw = _prefs.getString(_kTasks);
    if (raw == null) {
      return TaskPool.all.map((t) => t.cloneFresh()).toList();
    }
    try {
      final list = (jsonDecode(raw) as List)
          .map((e) => Task.fromJson(e as Map<String, dynamic>))
          .toList();
      return list;
    } catch (_) {
      return TaskPool.all.map((t) => t.cloneFresh()).toList();
    }
  }

  void _resetStale() {
    final now = DateTime.now();
    for (final t in _tasks) {
      t.resetIfStale(now);
    }
  }

  /// Выполнить задание: наградить монетами и опытом.
  bool completeTask(String id) {
    final now = DateTime.now();
    final t =
        _tasks.firstWhere((t) => t.id == id, orElse: () => _tasks.first);
    if (!t.isAvailableNow(now)) return false;
    t.completed = true;
    t.completedAt = now;
    _wallet.earn(t.coinReward, t.title, t.emoji);
    _pet.addXpForTask(t.xpReward);
    _save();
    return true;
  }

  void _save() {
    _prefs.setString(
        _kTasks, jsonEncode(_tasks.map((t) => t.toJson()).toList()));
    notifyListeners();
  }
}

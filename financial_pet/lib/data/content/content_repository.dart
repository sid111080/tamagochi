import 'dart:convert';

import 'package:flutter/services.dart';

import '../../core/models/task.dart';

/// Учебный контент приложения: задания по финансовой грамотности.
///
/// Отдельный слой (требование ТЗ §4, §8.14): задания хранятся в JSON-файле
/// и подгружаются приложением. Добавить новое задание — это новый объект
/// в assets/content/tasks.json, без изменения кода.
class ContentRepository {
  const ContentRepository({this.assetPath = _defaultPath, this.loader});

  static const String _defaultPath = 'assets/content/tasks.json';

  /// Путь к JSON-файлу с заданиями.
  final String assetPath;

  /// Загрузчик содержимого. По умолчанию — asset-бандл; в тестах
  /// подставляется свой (asset-бандл в unit-тестах недоступен).
  final Future<String> Function(String path)? loader;

  /// Загрузить и разобрать все задания.
  /// Отображаются только валидные: есть id и хотя бы один вариант
  /// (для choice) или хотя бы один элемент последовательности (для sequence).
  Future<List<Task>> loadTasks() async {
    final load = loader ?? _defaultLoader;
    final raw = await load(assetPath);
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(Task.fromJson)
        .where((t) => t.id.isNotEmpty &&
            (t.options.isNotEmpty || t.sequenceItems.isNotEmpty))
        .toList();
  }

  static Future<String> _defaultLoader(String path) =>
      rootBundle.loadString(path);
}

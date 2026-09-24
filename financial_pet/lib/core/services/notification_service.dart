import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/pet.dart';
import 'demo_service.dart';
import 'pet_service.dart';

/// Бэкенд локальных уведомлений — единственное место, знающее о плагине
/// flutter_local_notifications. В unit-тестах заменяется фейком.
abstract interface class NotificationBackend {
  /// Инициализация: канал уведомлений + право POST_NOTIFICATIONS
  /// (Android 13+; на старых версиях плагин не запрашивает).
  Future<void> init();

  /// Показать уведомление. [id] фиксирован на тип события: новое
  /// заменяет старое в шторке, а не копится.
  Future<void> show({
    required int id,
    required String title,
    required String body,
  });
}

/// Реализация [NotificationBackend] для Android и iOS. Полностью локальная:
/// уведомления создаёт система устройства, интернет не нужен (ТЗ §3, §4).
class LocalNotificationBackend implements NotificationBackend {
  LocalNotificationBackend(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  static const String channelId = 'pet_events';
  static const String channelName = 'Питомец';
  static const String channelDescription =
      'Питомцу нужна забота, новые задания';

  /// Белая иконка-силуэт в res/drawable (Android; на iOS иконка не нужна).
  static const String _icon = 'ic_notify_pet';

  @override
  Future<void> init() async {
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings(_icon),
        iOS: IOSInitializationSettings(),
        macOS: DarwinInitializationSettings(),
      ),
    );
    if (Platform.isAndroid) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await android?.createNotificationChannel(
        const AndroidNotificationChannel(
          channelId,
          channelName,
          description: channelDescription,
          importance: Importance.defaultImportance,
        ),
      );
      await android?.requestNotificationsPermission();
    } else if (Platform.isIOS) {
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      await ios?.requestPermissions(alert: true, badge: true, sound: true);
    } else if (Platform.isMacOS) {
      final mac = _plugin
          .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin>();
      await mac?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  @override
  Future<void> show({
    required int id,
    required String title,
    required String body,
  }) async {
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDescription,
          icon: _icon,
        ),
        iOS: DarwinNotificationDetails(),
        macOS: DarwinNotificationDetails(),
      ),
    );
  }
}

/// Локальные уведомления о событиях с питомцем (ТЗ §3, §4: офлайн,
/// без интернета и без персональных данных).
///
/// Триггерится только при запуске приложения:
/// - питомцу нужна забота (статусы просели ниже порога за время
///   отсутствия — offline-спад применяется при старте);
/// - наступил новый день = новые задания в ротации.
///
/// В демо-режиме отключено (как спад статусов), а в приложении —
/// переключателем (ТЗ §10: «звуки и анимации можно отключить»).
class NotificationService extends ChangeNotifier {
  NotificationService(
    this._prefs,
    this._pet,
    this._demo, {
    required NotificationBackend backend,
    DateTime Function()? clock,
  })  : // Поле приватное, а параметр — публичный именованный: main.dart
        // (другая библиотека) передаёт бэкенд по имени `backend`.
        _backend = backend, // ignore: prefer_initializing_formals
        _clock = clock ?? DateTime.now,
        _enabled = _prefs.getBool(enabledKey) ?? true;

  final SharedPreferences _prefs;
  final PetService _pet;
  final DemoService _demo;
  final NotificationBackend _backend;
  final DateTime Function() _clock;

  static const String enabledKey = 'notifications_v1';
  static const String lastOpenKey = 'last_open_v1';

  /// Порог статуса: ниже — питомец «нуждается в заботе».
  static const double _careThreshold = 30;

  /// Минимальное время отсутствия: короче — пуш не показываем
  /// (анти-спам: открыл приложение на минуту и закрыл → без пуша).
  static const Duration _minAway = Duration(minutes: 30);

  /// Фиксированные id уведомлений: новое заменяет старое в шторке.
  static const int _idPetCare = 1;
  static const int _idNewTasks = 2;

  bool _enabled;

  /// Включены ли уведомления (переключатель в разделе для взрослого).
  bool get enabled => _enabled;

  /// Включить/выключить уведомления.
  void toggle() {
    _enabled = !_enabled;
    _prefs.setBool(enabledKey, _enabled);
    notifyListeners();
  }

  /// Проверка при запуске: единственная точка, запускающая уведомления.
  /// Безопасна для каждого холодного старта.
  Future<void> checkLaunchEvents() async {
    if (!_enabled || _demo.isDemo) {
      _recordOpen();
      return;
    }
    final pet = _pet.pet;
    if (pet == null) {
      _recordOpen();
      return;
    }

    final now = _clock();
    final lastRaw = _prefs.getString(lastOpenKey);
    final lastOpen = lastRaw == null ? null : DateTime.tryParse(lastRaw);

    // Питомцу нужна забота: отсутствовали достаточно долго и хотя бы
    // один статус просел ниже порога.
    final away =
        lastOpen == null ? Duration.zero : now.difference(lastOpen);
    if (away >= _minAway) {
      final needs = _careNeeds(pet);
      if (needs.isNotEmpty) {
        await _show(
          id: _idPetCare,
          title: '${pet.name} нуждается в заботе',
          body: 'Пока тебя не было, ${pet.name} ${_joinRu(needs)}. '
              'Зайди и поиграй с питомцем!',
        );
      }
    }

    // Новый день = новые задания в ротации.
    if (lastOpen != null && _dayKey(lastOpen) != _dayKey(now)) {
      await _show(
        id: _idNewTasks,
        title: 'Новые задания',
        body: 'Ждут новые задания по финансовой грамотности! 📚',
      );
    }

    _recordOpen();
  }

  /// Что «не хватает» питомцу: только статусы ниже порога.
  static List<String> _careNeeds(Pet pet) {
    final needs = <String>[];
    if (pet.hunger < _careThreshold) needs.add('проголодался 🍎');
    if (pet.fun < _careThreshold) needs.add('поскучал 🎾');
    if (pet.cleanliness < _careThreshold) needs.add('испачкался 🫧');
    return needs;
  }

  /// Русский союз: «X и Y», «X, Y и Z».
  static String _joinRu(List<String> items) => items.length == 1
      ? items.first
      : '${items.sublist(0, items.length - 1).join(', ')} и ${items.last}';

  Future<void> _show({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!_enabled || _demo.isDemo) return;
    try {
      await _backend.show(id: id, title: title, body: body);
    } catch (_) {
      // Уведомления не должны ломать игру: ошибка бэкенда глотается
      // (приложение работает офлайн, ТЗ §3).
    }
  }

  void _recordOpen() {
    _prefs.setString(lastOpenKey, _clock().toIso8601String());
  }

  /// ГГГГ-ММ-ДД (без времени) — ключ дня для сравнения.
  static String _dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

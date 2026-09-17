import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/feedback_event.dart';

/// Центральный сервис обратной связи (ТЗ §8.9).
///
/// Хранит текущее событие [FeedbackEvent] и показывает его единой
/// детско-безопасной карточкой на главном экране. Каждое действие
/// (забота, покупка, копилка, задание, период) публикует сюда событие
/// через [post]; карточка отражает, что изменилось (баланс / копилка /
/// питомец), объясняет «почему» простым языком и подсказывает следующий
/// шаг. Для неудачного выбора показывает способ исправить — без обнуления
/// прогресса, страха и стыда (принцип «безопасной ошибки», ТЗ §6).
class FeedbackService extends ChangeNotifier {
  /// Как долго карточка остаётся на экране, если [FeedbackEvent.autoDismiss].
  static const Duration defaultDuration = Duration(seconds: 5);

  FeedbackEvent? _current;
  Timer? _autoHide;

  /// Недавние события — для «Истории» (ТЗ §8.11) и тестов.
  final List<FeedbackEvent> _history = [];

  FeedbackEvent? get current => _current;
  bool get isShowing => _current != null;
  List<FeedbackEvent> get history => List.unmodifiable(_history);

  /// Опубликовать событие: показать карточку и (если нужно) спланировать
  /// автоскрытие.
  void post(FeedbackEvent event) {
    _autoHide?.cancel();
    _current = event;
    _history.insert(0, event);
    if (_history.length > 30) {
      _history.removeLast();
    }
    if (event.autoDismiss) {
      _autoHide = Timer(defaultDuration, dismiss);
    }
    notifyListeners();
  }

  /// Скрыть карточку вручную (кнопка «Понятно»).
  void dismiss() {
    if (_current == null) return;
    _autoHide?.cancel();
    _current = null;
    notifyListeners();
  }

  /// Очистить всё (сброс профиля / выход из демо).
  void clear() {
    _autoHide?.cancel();
    _current = null;
    _history.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _autoHide?.cancel();
    super.dispose();
  }
}

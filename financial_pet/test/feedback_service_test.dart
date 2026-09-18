import 'package:financial_pet/core/models/feedback_event.dart';
import 'package:financial_pet/core/models/pet.dart';
import 'package:financial_pet/core/services/feedback_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Готовое событие для тестов (успешная забота).
FeedbackEvent _careEvent({String title = 'Покормил(а) питомца'}) {
  return FeedbackEvent.care(
    actionEmoji: '🍎',
    title: title,
    message: 'Питомец сыт.',
    statusChange: 'Сытость: 40 → 80',
    cost: 15,
    nextStep: 'Дальше: задание.',
    petMood: Mood.happy,
    petName: 'Муся',
  );
}

void main() {
  late FeedbackService service;

  setUp(() {
    service = FeedbackService();
  });

  tearDown(() => service.dispose());

  group('FeedbackService', () {
    test('post: показывает событие и добавляет в историю', () {
      expect(service.isShowing, false);
      service.post(_careEvent());
      expect(service.isShowing, true);
      expect(service.current?.title, 'Покормил(а) питомца');
      expect(service.history, hasLength(1));
      expect(service.history.first.balance, '−15 монеток');
    });

    test('dismiss: прячет карточку, история сохраняется', () {
      service.post(_careEvent());
      service.dismiss();
      expect(service.isShowing, false);
      expect(service.current, isNull);
      expect(service.history, hasLength(1));
    });

    test('новое post заменяет текущее событие', () {
      service.post(_careEvent(title: 'Первое'));
      service.post(_careEvent(title: 'Второе'));
      expect(service.current?.title, 'Второе');
      expect(service.history, hasLength(2));
      // Самое свежее — в начале (для «Истории»).
      expect(service.history.first.title, 'Второе');
    });

    test('история ограничена 30 событиями', () {
      for (var i = 0; i < 35; i++) {
        service.post(_careEvent(title: 'Событие $i'));
      }
      expect(service.history, hasLength(30));
      expect(service.history.first.title, 'Событие 34');
    });

    test('clear: сбрасывает текущее и историю (сброс профиля)', () {
      service.post(_careEvent());
      service.clear();
      expect(service.isShowing, false);
      expect(service.history, isEmpty);
    });

    test('автоскрытие: карточка исчезает через defaultDuration', () async {
      service.post(_careEvent());
      expect(service.isShowing, true);
      // Ждём срабатывания таймера автоскрытия.
      await Future<void>.delayed(
          FeedbackService.defaultDuration + const Duration(milliseconds: 100));
      expect(service.isShowing, false);
      // История при автоскрытии не трогается.
      expect(service.history, hasLength(1));
    });

    test('dismiss без показанной карточки — безопасен', () {
      service.dismiss();
      expect(service.isShowing, false);
    });
  });

  group('Фабрики событий', () {
    test('careInsufficient: безопасный тон и способ исправить', () {
      final e = FeedbackEvent.careInsufficient(
        petName: 'Муся',
        needLabel: 'корм',
        needed: 7,
        petMood: Mood.okay,
      );
      expect(e.tone, FeedbackTone.caution);
      expect(e.recovery, isNotNull);
      expect(e.message, contains('не хватает 7'));
      expect(e.message, isNot(contains('умрёт')));
      expect(e.message, isNot(contains('плохой')));
    });

    test('purchaseInsufficient: покупка не совершилась', () {
      final e = FeedbackEvent.purchaseInsufficient(
        productName: 'Игрушка',
        productEmoji: '🧸',
        shortfall: 12,
        petMood: Mood.happy,
        petName: 'Муся',
      );
      expect(e.tone, FeedbackTone.caution);
      expect(e.balance, '0 монеток');
      expect(e.message, contains('не хватает 12'));
    });

    test('savings без достижения — info, с достижением — celebration', () {
      final notReached = FeedbackEvent.savings(
        amount: 10,
        goalTitle: 'Колесо',
        saved: 30,
        target: 50,
        petMood: Mood.happy,
        petName: 'Муся',
        reached: false,
      );
      expect(notReached.tone, FeedbackTone.info);
      expect(notReached.message, contains('Осталось: 20'));

      final reached = FeedbackEvent.savings(
        amount: 20,
        goalTitle: 'Колесо',
        saved: 50,
        target: 50,
        petMood: Mood.happy,
        petName: 'Муся',
        reached: true,
      );
      expect(reached.tone, FeedbackTone.celebration);
      expect(reached.title, 'Цель достигнута!');
      expect(reached.message, contains('50'));
    });

    test('levelUp: празднование', () {
      final e = FeedbackEvent.levelUp(level: 3, petName: 'Муся');
      expect(e.tone, FeedbackTone.celebration);
      expect(e.message, contains('Муся'));
    });

    test('тоны дублируются словом и эмодзи (цвет — не единственный сигнал)',
        () {
      expect(FeedbackTone.success.word, 'Отлично');
      expect(FeedbackTone.caution.word, 'Можно исправить');
      expect(FeedbackTone.celebration.emoji, '🎉');
      expect(FeedbackTone.info.word, 'Готово');
    });
  });
}

import 'pet.dart';

/// Тональность обратной связи.
///
/// Определяет акцент карточки: эмодзи-иконка + слово + цвет.
/// Цвет — не единственный сигнал: рядом всегда слово и иконка (ТЗ §10).
enum FeedbackTone {
  success, // удачное действие: забота, покупка, копилка
  info, // нейтрально: баланс, напоминание
  caution, // неудачный выбор — безопасно: что случилось + как исправить
  celebration, // достижение: новый уровень, цель достигнута
}

extension FeedbackToneMeta on FeedbackTone {
  /// Иконка (сигнал, дублирующий цвет).
  String get emoji => switch (this) {
        FeedbackTone.success => '✅',
        FeedbackTone.info => '💬',
        FeedbackTone.caution => '💛',
        FeedbackTone.celebration => '🎉',
      };

  /// Короткое слово-сигнал тона.
  String get word => switch (this) {
        FeedbackTone.success => 'Отлично',
        FeedbackTone.info => 'Готово',
        FeedbackTone.caution => 'Можно исправить',
        FeedbackTone.celebration => 'Ура!',
      };
}

/// Событие обратной связи после действия (ТЗ §8.9).
///
/// После любого действия показывает: что изменилось (баланс / копилка /
/// питомец), короткое простое объяснение «что изменилось и почему»,
/// следующий шаг и — при неудачном выборе — способ исправить.
///
/// Принципы (ТЗ §6, §8.9): объяснение без страха и стыда; неудачный
/// выбор создаёт задачу («как исправить»), а не обнуляет прогресс.
class FeedbackEvent {
  const FeedbackEvent({
    required this.tone,
    required this.emoji,
    required this.title,
    required this.message,
    this.petMood,
    this.petName,
    this.petStatus,
    this.balance,
    this.savings,
    this.nextStep,
    this.recovery,
    this.autoDismiss = true,
  });

  /// Тональность (цвет + иконка + слово).
  final FeedbackTone tone;

  /// Эмодзи действия (🍎 кормление, 🛍 покупка, 🏦 копилка…).
  final String emoji;

  /// Короткий заголовок: «Кормил(а) питомца».
  final String title;

  /// Короткое простое объяснение: что изменилось и почему (2–3 предложения,
  /// простыми словами).
  final String message;

  /// Текущее настроение питомца (лицо в карточке).
  final Mood? petMood;

  /// Имя питомца (показывается рядом с лицом).
  final String? petName;

  /// Изменение показателя питомца, например: «Сытость: 45 → 85».
  final String? petStatus;

  /// Изменение баланса, например: «−15 монеток».
  final String? balance;

  /// Изменение накоплений, например: «+20 в копилку».
  final String? savings;

  /// Следующий шаг: «Дальше: поиграй с ним 🎾».
  final String? nextStep;

  /// Способ исправить неудачный выбор (только для [FeedbackTone.caution]).
  /// Без обнуления прогресса и без страха.
  final String? recovery;

  /// Автоматически скрыться через несколько секунд (не блокирует экран).
  final bool autoDismiss;

  // ------------------------------------------------------------------ //
  //  Фабрики: готовые, детско-безопасные формулировки для действий.
  //  Данные (статусы, суммы, настроение) передаёт UI из сервисов.
  // ------------------------------------------------------------------ //

  /// Успешная забота: кормление / игра / мытьё.
  factory FeedbackEvent.care({
    required String actionEmoji,
    required String title,
    required String message,
    required String statusChange,
    required int cost,
    required String nextStep,
    Mood? petMood,
    String? petName,
  }) {
    return FeedbackEvent(
      tone: FeedbackTone.success,
      emoji: actionEmoji,
      title: title,
      message: message,
      petMood: petMood,
      petName: petName,
      petStatus: statusChange,
      balance: '−$cost монеток',
      nextStep: nextStep,
    );
  }

  /// Не хватило монеток на заботу — безопасно: объяснить + как исправить.
  factory FeedbackEvent.careInsufficient({
    required String petName,
    required String needLabel,
    required int needed,
    Mood? petMood,
  }) {
    return FeedbackEvent(
      tone: FeedbackTone.caution,
      emoji: '🪙',
      title: 'Не хватило монеток',
      message:
          'Питомец не получил $needLabel — не хватает $needed монеток. '
          'Это не страшно: можно заработать.',
      petMood: petMood ?? Mood.okay,
      petName: petName,
      balance: '0 монеток',
      recovery: 'Сделай задание, чтобы заработать монетки, и попробуй снова.',
      nextStep: 'Открой вкладку «Задания».',
    );
  }

  /// Успешная покупка.
  factory FeedbackEvent.purchaseSuccess({
    required String productEmoji,
    required String productName,
    required String effect,
    required int price,
    Mood? petMood,
    String? petName,
    String? nextStep,
  }) {
    return FeedbackEvent(
      tone: FeedbackTone.success,
      emoji: productEmoji,
      title: 'Купил(а): $productName',
      message: '$effect Питомец это заметил.',
      petMood: petMood,
      petName: petName,
      balance: '−$price монеток',
      nextStep: nextStep ?? 'Можно выбрать ещё заботу или подарок.',
    );
  }

  /// Не хватило монеток на покупку — безопасно: объяснить + как исправить.
  factory FeedbackEvent.purchaseInsufficient({
    required String productName,
    required String productEmoji,
    required int shortfall,
    Mood? petMood,
    String? petName,
  }) {
    return FeedbackEvent(
      tone: FeedbackTone.caution,
      emoji: productEmoji,
      title: 'Не хватило монеток',
      message:
          'На «$productName» не хватает $shortfall монеток. Покупка не '
          'совершилась, баланс остался прежним.',
      petMood: petMood,
      petName: petName,
      balance: '0 монеток',
      recovery: 'Сделай задание, чтобы заработать, и вернись за покупкой.',
      nextStep: 'Открой вкладку «Задания».',
    );
  }

  /// Пополнение копилки (нейтрально: деньги в копилке, не потрачены).
  factory FeedbackEvent.savings({
    required int amount,
    required String goalTitle,
    required int saved,
    required int target,
    Mood? petMood,
    String? petName,
    bool reached,
  }) {
    if (reached) {
      return FeedbackEvent(
        tone: FeedbackTone.celebration,
        emoji: '🏦',
        title: 'Цель достигнута!',
        message:
            'Ты собрал(а) $target монеток на «$goalTitle». Классная работа!',
        petMood: Mood.happy,
        petName: petName,
        savings: '+$amount в копилку',
        nextStep: 'Можно поставить новую цель.',
      );
    }
    final left = target - saved;
    return FeedbackEvent(
      tone: FeedbackTone.info,
      emoji: '🏦',
      title: 'В копилку +$amount',
      message:
          'Отложил(а) $amount монеток на «$goalTitle». Осталось: $left.',
      petMood: petMood,
      petName: petName,
      savings: '+$amount в копилку',
      nextStep: left > 0
          ? 'Добавь ещё, чтобы достичь цели.'
          : 'Цель почти достигнута!',
    );
  }

  /// Новый уровень питомца.
  factory FeedbackEvent.levelUp({
    required int level,
    required String petName,
  }) {
    return FeedbackEvent(
      tone: FeedbackTone.celebration,
      emoji: '🎉',
      title: 'Новый уровень: $level',
      message:
          '$petName растёт! Твои решения по деньгам помогают ему развиваться.',
      petMood: Mood.happy,
      petName: petName,
      nextStep: 'Продолжай заботиться и копить.',
    );
  }
}

/// Периодичность задания.
enum TaskFrequency { daily, weekly }

extension TaskFrequencyX on TaskFrequency {
  String get label => switch (this) {
        TaskFrequency.daily => 'Ежедневно',
        TaskFrequency.weekly => 'Еженедельно',
      };

  String get badge => switch (this) {
        TaskFrequency.daily => '📅',
        TaskFrequency.weekly => '🗓️',
      };
}

/// Задание по финансовой грамотности. Выполнение приносит
/// монетки и опыт (рост питомца).
class Task {
  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.coinReward,
    required this.xpReward,
    required this.frequency,
    this.completed = false,
    this.completedAt,
  });

  final String id;
  final String title;
  final String description;
  final String emoji;
  final int coinReward;
  final int xpReward;
  final TaskFrequency frequency;

  bool completed;
  DateTime? completedAt;

  /// Новая невыполненная копия (для инициализации из пула).
  Task cloneFresh() => Task(
        id: id,
        title: title,
        description: description,
        emoji: emoji,
        coinReward: coinReward,
        xpReward: xpReward,
        frequency: frequency,
        completed: false,
        completedAt: null,
      );

  /// Доступно ли задание сейчас для выполнения.
  /// daily — можно сделать раз в день; weekly — раз в неделю.
  /// Выполненное в текущем периоде задание недоступно повторно.
  bool isAvailableNow(DateTime now) {
    if (!completed || completedAt == null) return true;
    final c = completedAt!;
    final periodStart = frequency == TaskFrequency.daily
        ? DateTime(now.year, now.month, now.day)
        : _startOfWeek(now);
    // Выполнено раньше начала текущего периода => можно снова.
    return c.isBefore(periodStart);
  }

  /// Сбросить выполнение, если оно устарело (новый день/неделя).
  void resetIfStale(DateTime now) {
    if (completed && completedAt != null && isAvailableNow(now)) {
      completed = false;
      completedAt = null;
    }
  }

  static DateTime _startOfWeek(DateTime d) {
    final weekday = d.weekday; // 1 = Mon ... 7 = Sun
    final diff = weekday - 1;
    return DateTime(d.year, d.month, d.day - diff);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'emoji': emoji,
        'coinReward': coinReward,
        'xpReward': xpReward,
        'frequency': frequency.name,
        'completed': completed,
        'completedAt': completedAt?.toIso8601String(),
      };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        emoji: json['emoji'] as String,
        coinReward: (json['coinReward'] as num).toInt(),
        xpReward: (json['xpReward'] as num).toInt(),
        frequency:
            TaskFrequency.values.firstWhere((f) => f.name == json['frequency']),
        completed: json['completed'] as bool? ?? false,
        completedAt: json['completedAt'] == null
            ? null
            : DateTime.parse(json['completedAt'] as String),
      );
}

/// Пул предзаготовленных заданий (без бэкенда).
class TaskPool {
  static final List<Task> all = [
    // --- Ежедневные ---
    Task(
      id: 'd_count',
      title: 'Считалка',
      description:
          'Посчитай: 5 + 3 = ? Расскажи ответ и где ещё встречаются такие числа.',
      emoji: '🔢',
      coinReward: 15,
      xpReward: 25,
      frequency: TaskFrequency.daily,
    ),
    Task(
      id: 'd_piggy',
      title: 'Копилка',
      description:
          'Положи одну монетку в копилку — реальную или воображаемую.',
      emoji: '🏦',
      coinReward: 15,
      xpReward: 25,
      frequency: TaskFrequency.daily,
    ),
    Task(
      id: 'd_want_need',
      title: 'Хочу и нужно',
      description:
          'Выбери: вода или конфета? Что нужнее всего и почему?',
      emoji: '🍏',
      coinReward: 15,
      xpReward: 25,
      frequency: TaskFrequency.daily,
    ),
    Task(
      id: 'd_compare',
      title: 'Сравни цены',
      description:
          'Найди дома две вещи и назови, какая из них дороже.',
      emoji: '🏷️',
      coinReward: 15,
      xpReward: 25,
      frequency: TaskFrequency.daily,
    ),
    Task(
      id: 'd_plan',
      title: 'План на день',
      description:
          'Расскажи, на что ты хотел(а) бы потратить монетки сегодня.',
      emoji: '📝',
      coinReward: 15,
      xpReward: 25,
      frequency: TaskFrequency.daily,
    ),
    Task(
      id: 'd_spend',
      title: 'Умная покупка',
      description:
          'Придумай, на что потратить 10 монеток, чтобы их хватило на два дня.',
      emoji: '🛒',
      coinReward: 15,
      xpReward: 25,
      frequency: TaskFrequency.daily,
    ),
    Task(
      id: 'd_save',
      title: 'Экономка',
      description: 'Назови один способ сэкономить монетки на этой неделе.',
      emoji: '💡',
      coinReward: 15,
      xpReward: 25,
      frequency: TaskFrequency.daily,
    ),
    Task(
      id: 'd_gift',
      title: 'Подарок',
      description:
          'Подумай, кому и какой подарок ты можешь сделать за свои монетки.',
      emoji: '🎁',
      coinReward: 15,
      xpReward: 25,
      frequency: TaskFrequency.daily,
    ),
    // --- Еженедельные ---
    Task(
      id: 'w_budget',
      title: 'Бюджет на неделю',
      description:
          'Вместе с родителем составь план: как потратить карманные деньги за неделю.',
      emoji: '📊',
      coinReward: 35,
      xpReward: 45,
      frequency: TaskFrequency.weekly,
    ),
    Task(
      id: 'w_goal',
      title: 'Цель копилки',
      description:
          'Определи цель, на которую будешь копить в течение недели.',
      emoji: '🎯',
      coinReward: 35,
      xpReward: 45,
      frequency: TaskFrequency.weekly,
    ),
    Task(
      id: 'w_save_plan',
      title: 'План накоплений',
      description:
          'Сколько монеток откладывать каждый день, чтобы за неделю собрать 35?',
      emoji: '🧮',
      coinReward: 35,
      xpReward: 45,
      frequency: TaskFrequency.weekly,
    ),
    Task(
      id: 'w_share',
      title: 'Поделиться',
      description:
          'Как разделить 10 монеток с другом так, чтобы и тебе, и другу было честно?',
      emoji: '🤝',
      coinReward: 35,
      xpReward: 45,
      frequency: TaskFrequency.weekly,
    ),
  ];
}

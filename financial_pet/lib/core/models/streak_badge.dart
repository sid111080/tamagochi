/// Бейдж за ежедневный стрик: награждается за [days] дней подряд.
class StreakBadge {
  const StreakBadge({
    required this.days,
    required this.name,
    required this.emoji,
  });

  /// Сколько дней подряд нужно выполнять ежедневные задания.
  final int days;
  final String name;
  final String emoji;

  /// Получен ли бейдж при лучшем стрике [maxStreak].
  bool isEarned(int maxStreak) => maxStreak >= days;

  /// Все бейджи по возрастанию сложности.
  static const List<StreakBadge> all = [
    StreakBadge(days: 3, name: 'Бронза', emoji: '🥉'),
    StreakBadge(days: 7, name: 'Серебро', emoji: '🥈'),
    StreakBadge(days: 30, name: 'Золото', emoji: '🥇'),
  ];
}

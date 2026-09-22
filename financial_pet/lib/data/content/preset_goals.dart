/// Пресет-цели копилки (ТЗ §8.7: «Минимум 3 цели с понятной стоимостью.
/// Выбор цели…»). Показываются ребёнку как готовые варианты, когда
/// он ещё не создал ни одной цели. Выбор — это предзаполнение диалога
/// создания цели, а не автоматическое создание.
class PresetGoal {
  const PresetGoal({
    required this.title,
    required this.emoji,
    required this.target,
    required this.hint,
  });

  final String title;
  final String emoji;

  /// Стоимость цели (сколько монеток нужно собрать).
  final int target;

  /// Короткая подсказка для ребёнка.
  final String hint;
}

const List<PresetGoal> presetGoals = [
  PresetGoal(
    title: 'Новый мяч',
    emoji: '⚽',
    target: 50,
    hint: 'Собери 50 монеток — и мяч твой!',
  ),
  PresetGoal(
    title: 'Велосипед',
    emoji: '🚲',
    target: 100,
    hint: 'Большая цель: 100 монеток. Копи по чуть-чуть!',
  ),
  PresetGoal(
    title: 'Велосипед с багажником',
    emoji: '🚲',
    target: 200,
    hint: 'Самый крутой! 200 монеток — и ты едешь с багажом.',
  ),
];

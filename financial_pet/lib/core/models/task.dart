/// Первая подходящая по предикату, либо null (без package:collection).
T? firstWhereOrNull<T>(Iterable<T> items, bool Function(T) test) {
  for (final item in items) {
    if (test(item)) return item;
  }
  return null;
}

/// Тема задания — одна из трёх образовательных тем по ТЗ
/// (fg_competencies.md: планирование бюджета, сбережения, платежи и покупки).
enum TaskTopic { planningBudget, savings, payments }

extension TaskTopicX on TaskTopic {
  /// Строка из JSON-контента.
  String get jsonName => switch (this) {
        TaskTopic.planningBudget => 'planning_budget',
        TaskTopic.savings => 'savings',
        TaskTopic.payments => 'payments',
      };

  String get label => switch (this) {
        TaskTopic.planningBudget => 'Бюджет',
        TaskTopic.savings => 'Сбережения',
        TaskTopic.payments => 'Покупки',
      };

  String get badge => switch (this) {
        TaskTopic.planningBudget => '📊',
        TaskTopic.savings => '🏦',
        TaskTopic.payments => '🛒',
      };

  /// Неизвестная тема → по умолчанию [TaskTopic.planningBudget].
  static TaskTopic parse(String? name) =>
      firstWhereOrNull(TaskTopic.values, (t) => t.jsonName == name) ??
      TaskTopic.planningBudget;
}

/// Тип задания. ТЗ §8.8: «Не только выбор ответа из вариантов».
enum TaskType { choice, sequence }

extension TaskTypeX on TaskType {
  static TaskType parse(String? name) =>
      firstWhereOrNull(TaskType.values, (t) => t.name == name) ??
      TaskType.choice;
}

/// Сложность задания (влияет на размер награды).
enum TaskDifficulty { easy, medium }

extension TaskDifficultyX on TaskDifficulty {
  String get label => switch (this) {
        TaskDifficulty.easy => 'Лёгкое',
        TaskDifficulty.medium => 'Среднее',
      };

  String get badge => switch (this) {
        TaskDifficulty.easy => '🌱',
        TaskDifficulty.medium => '🌿',
      };

  /// Неизвестная сложность → по умолчанию [TaskDifficulty.easy].
  static TaskDifficulty parse(String? name) =>
      firstWhereOrNull(TaskDifficulty.values, (t) => t.name == name) ??
      TaskDifficulty.easy;
}

/// Влияние варианта на питомца (эмоциональное последствие).
/// happy — питомец радуется, sad — грустит (без страха/стыда), neutral — без изменений.
enum PetConsequence { happy, neutral, sad }

extension PetConsequenceX on PetConsequence {
  String get label => switch (this) {
        PetConsequence.happy => 'Счастлив',
        PetConsequence.neutral => 'Спокоен',
        PetConsequence.sad => 'Грустит',
      };

  /// Числовой сдвиг настроения, который сервис применяет к питомцу.
  double get moodDelta => switch (this) {
        PetConsequence.happy => 15,
        PetConsequence.neutral => 0,
        PetConsequence.sad => -15,
      };

  /// Мягкое лицо-реакция для обратной связи (без страха и стыда, ТЗ §3).
  String get emoji => switch (this) {
        PetConsequence.happy => '😊',
        PetConsequence.neutral => '🙂',
        PetConsequence.sad => '🙁',
      };

  /// Неизвестное последствие → по умолчанию [PetConsequence.neutral].
  static PetConsequence parse(String? name) =>
      firstWhereOrNull(PetConsequence.values, (p) => p.name == name) ??
      PetConsequence.neutral;
}

/// Вариант ответа на задание.
class TaskOption {
  const TaskOption({
    required this.id,
    required this.text,
    required this.isCorrect,
    required this.consequencePet,
    required this.consequenceBalance,
    required this.explanationCorrect,
    required this.explanationWrong,
  });

  final String id;
  final String text;
  final bool isCorrect;

  /// Эмоциональное последствие для питомца.
  final PetConsequence consequencePet;

  /// Воздействие на кошелёк (может быть 0 — тогда «последствием»
  /// служит настроение питомца и объяснение, а наградой — [Task.reward]).
  final int consequenceBalance;

  final String explanationCorrect;
  final String explanationWrong;

  /// Пояснение, которое показать после этого ответа:
  /// для верного — объяснение правильности, для неверного — почему не так.
  String get explanation =>
      isCorrect ? explanationCorrect : explanationWrong;

  factory TaskOption.fromJson(Map<String, dynamic> json) => TaskOption(
        id: json['id'] as String? ?? '',
        text: json['text'] as String? ?? '',
        isCorrect: json['is_correct'] as bool? ?? false,
        consequencePet:
            PetConsequenceX.parse(json['consequence_pet'] as String?),
        consequenceBalance: (json['consequence_balance'] as num? ?? 0).toInt(),
        explanationCorrect: json['explanation_correct'] as String? ?? '',
        explanationWrong: json['explanation_wrong'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'is_correct': isCorrect,
        'consequence_pet': consequencePet.name,
        'consequence_balance': consequenceBalance,
        'explanation_correct': explanationCorrect,
        'explanation_wrong': explanationWrong,
      };
}

/// Задание по финансовой грамотности в формате квиза:
/// игровая ситуация + варианты ответа с последствиями + награда.
///
/// Это чистый учебный контент (см. assets/content/tasks.json),
/// отделённый от игровой логики. Состояние выполнения живёт в TaskService.
class Task {
  const Task({
    required this.id,
    required this.topic,
    required this.title,
    required this.scenario,
    required this.competencyRef,
    required this.type,
    required this.options,
    required this.reward,
    required this.minAge,
    required this.maxAge,
    required this.difficulty,
    this.sequenceItems = const [],
    this.correctOrder = const [],
  });

  final String id;
  final TaskTopic topic;
  final String title;

  /// Игровая ситуация (2-3 предложения, понятные ребёнку 7-11 лет).
  final String scenario;

  /// Ссылка на компетенцию из Единой рамки финансовой грамотности.
  final String competencyRef;
  final TaskType type;
  final List<TaskOption> options;

  /// Награда за верный ответ (монетки в кошелёк).
  final int reward;

  final int minAge;
  final int maxAge;
  final TaskDifficulty difficulty;

  /// Элементы для задания-последовательности (тип [TaskType.sequence]).
  /// Ребёнок расставляет их в правильном порядке.
  final List<String> sequenceItems;

  /// Правильный порядок: индексы в [sequenceItems] по возрастанию
  /// (0 = первый, 1 = второй и т.д.).
  final List<int> correctOrder;

  /// Уникальный вариант ответа с данным id.
  TaskOption? optionById(String id) =>
      firstWhereOrNull(options, (o) => o.id == id);

  /// Есть ли в задании хотя бы один верный вариант (здравый контрол контента).
  bool get hasCorrectOption => options.any((o) => o.isCorrect);

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'] as String? ?? '',
        topic: TaskTopicX.parse(json['topic'] as String?),
        title: json['title'] as String? ?? '',
        scenario: json['scenario'] as String? ?? '',
        competencyRef: json['competency_ref'] as String? ?? '',
        type: TaskTypeX.parse(json['type'] as String?),
        options: ((json['options'] as List?) ?? const [])
            .map((e) => TaskOption.fromJson(e as Map<String, dynamic>))
            .toList(),
        reward: (json['reward'] as num? ?? 0).toInt(),
        minAge: (json['min_age'] as num? ?? 7).toInt(),
        maxAge: (json['max_age'] as num? ?? 11).toInt(),
        difficulty: TaskDifficultyX.parse(json['difficulty'] as String?),
        sequenceItems: ((json['sequence_items'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
        correctOrder: ((json['correct_order'] as List?) ?? const [])
            .map((e) => (e as num).toInt())
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'topic': topic.jsonName,
        'title': title,
        'scenario': scenario,
        'competency_ref': competencyRef,
        'type': type.name,
        'options': options.map((o) => o.toJson()).toList(),
        'reward': reward,
        'min_age': minAge,
        'max_age': maxAge,
        'difficulty': difficulty.name,
        if (sequenceItems.isNotEmpty) 'sequence_items': sequenceItems,
        if (correctOrder.isNotEmpty) 'correct_order': correctOrder,
      };
}

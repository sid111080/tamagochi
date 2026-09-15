/// Цель копилки: на что ребёнок откладывает монетки.
class PiggyBankGoal {
  PiggyBankGoal({
    required this.id,
    required this.title,
    required this.emoji,
    required this.target,
    this.saved = 0,
    this.rewarded = false,
  });

  final String id;
  final String title;
  final String emoji;

  /// Сколько монеток нужно собрать.
  final int target;

  /// Сколько уже накоплено (недоступно для трат, пока цель не достигнута).
  int saved;

  /// Награда за достижение цели уже выдана (чтобы не выдавать дважды).
  bool rewarded;

  bool get isReached => saved >= target;

  /// Прогресс от 0.0 до 1.0.
  double get progress => target <= 0 ? 0.0
      : (saved / target) > 1.0 ? 1.0
      : saved / target;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'emoji': emoji,
        'target': target,
        'saved': saved,
        'rewarded': rewarded,
      };

  factory PiggyBankGoal.fromJson(Map<String, dynamic> json) =>
      PiggyBankGoal(
        id: json['id'] as String,
        title: json['title'] as String,
        emoji: json['emoji'] as String,
        target: (json['target'] as num).toInt(),
        saved: (json['saved'] as num?)?.toInt() ?? 0,
        rewarded: json['rewarded'] as bool? ?? false,
      );
}

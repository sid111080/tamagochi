import 'growth_stage.dart';

/// Настроение питомца — среднее от трёх статусов.
enum Mood { happy, okay, sad }

extension MoodX on Mood {
  String get emoji => switch (this) {
        Mood.happy => '😊',
        Mood.okay => '🙂',
        Mood.sad => '😢',
      };

  String get label => switch (this) {
        Mood.happy => 'Счастлив',
        Mood.okay => 'Нормально',
        Mood.sad => 'Грустит',
      };
}

/// Виртуальный питомец. Его рост (уровень) и настроение напрямую
/// зависят от разумного управления ресурсами: заботы и заданий.
class Pet {
  Pet({
    required this.id,
    required this.name,
    required this.speciesId,
    this.hunger = 80,
    this.fun = 80,
    this.cleanliness = 80,
    this.totalXp = 0,
    List<int>? xpHistory,
    DateTime? createdAt,
    DateTime? lastDecayAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        lastDecayAt = lastDecayAt ?? DateTime.now(),
        xpHistory = xpHistory ?? [0];

  final String id;
  final String name;
  final String speciesId;

  /// Сытость, веселье, чистота: 0..100.
  double hunger;
  double fun;
  double cleanliness;

  /// Сумма заработанного опыта.
  int totalXp;

  DateTime createdAt;
  DateTime lastDecayAt;

  /// Снимки накопленного опыта (для графика роста).
  final List<int> xpHistory;

  static const int xpPerLevel = 60;
  static const double _decayPerMinute = 0.6;

  int get level => 1 + totalXp ~/ xpPerLevel;
  GrowthStage get stage => GrowthStageX.fromLevel(level);

  /// Размер аватара: каждый уровень +25% (0.68 → 1.68, потолок на 5-м).
  ///
  /// Стадии (Малыш/Ребёнок/…) — дискретны, поэтому связывать размер
  /// со стадией нельзя: на 2-м уровне питомец был бы такого же размера,
  /// как на 1-м, и рост не виден. Считаем от уровня: каждый уровень даёт
  /// заметный шаг (+25%). Для видов с одним эмодзи (панда 🐼, единорог 🦄)
  /// размер — главный сигнал роста. Аватар обёрнут в AnimatedContainer —
  /// при новом уровне плавно «выдышит».
  double get sizeScale => (0.68 + (level - 1) * 0.25).clamp(0.68, 1.68);

  /// Прогресс к следующему уровню, 0..1.
  double get progressToNext =>
      ((totalXp % xpPerLevel) / xpPerLevel).clamp(0, 1);

  /// Сколько опыта осталось до следующего уровня.
  int get xpToNext => xpPerLevel - (totalXp % xpPerLevel);

  double get averageStatus =>
      ((hunger + fun + cleanliness) / 3).clamp(0, 100);

  Mood get mood => averageStatus >= 70
      ? Mood.happy
      : averageStatus >= 40
          ? Mood.okay
          : Mood.sad;

  bool get needsCare => averageStatus < 70;

  bool get canFeed => hunger < 90;
  bool get canPlay => fun < 90;
  bool get canWash => cleanliness < 90;

  void feed() => _applyStatus(hunger: 40, xp: 5);
  void play() => _applyStatus(fun: 40, xp: 5);
  void wash() => _applyStatus(cleanliness: 50, xp: 5);

  /// Применить эффект (например, покупки): изменить статусы на дельты.
  /// Опыт НЕ начисляет — покупки не «прокачивают» питомца.
  void applyEffect({
    double hunger = 0,
    double fun = 0,
    double cleanliness = 0,
  }) {
    if (hunger != 0) this.hunger = (this.hunger + hunger).clamp(0, 100);
    if (fun != 0) this.fun = (this.fun + fun).clamp(0, 100);
    if (cleanliness != 0) {
      this.cleanliness = (this.cleanliness + cleanliness).clamp(0, 100);
    }
    lastDecayAt = DateTime.now();
  }

  /// Начислить опыт за выполнение задания.
  void addXp(int amount) {
    totalXp += amount;
    _pushXpHistory();
  }

  void _applyStatus({
    double? hunger,
    double? fun,
    double? cleanliness,
    int xp = 0,
  }) {
    if (hunger != null) this.hunger = (this.hunger + hunger).clamp(0, 100);
    if (fun != null) this.fun = (this.fun + fun).clamp(0, 100);
    if (cleanliness != null) {
      this.cleanliness = (this.cleanliness + cleanliness).clamp(0, 100);
    }
    if (xp > 0) addXp(xp);
    lastDecayAt = DateTime.now();
  }

  /// Медленный естественный спад статусов с течением времени.
  void decay(Duration since) {
    if (since.inSeconds < 30) return;
    final minutes = since.inMinutes.toDouble();
    final drop = minutes * _decayPerMinute;
    hunger = (hunger - drop).clamp(0, 100);
    fun = (fun - drop * 0.8).clamp(0, 100);
    cleanliness = (cleanliness - drop * 0.5).clamp(0, 100);
    lastDecayAt = DateTime.now();
  }

  void _pushXpHistory() {
    xpHistory.add(totalXp);
    if (xpHistory.length > 24) {
      xpHistory.removeAt(0);
    }
  }

  // --- Serializacija ---

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'speciesId': speciesId,
        'hunger': hunger,
        'fun': fun,
        'cleanliness': cleanliness,
        'totalXp': totalXp,
        'createdAt': createdAt.toIso8601String(),
        'lastDecayAt': lastDecayAt.toIso8601String(),
        'xpHistory': xpHistory,
      };

  factory Pet.fromJson(Map<String, dynamic> json) => Pet(
        id: json['id'] as String,
        name: json['name'] as String,
        speciesId: json['speciesId'] as String,
        hunger: (json['hunger'] as num).toDouble(),
        fun: (json['fun'] as num).toDouble(),
        cleanliness: (json['cleanliness'] as num).toDouble(),
        totalXp: (json['totalXp'] as num).toInt(),
        createdAt: DateTime.parse(json['createdAt'] as String),
        lastDecayAt: DateTime.parse(json['lastDecayAt'] as String),
        xpHistory: (json['xpHistory'] as List?)
                ?.map((e) => (e as num).toInt())
                .toList() ??
            [0],
      );
}

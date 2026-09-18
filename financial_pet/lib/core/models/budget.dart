/// Направление бюджета — один из трёх каналов, по которым ребёнок
/// распределяет и тратит монетки (ТЗ §5, §8.5).
///
/// - [BudgetDirection.required] — обязательные: еда и уход, питомец им жив.
/// - [BudgetDirection.optional] — необязательные: игрушка, украшение, радость.
/// - [BudgetDirection.savings] — накопления: откладываем в копилку на цель.
enum BudgetDirection { required, optional, savings }

extension BudgetDirectionX on BudgetDirection {
  /// Полное имя направления.
  String get label => switch (this) {
        BudgetDirection.required => 'Обязательные',
        BudgetDirection.optional => 'Необязательные',
        BudgetDirection.savings => 'Накопления',
      };

  /// Короткое, «детское» описание того, на что идут деньги.
  String get shortLabel => switch (this) {
        BudgetDirection.required => 'Еда и уход',
        BudgetDirection.optional => 'Приятности',
        BudgetDirection.savings => 'В копилку',
      };

  String get emoji => switch (this) {
        BudgetDirection.required => '🍎',
        BudgetDirection.optional => '🎁',
        BudgetDirection.savings => '🏦',
      };

  /// Неизвестное имя → по умолчанию [BudgetDirection.required].
  static BudgetDirection parse(String? name) =>
      BudgetDirection.values.firstWhere((d) => d.name == name,
          orElse: () => BudgetDirection.required);
}

/// Стадия финансовой ответственности (ТЗ §8.10: минимум 3 стадии развития).
///
/// В отличие от уровня (XP за заботу и задания) — зависит от *совокупности*
/// финансовых решений за несколько периодов: покрыты ли обязательные расходы,
/// уложились ли необязательные в план, копит ли ребёнок регулярно.
enum FinancialStage { beginner, confident, master }

extension FinancialStageX on FinancialStage {
  String get label => switch (this) {
        FinancialStage.beginner => 'Начинающий',
        FinancialStage.confident => 'Уверенный',
        FinancialStage.master => 'Мастер финансов',
      };

  String get emoji => switch (this) {
        FinancialStage.beginner => '🌱',
        FinancialStage.confident => '🌿',
        FinancialStage.master => '🌳',
      };

  /// Стадия по накопленным очкам ответственности.
  /// 5 периодов дают максимум 15 очков (3 за период) — пороги подобраны
  /// так, чтобы к концу пути реально дорасти до «Мастера».
  static FinancialStage fromPoints(int points) => switch (points) {
        >= 10 => FinancialStage.master,
        >= 5 => FinancialStage.confident,
        _ => FinancialStage.beginner,
      };

  /// Прогресс внутри текущей стадии, 0..1 (для шкалы в UI).
  /// Пороги: «Уверенный» с 5, «Мастер» с 10 очков; у мастера шкала полная.
  double progressToNextStage(int points) {
    final (lo, hi) = switch (this) {
      FinancialStage.beginner => (0, 5),
      FinancialStage.confident => (5, 10),
      FinancialStage.master => (10, 10),
    };
    if (hi <= lo) return 1.0;
    return ((points - lo) / (hi - lo)).clamp(0.0, 1.0);
  }

  static FinancialStage parse(String? name) =>
      FinancialStage.values.firstWhere((s) => s.name == name,
          orElse: () => FinancialStage.beginner);
}

/// Три суммы по направлениям. Используется и как план, и как факт.
class BudgetAmounts {
  BudgetAmounts({this.required = 0, this.optional = 0, this.savings = 0});

  int required;
  int optional;
  int savings;

  int get total => required + optional + savings;

  int amountFor(BudgetDirection direction) => switch (direction) {
        BudgetDirection.required => required,
        BudgetDirection.optional => optional,
        BudgetDirection.savings => savings,
      };

  /// Начислить [amount] в направление [direction] (только рост).
  void add(BudgetDirection direction, int amount) {
    if (amount <= 0) return;
    switch (direction) {
      case BudgetDirection.required:
        required += amount;
      case BudgetDirection.optional:
        optional += amount;
      case BudgetDirection.savings:
        savings += amount;
    }
  }

  Map<String, dynamic> toJson() => {
        'required': required,
        'optional': optional,
        'savings': savings,
      };

  factory BudgetAmounts.fromJson(Map<String, dynamic> json) => BudgetAmounts(
        required: (json['required'] as num? ?? 0).toInt(),
        optional: (json['optional'] as num? ?? 0).toInt(),
        savings: (json['savings'] as num? ?? 0).toInt(),
      );
}

/// Фаза игрового периода (ТЗ §5: «способ завершения — определяет команда»).
enum PeriodPhase { planning, active, finished }

extension PeriodPhaseX on PeriodPhase {
  static PeriodPhase parse(String? name) =>
      PeriodPhase.values.firstWhere((p) => p.name == name,
          orElse: () => PeriodPhase.planning);
}

/// Итог завершённого периода: три критерия (ТЗ §8.10) + эмоция + объяснение.
///
/// Это *данные*: именно сервис вычисляет значения, модель лишь их хранит.
class PeriodResult {
  PeriodResult({
    required this.periodIndex,
    required this.requiredCovered,
    required this.optionalWithinPlan,
    required this.savingsConsistent,
    required this.score,
    required this.moodDelta,
    required this.explanation,
  });

  final int periodIndex;

  /// Критерий 1: обязательные расходы покрыты (ребёнок позаботился о питомце).
  final bool requiredCovered;

  /// Критерий 2: необязательные траты уложились в план (без перерасхода).
  final bool optionalWithinPlan;

  /// Критерий 3: регулярность накоплений (отложил хотя бы что-то / до плана).
  final bool savingsConsistent;

  /// Суммарный результат: сколько из трёх критериев выполнено (0..3).
  final int score;

  /// Сдвиг эмоционального состояния питомца (обратимый, без страха).
  final double moodDelta;

  /// Короткое детское объяснение: что получилось и что улучшать.
  final String explanation;

  Map<String, dynamic> toJson() => {
        'periodIndex': periodIndex,
        'requiredCovered': requiredCovered,
        'optionalWithinPlan': optionalWithinPlan,
        'savingsConsistent': savingsConsistent,
        'score': score,
        'moodDelta': moodDelta,
        'explanation': explanation,
      };

  factory PeriodResult.fromJson(Map<String, dynamic> json) => PeriodResult(
        periodIndex: (json['periodIndex'] as num? ?? 0).toInt(),
        requiredCovered: json['requiredCovered'] as bool? ?? false,
        optionalWithinPlan: json['optionalWithinPlan'] as bool? ?? false,
        savingsConsistent: json['savingsConsistent'] as bool? ?? false,
        score: (json['score'] as num? ?? 0).toInt(),
        moodDelta: (json['moodDelta'] as num? ?? 0).toDouble(),
        explanation: json['explanation'] as String? ?? '',
      );
}

/// Игровой период (ТЗ §5): завершённый цикл финансовых решений.
///
/// Внутри периода ребёнок: планирует бюджет → тратит (факт) → видит
/// сравнение плана с фактом и влияние на питомца. Периодов пять (ТЗ §9);
/// далее цикл повторяется.
class Period {
  Period({
    required this.index,
    required this.budget,
    this.phase = PeriodPhase.planning,
    BudgetAmounts? plan,
    BudgetAmounts? fact,
    this.result,
  })  : plan = plan ?? BudgetAmounts(),
        fact = fact ?? BudgetAmounts();

  /// Порядковый номер периода (1..5, далее продолжается цикл).
  int index;

  /// Доступный бюджет на начало периода (снимок баланса).
  int budget;

  PeriodPhase phase;

  /// План: как ребёнок распределил деньги до начала периода.
  BudgetAmounts plan;

  /// Факт: реальные траты за период по каждому направлению.
  BudgetAmounts fact;

  /// Итог, вычисляется при завершении периода.
  PeriodResult? result;

  /// Не распределённый остаток (имеет смысл на фазе планирования).
  int get unallocated => (budget - plan.total).clamp(0, 999999);

  /// Можно ли ещё менять план (до подтверждения).
  bool get canEditPlan => phase == PeriodPhase.planning;

  Map<String, dynamic> toJson() => {
        'index': index,
        'budget': budget,
        'phase': phase.name,
        'plan': plan.toJson(),
        'fact': fact.toJson(),
        'result': result?.toJson(),
      };

  factory Period.fromJson(Map<String, dynamic> json) => Period(
        index: (json['index'] as num? ?? 1).toInt(),
        budget: (json['budget'] as num? ?? 0).toInt(),
        phase: PeriodPhaseX.parse(json['phase'] as String?),
        plan: BudgetAmounts.fromJson(
            (json['plan'] as Map? ?? const {}) as Map<String, dynamic>),
        fact: BudgetAmounts.fromJson(
            (json['fact'] as Map? ?? const {}) as Map<String, dynamic>),
        result: (json['result'] as Map?) == null
            ? null
            : PeriodResult.fromJson(
                (json['result'] as Map).cast<String, dynamic>()),
      );
}

/// Контракт «тратопредупреждающий»: те, кто тратит монетки (забота, копилка,
/// покупки), сообщают движку периода о каждом расходе.
///
/// Определяем здесь (в слое моделей), чтобы сервисы зависимостей
/// ([PetService], [PiggyBankService]) не тянули за собой [PeriodService]
/// — нет циклической зависимости: сервис хранит только интерфейс.
abstract interface class SpendReporter {
  /// Зафиксировать [amount] в направлении [direction] в текущем периоде.
  /// Период сам решает, засчитывать ли расход (только в активной фазе).
  void reportSpend(BudgetDirection direction, int amount);
}

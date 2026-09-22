/// Стадии роста питомца. Уровень напрямую зависит от заботы
/// и выполнения финансовых заданий.
enum GrowthStage { baby, child, teen, adult }

extension GrowthStageX on GrowthStage {
  /// Русский label для детей 6-9 лет.
  String get label => switch (this) {
        GrowthStage.baby => 'Малыш',
        GrowthStage.child => 'Ребёнок',
        GrowthStage.teen => 'Подросток',
        GrowthStage.adult => 'Взрослый',
      };

  /// Индекс для выбора эмодзи вида по стадии.
  int get index => GrowthStage.values.indexOf(this);

  /// «Малыш» — только 1-й уровень: уже на 2-м питомец меняет облик
  /// (эмодзи стадии + размер), чтобы рост был заметен с первого
  /// повышения уровня. Баг: при пороге `>= 3` уровни 1 и 2 давали
  /// одну стадию — кот оставался 🐱, и рост не читался.
  static GrowthStage fromLevel(int level) => switch (level) {
        >= 8 => GrowthStage.adult,
        >= 5 => GrowthStage.teen,
        >= 2 => GrowthStage.child,
        _ => GrowthStage.baby,
      };
}

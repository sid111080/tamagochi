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

  /// Множитель размера: чем взрослее, тем крупнее.
  double get sizeScale => switch (this) {
        GrowthStage.baby => 0.75,
        GrowthStage.child => 0.9,
        GrowthStage.teen => 1.05,
        GrowthStage.adult => 1.2,
      };

  /// Индекс для выбора эмодзи вида по стадии.
  int get index => ordinal;

  static GrowthStage fromLevel(int level) => switch (level) {
        >= 8 => GrowthStage.adult,
        >= 5 => GrowthStage.teen,
        >= 3 => GrowthStage.child,
        _ => GrowthStage.baby,
      };
}

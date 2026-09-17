/// Тип товара (ТЗ §8.6): обязательные и необязательные расходы.
///
/// - [PurchaseCategory.required] — питомцу нужно (корм, уход): влияет на
///   состояние и попадает в факт направления «Обязательные».
/// - [PurchaseCategory.optional] — радость и настроение: попадает в факт
///   направления «Необязательные».
enum PurchaseCategory { required, optional }

extension PurchaseCategoryX on PurchaseCategory {
  /// Полное имя категории.
  String get label => switch (this) {
        PurchaseCategory.required => 'Обязательные',
        PurchaseCategory.optional => 'Необязательные',
      };

  /// Короткое, «детское» название секции в магазине.
  String get shortLabel => switch (this) {
        PurchaseCategory.required => 'Нужное питомцу',
        PurchaseCategory.optional => 'Приятности',
      };

  String get emoji => switch (this) {
        PurchaseCategory.required => '🍎',
        PurchaseCategory.optional => '🎁',
      };
}

/// Товар в магазине (ТЗ §8.6): цена, категория и влияние на питомца.
///
/// Учебный контент, хранится в отдельном слое данных
/// ([data/content/purchases.dart]) — новый товар = новый объект в списке,
/// логика не меняется (ТЗ §8.14).
class Purchase {
  const Purchase({
    required this.id,
    required this.name,
    required this.emoji,
    required this.price,
    required this.category,
    this.hunger = 0,
    this.fun = 0,
    this.cleanliness = 0,
  });

  final String id;
  final String name;
  final String emoji;

  /// Цена в монетках.
  final int price;

  final PurchaseCategory category;

  /// Влияние на питомца: прирост статусов (применяется с clamp 0..100).
  /// Ноль — товар не влияет на этот статус.
  final int hunger;
  final int fun;
  final int cleanliness;

  /// Текст влияния на питомца: «Сытость +35» / «Веселье +20, Сытость +10».
  String get effectLabel {
    final parts = <String>[
      if (hunger != 0) 'Сытость +$hunger',
      if (fun != 0) 'Веселье +$fun',
      if (cleanliness != 0) 'Чистота +$cleanliness',
    ];
    return parts.isEmpty ? 'Радость' : parts.join(', ');
  }
}

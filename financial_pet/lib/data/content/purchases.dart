import '../../core/models/purchase.dart';

/// Каталог покупок (ТЗ §8.6, §8.14): 8 товаров, два типа.
///
/// Учебный контент — отдельный слой. Добавить товар — это новый объект в
/// списке, без изменения игровой логики.
const List<Purchase> purchaseCatalog = [
  // Обязательные: питомцу нужно, влияет на состояние.
  Purchase(
    id: 'feed',
    name: 'Корм',
    emoji: '🍖',
    price: 15,
    category: PurchaseCategory.required,
    hunger: 35,
  ),
  Purchase(
    id: 'soap',
    name: 'Мыло',
    emoji: '🧼',
    price: 12,
    category: PurchaseCategory.required,
    cleanliness: 35,
  ),
  Purchase(
    id: 'ball',
    name: 'Мячик',
    emoji: '⚽',
    price: 14,
    category: PurchaseCategory.required,
    fun: 30,
  ),
  Purchase(
    id: 'veg',
    name: 'Овощи',
    emoji: '🥕',
    price: 10,
    category: PurchaseCategory.required,
    hunger: 20,
  ),
  // Необязательные: радость и настроение, не критично.
  Purchase(
    id: 'bear',
    name: 'Медвежонок',
    emoji: '🧸',
    price: 28,
    category: PurchaseCategory.optional,
    fun: 25,
  ),
  Purchase(
    id: 'bow',
    name: 'Бантик',
    emoji: '🎀',
    price: 18,
    category: PurchaseCategory.optional,
    fun: 18,
  ),
  Purchase(
    id: 'cake',
    name: 'Тортик',
    emoji: '🎂',
    price: 22,
    category: PurchaseCategory.optional,
    fun: 20,
    hunger: 10,
  ),
  Purchase(
    id: 'tophat',
    name: 'Цилиндр',
    emoji: '🎩',
    price: 30,
    category: PurchaseCategory.optional,
    fun: 22,
  ),
];

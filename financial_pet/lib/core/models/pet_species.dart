import 'package:flutter/material.dart';

/// Вариант внешнего вида питомца: название + акцентный цвет.
/// Разные варианты одного вида визуально различимы (цвет кольца/фона).
class PetVariant {
  const PetVariant({required this.name, required this.color});
  final String name;
  final Color color;
}

/// Вид (раса) виртуального питомца. Каждый вид имеет 4 эмодзи —
/// по одному на каждую стадию роста, плюс варианты окраски.
class PetSpecies {
  const PetSpecies({
    required this.id,
    required this.displayName,
    required this.defaultName,
    required this.stageEmojis,
    required this.color,
    required this.tagline,
    required this.variants,
  });

  final String id;
  final String displayName;
  final String defaultName;

  /// 4 эмодзи: [Малыш, Ребёнок, Подросток, Взрослый].
  final List<String> stageEmojis;

  /// Акцентный цвет питомца (кольцо, карточки) — для варианта 0.
  final Color color;

  final String tagline;

  /// Варианты окраски: каждый — пара (название, цвет).
  /// 2 варианта × 5 видов = 10 визуально различимых комбинаций (ТЗ §8.2).
  final List<PetVariant> variants;

  /// Цвет для данного варианта (fallback — [color]).
  Color colorFor(int variant) =>
      variants[variant.clamp(0, variants.length - 1)].color;

  /// Название варианта (для UI выбора).
  String variantName(int variant) =>
      variants[variant.clamp(0, variants.length - 1)].name;

  /// Эмодзи для конкретной стадии роста.
  String emojiForIndex(int stageIndex) =>
      stageEmojis[stageIndex.clamp(0, stageEmojis.length - 1)];

  static const List<PetSpecies> all = [
    PetSpecies(
      id: 'kitten',
      displayName: 'Котёнок',
      defaultName: 'Муся',
      stageEmojis: ['🐱', '🐈', '🐈', '🦁'],
      color: Color(0xFFFF8A65),
      tagline: 'Ласковый и любознательный',
      variants: [
        PetVariant(name: 'Рыжий', color: Color(0xFFFF8A65)),
        PetVariant(name: 'Серый', color: Color(0xFF90A4AE)),
      ],
    ),
    PetSpecies(
      id: 'chick',
      displayName: 'Цыплёнок',
      defaultName: 'Жужа',
      stageEmojis: ['🐣', '🐤', '🐥', '🐔'],
      color: Color(0xFFFFC93C),
      tagline: 'Самый быстрый на дороге',
      variants: [
        PetVariant(name: 'Золотой', color: Color(0xFFFFC93C)),
        PetVariant(name: 'Розовый', color: Color(0xFFFFB6C7)),
      ],
    ),
    PetSpecies(
      id: 'dragon',
      displayName: 'Дракончик',
      defaultName: 'Чарли',
      stageEmojis: ['🐲', '🐉', '🐉', '🐉'],
      color: Color(0xFF6BCB77),
      tagline: 'Смелый защитник копилки',
      variants: [
        PetVariant(name: 'Зелёный', color: Color(0xFF6BCB77)),
        PetVariant(name: 'Синий', color: Color(0xFF4FC3F7)),
      ],
    ),
    PetSpecies(
      id: 'panda',
      displayName: 'Панда',
      defaultName: 'Бамба',
      stageEmojis: ['🐼', '🐼', '🐼', '🐼'],
      color: Color(0xFFA66CFF),
      tagline: 'Спокойный и добрый',
      variants: [
        PetVariant(name: 'Фиолетовый', color: Color(0xFFA66CFF)),
        PetVariant(name: 'Лавандовый', color: Color(0xFFCE93D8)),
      ],
    ),
    PetSpecies(
      id: 'unicorn',
      displayName: 'Единорог',
      defaultName: 'Нюша',
      stageEmojis: ['🦄', '🦄', '🦄', '🦄'],
      color: Color(0xFFFF7AB6),
      tagline: 'Волшебный мечтатель',
      variants: [
        PetVariant(name: 'Розовый', color: Color(0xFFFF7AB6)),
        PetVariant(name: 'Мятный', color: Color(0xFF80CBC4)),
      ],
    ),
  ];

  static PetSpecies byId(String id) =>
      all.firstWhere((s) => s.id == id, orElse: () => all.first);
}

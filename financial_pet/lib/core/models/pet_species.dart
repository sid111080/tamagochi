import 'package:flutter/material.dart';

/// Вид (раса) виртуального питомца. Каждый вид имеет 4 эмодзи —
/// по одному на каждую стадию роста, плюс акцентный цвет.
class PetSpecies {
  const PetSpecies({
    required this.id,
    required this.displayName,
    required this.defaultName,
    required this.stageEmojis,
    required this.color,
    required this.tagline,
  });

  final String id;
  final String displayName;
  final String defaultName;

  /// 4 эмодзи: [Малыш, Ребёнок, Подросток, Взрослый].
  final List<String> stageEmojis;

  /// Акцентный цвет питомца (кольцо, карточки).
  final Color color;

  final String tagline;

  /// Эмодзи для конкретной стадии роста.
  String emojiForIndex(int stageIndex) =>
      stageEmojis[stageIndex.clamp(0, stageEmojis.length - 1)];

  static const List<PetSpecies> all = [
    PetSpecies(
      id: 'kitten',
      displayName: 'Котёнок',
      defaultName: 'Муся',
      // Стадии различимы: мордочка → кошка → кошка → лев (взрослый).
      stageEmojis: ['🐱', '🐈', '🐈', '🦁'],
      color: Color(0xFFFF8A65),
      tagline: 'Ласковый и любознательный',
    ),
    PetSpecies(
      id: 'chick',
      displayName: 'Цыплёнок',
      defaultName: 'Жужа',
      stageEmojis: ['🐣', '🐤', '🐥', '🐔'],
      color: Color(0xFFFFC93C),
      tagline: 'Самый быстрый на дороге',
    ),
    PetSpecies(
      id: 'dragon',
      displayName: 'Дракончик',
      defaultName: 'Чарли',
      // Стадии различимы: мордочка (малыш/ребёнок) → полный дракон (подросток/взрослый).
      stageEmojis: ['🐲', '🐲', '🐉', '🐉'],
      color: Color(0xFF6BCB77),
      tagline: 'Смелый защитник копилки',
    ),
    PetSpecies(
      id: 'panda',
      displayName: 'Панда',
      defaultName: 'Бамба',
      stageEmojis: ['🐼', '🐼', '🐼', '🐼'],
      color: Color(0xFFA66CFF),
      tagline: 'Спокойный и добрый',
    ),
    PetSpecies(
      id: 'unicorn',
      displayName: 'Единорог',
      defaultName: 'Нюша',
      stageEmojis: ['🦄', '🦄', '🦄', '🦄'],
      color: Color(0xFFFF7AB6),
      tagline: 'Волшебный мечтатель',
    ),
  ];

  static PetSpecies byId(String id) =>
      all.firstWhere((s) => s.id == id, orElse: () => all.first);
}

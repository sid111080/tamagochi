import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/pet.dart';
import '../models/pet_species.dart';

/// Уровень питомца + прогресс до следующего.
class LevelIndicator extends StatelessWidget {
  const LevelIndicator({
    super.key,
    required this.pet,
    required this.species,
  });

  final Pet pet;
  final PetSpecies species;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: species.color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Уровень ${pet.level}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'Осталось ${pet.xpToNext} XP',
                style: const TextStyle(
                  color: AppColors.inkSoft,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: pet.progressToNext,
              minHeight: 10,
              backgroundColor: species.color.withValues(alpha: 0.18),
              valueColor: AlwaysStoppedAnimation(species.color),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Выполняй задания и заботься о питомце, чтобы он рос!',
            style: TextStyle(
              color: AppColors.inkSoft,
              fontSize: 12.5,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

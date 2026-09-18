import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../core/models/budget.dart';
import '../core/models/pet.dart';
import '../core/models/pet_species.dart';
import '../core/services/period_service.dart';

/// Уровень питомца + стадия финансовой ответственности в одной карточке.
///
/// Компактная компоновка: всё видно на главном экране без скролла
/// (ТЗ §8.10: стадии развития видны ребёнку).
class LevelIndicator extends StatelessWidget {
  const LevelIndicator({
    super.key,
    required this.pet,
    required this.species,
    this.stage,
    this.points,
    this.periodIndex,
    this.season,
  });

  final Pet pet;
  final PetSpecies species;

  /// Стадия финансовой ответственности (3 стадии по итогам периодов).
  final FinancialStage? stage;

  /// Очки ответственности (для шкалы до следующей стадии).
  final int? points;

  /// Номер текущего периода (для «Период X/Y»).
  final int? periodIndex;

  /// Номер сезона (цикл из 5 периодов), если известен.
  final int? season;

  @override
  Widget build(BuildContext context) {
    final stage = this.stage;
    final stages = FinancialStage.values;
    final current = stage == null ? -1 : stages.indexOf(stage);

    return Container(
      padding: const EdgeInsets.all(14),
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
          // Уровень + XP до следующего.
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 5),
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
              if (periodIndex != null)
                Text(
                  season != null
                      ? 'Сезон $season · период $periodIndex/$periodsPerSeason'
                      : 'Период $periodIndex/$periodsPerSeason',
                  style: const TextStyle(
                    color: AppColors.inkSoft,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                )
              else
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
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: pet.progressToNext,
              minHeight: 8,
              backgroundColor: species.color.withValues(alpha: 0.18),
              valueColor: AlwaysStoppedAnimation(species.color),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Задания и забота дают XP — питомец растёт.',
            style: TextStyle(
              color: AppColors.inkSoft,
              fontSize: 12,
              height: 1.2,
            ),
          ),
          if (stage != null) ...[
            const Divider(height: 20, color: Color(0x1A000000)),
            // Стадии: текущая подсвечена иконкой и жирным шрифтом
            // (цвет — не единственный сигнал, ТЗ §10).
            Row(
              children: [
                for (var i = 0; i < stages.length; i++) ...[
                  if (i > 0)
                    Expanded(
                      child: Center(
                        child: Container(
                          height: 3,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: i <= current
                                ? AppColors.leaf
                                : AppColors.leaf.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          stages[i].emoji,
                          style: TextStyle(
                            fontSize: i == current ? 24 : 16,
                            color: i == current
                                ? Colors.black87
                                : Colors.black.withValues(alpha: 0.3),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          stages[i].label,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            height: 1.1,
                            fontWeight: i == current
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: i == current
                                ? AppColors.ink
                                : AppColors.ink.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: stage.progressToNextStage(points ?? 0),
                minHeight: 8,
                backgroundColor: AppColors.leaf.withValues(alpha: 0.18),
                valueColor: AlwaysStoppedAnimation(AppColors.leaf),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

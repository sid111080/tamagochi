import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/models/task.dart';

/// Карточка задания-квиза: тема, сложность, ситуация, награда, кнопка.
class QuizTaskCard extends StatelessWidget {
  const QuizTaskCard({
    super.key,
    required this.task,
    required this.isDone,
    required this.onTap,
  });

  final Task task;
  final bool isDone;
  final VoidCallback onTap;

  Color get _topicColor => switch (task.topic) {
        TaskTopic.planningBudget => AppColors.leaf,
        TaskTopic.savings => AppColors.sky,
        TaskTopic.payments => AppColors.grape,
      };

  Color get _difficultyColor => switch (task.difficulty) {
        TaskDifficulty.easy => const Color(0xFF3E8E4E),
        TaskDifficulty.medium => const Color(0xFFC77800),
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDone ? AppColors.bg : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDone ? 0.03 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Бейдж темы + сложности.
          Row(
            children: [
              _chip('${task.topic.badge} ${task.topic.label}', _topicColor),
              const SizedBox(width: 8),
              _chip(
                  '${task.difficulty.badge} ${task.difficulty.label}',
                  _difficultyColor),
              const Spacer(),
              _chip('🪙 +${task.reward}', const Color(0xFFB8860B)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            task.title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            task.scenario,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
              color: AppColors.inkSoft,
            ),
          ),
          const SizedBox(height: 12),
          // Кнопка 48dp по высоте — крупная мишень для ребёнка (ТЗ §10).
          isDone
              ? Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.leaf,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('✓',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 15)),
                        SizedBox(width: 6),
                        Text('Пройдено',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 14)),
                      ],
                    ),
                  ),
                )
              : Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 48),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: onTap,
                    child: const Text(
                      'Пройти',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _chip(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color),
        ),
      );
}

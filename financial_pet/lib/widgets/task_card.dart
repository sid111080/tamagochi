import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/task.dart';

/// Карточка задания с наградой и кнопкой выполнения.
class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.onComplete,
  });

  final Task task;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final available = task.isAvailableNow(DateTime.now());
    final isDone = task.completed && !available;

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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: (isDone
                      ? AppColors.bgDeep
                      : task.frequency == TaskFrequency.daily
                          ? AppColors.leaf
                          : AppColors.grape)
                  .withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(task.emoji, style: const TextStyle(fontSize: 26)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        task.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: task.frequency == TaskFrequency.daily
                            ? AppColors.leaf.withValues(alpha: 0.18)
                            : AppColors.grape.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${task.frequency.badge} ${task.frequency.label}',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: task.frequency == TaskFrequency.daily
                              ? const Color(0xFF3E8E4E)
                              : AppColors.grape,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  task.description,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: AppColors.inkSoft,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _reward('${task.difficulty.badge} ${task.difficulty.label}',
                        _difficultyColor(task.difficulty)),
                    const SizedBox(width: 8),
                    _reward('🪙 +${task.coinReward}',
                        const Color(0xFFB8860B)),
                    const SizedBox(width: 8),
                    _reward('⭐ +${task.xpReward} XP', AppColors.grape),
                  ],
                ),
                const SizedBox(height: 10),
                if (isDone)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.leaf,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '✓ Выполнено',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  )
                else
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: available ? onComplete : null,
                      child: const Text(
                        'Выполнить',
                        style:
                            TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _difficultyColor(TaskDifficulty difficulty) => switch (difficulty) {
        TaskDifficulty.easy => const Color(0xFF3E8E4E),
        TaskDifficulty.medium => const Color(0xFFC77800),
        TaskDifficulty.hard => AppColors.grape,
      };

  Widget _reward(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      );
}

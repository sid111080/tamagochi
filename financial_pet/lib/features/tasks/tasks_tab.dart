import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../core/models/streak_badge.dart';
import '../../core/models/task.dart';
import '../../core/services/task_service.dart';
import 'quiz_screen.dart';
import 'quiz_task_card.dart';

/// Таб «Задания»: доступные квизы + стрик + бейджи.
///
/// Задания — по трём образовательным темам (fg_competencies.md):
/// бюджет, сбережения, покупки. Каждый день — по 3 задания (раунд);
/// все 3 выполнены — открывается следующий раунд из пула. Пул
/// исчерпан — «приходи завтра за новыми» (ротация по дате).
class TasksTab extends StatelessWidget {
  const TasksTab({super.key});

  @override
  Widget build(BuildContext context) {
    final taskService = context.watch<TaskService>();

    final available = taskService.availableTasks;
    final completed = taskService.completedTasks;

    void openQuiz(Task task) => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => QuizScreen(task: task),
          ),
        );

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Доступно: ${taskService.availableCount}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.inkSoft,
                ),
              ),
            ),
            if (taskService.streak > 0)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '🔥 ${taskService.streak}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F8A82),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        const _StreakBadgesRow(),
        const SizedBox(height: 14),
        if (available.isEmpty)
          const _EmptyTasks()
        else
          ...available.map(
            (t) => QuizTaskCard(
              task: t,
              isDone: false,
              onTap: () => openQuiz(t),
            ),
          ),
        if (completed.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Text(
            'Пройдено сегодня',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.inkSoft,
            ),
          ),
          const SizedBox(height: 14),
          ...completed.map(
            (t) => QuizTaskCard(task: t, isDone: true, onTap: () {}),
          ),
        ],
      ],
    );
  }
}

/// Ряд бейджей стрика: полученные — яркие, будущие — приглушённые.
class _StreakBadgesRow extends StatelessWidget {
  const _StreakBadgesRow();

  @override
  Widget build(BuildContext context) {
    final maxStreak = context.watch<TaskService>().maxStreak;
    return Row(
      children: [
        for (var i = 0; i < StreakBadge.all.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: _BadgeChip(
              badge: StreakBadge.all[i],
              earned: StreakBadge.all[i].isEarned(maxStreak),
            ),
          ),
        ],
      ],
    );
  }
}

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({required this.badge, required this.earned});

  final StreakBadge badge;
  final bool earned;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: earned
            ? AppColors.accent.withValues(alpha: 0.25)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: earned
              ? AppColors.accent.withValues(alpha: 0.8)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        children: [
          Text(
            badge.emoji,
            style: TextStyle(
              fontSize: 20,
              color:
                  earned ? null : Colors.black.withValues(alpha: 0.2),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            earned ? badge.name : '${badge.days} дн.',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: earned
                  ? const Color(0xFF8A6D00)
                  : AppColors.inkSoft.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

/// Пустое состояние, если все задания на сегодня пройдены.
class _EmptyTasks extends StatelessWidget {
  const _EmptyTasks();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🎊', style: TextStyle(fontSize: 48)),
            SizedBox(height: 12),
            Text(
              'Все задания на сегодня пройдены!\nВозвращайся завтра за новыми.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.4,
                fontWeight: FontWeight.w700,
                color: AppColors.inkSoft,
              ),
            ),
          ],
        ),
      );
}

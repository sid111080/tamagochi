import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../core/models/budget.dart';
import '../../core/models/piggy_bank_goal.dart';
import '../../core/models/task.dart';
import '../../core/models/wallet.dart';
import '../../core/services/period_service.dart';
import '../../core/services/piggy_bank_service.dart';
import '../../core/services/task_service.dart';
import '../../core/services/wallet_service.dart';
import '../../data/content/glossary.dart';

/// Вкладка «История и прогресс» (ТЗ §8.11):
/// итоги последнего периода, прогресс по темам, цели копилки,
/// завершённые задания, история операций и словарь терминов.
class HistoryTab extends StatelessWidget {
  const HistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    final period = context.watch<PeriodService>();
    final tasks = context.watch<TaskService>();
    final piggy = context.watch<PiggyBankService>();
    final wallet = context.watch<WalletService>();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _PeriodResultCard(result: period.lastResult, stage: period.stage),
        const SizedBox(height: 16),
        _TopicProgressCard(tasks: tasks),
        const SizedBox(height: 16),
        _GoalProgressCard(goals: piggy.goals, totalSaved: piggy.totalSaved),
        const SizedBox(height: 16),
        _CompletedTasksCard(tasks: tasks),
        const SizedBox(height: 16),
        _TransactionsCard(transactions: wallet.transactions),
        const SizedBox(height: 16),
        const _GlossaryCard(),
      ],
    );
  }
}

/// Карточка-контейнер с заголовком и тенью.
class _Card extends StatelessWidget {
  const _Card({required this.title, required this.emoji, required this.child});

  final String title;
  final String emoji;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

/// Пустая подсказка внутри карточки.
class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.emoji, required this.text});

  final String emoji;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 32)),
        const SizedBox(height: 8),
        Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13.5,
            height: 1.4,
            color: AppColors.inkSoft,
          ),
        ),
      ],
    );
  }
}

/// Итог последнего периода: score, три критерия, объяснение, стадия.
class _PeriodResultCard extends StatelessWidget {
  const _PeriodResultCard({required this.result, required this.stage});

  final PeriodResult? result;
  final FinancialStage stage;

  static const Color _good = Color(0xFF3E8E4E);

  @override
  Widget build(BuildContext context) {
    if (result == null) {
      return _Card(
        title: 'Итог периода',
        emoji: '🏁',
        child: const _EmptyHint(
          emoji: '📝',
          text: 'Заверши период на вкладке «Бюджет» —\nитог появится здесь.',
        ),
      );
    }
    return _Card(
      title: 'Итог периода ${result!.periodIndex}',
      emoji: '🏁',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${result!.score} из 3',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF8A6D00),
                  ),
                ),
              ),
              const Spacer(),
              Text(stage.emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 4),
              Text(
                stage.label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.inkSoft,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _criterion(result!.requiredCovered, 'Обязательные — покрыты'),
          const SizedBox(height: 6),
          _criterion(result!.optionalWithinPlan, 'Необязательные — по плану'),
          const SizedBox(height: 6),
          _criterion(result!.savingsConsistent, 'Копилку — пополнил(а)'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.bgDeep,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              result!.explanation,
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.45,
                color: AppColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _criterion(bool met, String label) {
    return Row(
      children: [
        Icon(
          met ? Icons.check_circle_rounded : Icons.remove_circle_outline,
          size: 20,
          color: met ? _good : AppColors.primaryDark,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: met ? AppColors.ink : AppColors.inkSoft,
          ),
        ),
      ],
    );
  }
}

/// Прогресс по трём темам + стрик.
class _TopicProgressCard extends StatelessWidget {
  const _TopicProgressCard({required this.tasks});

  final TaskService tasks;

  static const Color _good = Color(0xFF3E8E4E);

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];

    if (tasks.streak > 0) {
      children.add(
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.secondary.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '🔥 Стрик: ${tasks.streak} дн.',
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1F8A82),
            ),
          ),
        ),
      );
    }

    for (var i = 0; i < TaskTopic.values.length; i++) {
      final topic = TaskTopic.values[i];
      final (done, all) = tasks.topicProgress[topic] ?? (0, 0);
      final complete = all > 0 && done >= all;
      children.add(
        Row(
          children: [
            Text(topic.badge, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                topic.label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ),
            Text(
              '$done / $all',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: complete ? _good : AppColors.inkSoft,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              complete
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked,
              size: 18,
              color: complete
                  ? _good
                  : AppColors.inkSoft.withValues(alpha: 0.5),
            ),
          ],
        ),
      );
      children.add(const SizedBox(height: 6));
      children.add(
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: all == 0 ? 0.0 : (done / all).clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: AppColors.bgDeep,
            color: complete ? _good : AppColors.leaf,
          ),
        ),
      );
      if (i < TaskTopic.values.length - 1) {
        children.add(const SizedBox(height: 14));
      }
    }

    return _Card(title: 'Мои умения', emoji: '📚', child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    ));
  }
}

/// Прогресс по целям копилки.
class _GoalProgressCard extends StatelessWidget {
  const _GoalProgressCard({required this.goals, required this.totalSaved});

  final List<PiggyBankGoal> goals;
  final int totalSaved;

  static const Color _good = Color(0xFF3E8E4E);

  @override
  Widget build(BuildContext context) {
    if (goals.isEmpty) {
      return _Card(
        title: 'Цели копилки',
        emoji: '🏦',
        child: const _EmptyHint(
          emoji: '🎯',
          text: 'Создай цель на вкладке «Кошелёк» —\nпрогресс появится здесь.',
        ),
      );
    }

    final children = <Widget>[
      Text(
        'Всего в копилке: $totalSaved монеток',
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: _good,
        ),
      ),
      const SizedBox(height: 12),
    ];
    for (var i = 0; i < goals.length; i++) {
      final g = goals[i];
      final reached = g.isReached;
      children.add(
        Row(
          children: [
            Text(g.emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                g.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
            ),
            Text(
              reached ? '✓ Достигнуто' : '${g.saved} / ${g.target}',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: reached ? _good : AppColors.inkSoft,
              ),
            ),
          ],
        ),
      );
      children.add(const SizedBox(height: 6));
      children.add(
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: g.progress,
            minHeight: 8,
            backgroundColor: AppColors.bgDeep,
            color: reached ? _good : AppColors.leaf,
          ),
        ),
      );
      if (i < goals.length - 1) children.add(const SizedBox(height: 10));
    }

    return _Card(
        title: 'Цели копилки', emoji: '🏦',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ));
  }
}

/// Недавно завершённые задания (с датами).
class _CompletedTasksCard extends StatelessWidget {
  const _CompletedTasksCard({required this.tasks});

  final TaskService tasks;

  @override
  Widget build(BuildContext context) {
    final history = tasks.completedHistory;
    if (history.isEmpty) {
      return _Card(
        title: 'Пройденные задания',
        emoji: '✅',
        child: const _EmptyHint(
          emoji: '📝',
          text: 'Ещё нет пройденных заданий.\nСделай первое на вкладке «Задания»!',
        ),
      );
    }

    // Показываем максимум 5 последних.
    final limit = history.length > 5 ? 5 : history.length;
    final children = <Widget>[];
    for (var i = 0; i < limit; i++) {
      final (task, date) = history[i];
      children.add(
        Row(
          children: [
            Text(task.topic.badge, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                task.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ),
            Text(
              _formatDate(date),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.inkSoft,
              ),
            ),
          ],
        ),
      );
      if (i < limit - 1) children.add(const SizedBox(height: 10));
    }
    if (history.length > 5) {
      children.add(const SizedBox(height: 8));
      children.add(
        Text(
          '…и ещё ${history.length - 5}',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.inkSoft.withValues(alpha: 0.7),
          ),
        ),
      );
    }

    return _Card(
        title: 'Пройденные задания', emoji: '✅',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ));
  }
}

/// История операций с монетками (последние 8).
class _TransactionsCard extends StatelessWidget {
  const _TransactionsCard({required this.transactions});

  final List<CoinTransaction> transactions;

  static const Color _good = Color(0xFF3E8E4E);

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return _Card(
        title: 'История монеток',
        emoji: '🪙',
        child: const _EmptyHint(
          emoji: '💸',
          text: 'Операции появятся здесь,\nкак только ты заработаешь или потратишь.',
        ),
      );
    }

    final limit = transactions.length > 8 ? 8 : transactions.length;
    final children = <Widget>[];
    for (var i = 0; i < limit; i++) {
      final tx = transactions[i];
      final isIncome = tx.amount > 0;
      final color = isIncome ? _good : AppColors.primaryDark;
      children.add(
        Row(
          children: [
            Text(tx.emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                tx.reason,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
            ),
            // Стрелка + знак — цвет не единственный сигнал (ТЗ §10).
            Text(
              isIncome ? '▲' : '▼',
              style: TextStyle(fontSize: 11, color: color),
            ),
            const SizedBox(width: 3),
            Text(
              '${isIncome ? '+' : ''}${tx.amount}',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: color),
            ),
            const SizedBox(width: 8),
            Text(
              _formatDate(tx.at),
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.inkSoft,
              ),
            ),
          ],
        ),
      );
      if (i < limit - 1) {
        children.add(const SizedBox(height: 8));
        children.add(const Divider(height: 1, color: Colors.black12));
        children.add(const SizedBox(height: 8));
      }
    }
    if (transactions.length > 8) {
      children.add(
        Text(
          '…и ещё ${transactions.length - 8} операций',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.inkSoft.withValues(alpha: 0.7),
          ),
        ),
      );
    }

    return _Card(
        title: 'История монеток', emoji: '🪙',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ));
  }
}

/// Справочник терминов (ТЗ §8.11: «короткий справочный раздел с терминами»).
class _GlossaryCard extends StatelessWidget {
  const _GlossaryCard();

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < glossary.length; i++) {
      final term = glossary[i];
      children.add(
        Padding(
          padding: EdgeInsets.only(
            bottom: i < glossary.length - 1 ? 12 : 0,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(term.emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      term.term,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      term.definition,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _Card(
        title: 'Словарик', emoji: '📖',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ));
  }
}

/// Короткая дата: «18 сен» (с годом, если не текущий).
String _formatDate(DateTime d) {
  const months = [
    'янв', 'фев', 'мар', 'апр', 'мая', 'июн',
    'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'
  ];
  final now = DateTime.now();
  final sameYear = d.year == now.year;
  return sameYear
      ? '${d.day} ${months[d.month - 1]}'
      : '${d.day} ${months[d.month - 1]} ${d.year}';
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../core/models/task.dart';
import '../../core/services/task_service.dart';

/// Экран прохождения задания-квиза: ситуация → выбор варианта →
/// обратная связь (объяснение + реакция питомца) + награда.
///
/// Обратная связь — после каждого ответа, независимо от правильности
/// (ТЗ §8.9): верный — питомец радуется и награда; неверный — питомец
/// грустит, объяснение, можно попробовать ещё («безопасная ошибка»).
class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key, required this.task});

  final Task task;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  String? _selectedOptionId;
  final Set<String> _triedWrong = {};
  QuizResult? _result;

  bool get _answered => _result != null;

  @override
  Widget build(BuildContext context) {
    final result = _result;
    final selectedId = _selectedOptionId;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          widget.task.title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Тема + сложность.
            Row(
              children: [
                _chip('${widget.task.topic.badge} ${widget.task.topic.label}',
                    AppColors.grape),
                const SizedBox(width: 8),
                _chip(
                    '${widget.task.difficulty.badge} ${widget.task.difficulty.label}',
                    AppColors.secondary),
              ],
            ),
            const SizedBox(height: 16),
            // Ситуация.
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
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
                  const Text(
                    'Ситуация',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.inkSoft,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.task.scenario,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.45,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Выбери вариант',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 12),
            ...widget.task.options.map(
              (option) => _OptionCard(
                option: option,
                revealed: _answered,
                selected: selectedId == option.id,
                disabled: _triedWrong.contains(option.id),
                onTap: () => _select(option.id),
              ),
            ),
            const SizedBox(height: 8),
            if (result != null) ...[
              const SizedBox(height: 8),
              _FeedbackPanel(result: result),
              const SizedBox(height: 16),
              if (result.isCorrect)
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.leaf,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'К заданиям',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _retry,
                    child: const Text(
                      'Попробовать ещё',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  void _select(String optionId) {
    if (_answered) return;
    final service = context.read<TaskService>();
    final result = service.answer(widget.task.id, optionId);
    if (result == null) {
      // Задание уже выполнено или недоступно — возвращаемся.
      if (context.mounted) Navigator.of(context).pop();
      return;
    }
    setState(() {
      _selectedOptionId = optionId;
      _result = result;
      if (!result.isCorrect) _triedWrong.add(optionId);
    });
  }

  void _retry() {
    setState(() {
      _selectedOptionId = null;
      _result = null;
    });
  }

  Widget _chip(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style:
              TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color),
        ),
      );
}

/// Вариант ответа. В режиме раскрытия подсвечивает верный и выбранный.
class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.option,
    required this.revealed,
    required this.selected,
    required this.disabled,
    required this.onTap,
  });

  final TaskOption option;
  final bool revealed;
  final bool selected;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // После ответа: зелёная рамка у верного, приглушённый у ошибочного.
    final isCorrectRevealed = revealed && option.isCorrect;
    final isWrongRevealed = revealed && selected && !option.isCorrect;

    Color borderColor = AppColors.primary;
    Color bgColor = Colors.white;
    if (revealed) {
      if (isCorrectRevealed) {
        borderColor = AppColors.leaf;
        bgColor = AppColors.leaf.withValues(alpha: 0.1);
      } else if (isWrongRevealed) {
        borderColor = AppColors.inkSoft.withValues(alpha: 0.5);
        bgColor = AppColors.bg;
      } else {
        borderColor = Colors.black.withValues(alpha: 0.08);
        bgColor = AppColors.bg;
      }
    } else if (disabled) {
      borderColor = Colors.black.withValues(alpha: 0.08);
      bgColor = AppColors.bg;
    }

    return GestureDetector(
      onTap: (revealed || disabled) ? null : onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (revealed && isCorrectRevealed)
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Text('✓',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF3E8E4E))),
              )
            else if (isWrongRevealed)
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Text('·',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.inkSoft)),
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: 2, left: 16),
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: revealed
                        ? Colors.transparent
                        : AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color:
                            AppColors.primary.withValues(alpha: 0.5),
                        width: 2),
                  ),
                ),
              ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                option.text,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.4,
                  fontWeight: FontWeight.w700,
                  color: (revealed || disabled)
                      ? AppColors.inkSoft
                      : AppColors.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Панель обратной связи: реакция питомца + объяснение (+ награда).
class _FeedbackPanel extends StatelessWidget {
  const _FeedbackPanel({required this.result});

  final QuizResult result;

  @override
  Widget build(BuildContext context) {
    final ok = result.isCorrect;
    final color = ok ? AppColors.leaf : AppColors.inkSoft;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: ok ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: ok ? 0.5 : 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                result.option.consequencePet.emoji,
                style: const TextStyle(fontSize: 28),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  ok ? 'Молодец!' : 'Попробуй ещё',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: ok ? const Color(0xFF2E7D46) : AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            result.option.explanation,
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
              color: AppColors.ink,
            ),
          ),
          if (ok && result.reward > 0)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.coin.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Награда: 🪙 +${result.reward} фиников',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFB8860B),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

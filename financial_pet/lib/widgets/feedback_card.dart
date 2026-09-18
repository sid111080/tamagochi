import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../core/models/feedback_event.dart';
import '../core/models/pet.dart';

/// Плавающая карточка обратной связи на главном экране (ТЗ §8.9).
///
/// Показывает: что изменилось (баланс / копилка / питомец), короткое
/// объяснение «почему», следующий шаг и — при неудачном выборе — способ
/// исправить. Цвет тона дублируется словом и эмодзи (ТЗ §10: цвет — не
/// единственный сигнал). Не блокирует экран: автоматически скрывается
/// через несколько секунд, есть кнопка «Понятно».
class FeedbackCard extends StatelessWidget {
  const FeedbackCard({
    super.key,
    required this.event,
    required this.onDismiss,
  });

  final FeedbackEvent event;
  final VoidCallback onDismiss;

  Color get _accent => switch (event.tone) {
        FeedbackTone.success => AppColors.leaf,
        FeedbackTone.info => AppColors.sky,
        FeedbackTone.caution => AppColors.coin,
        FeedbackTone.celebration => AppColors.grape,
      };

  @override
  Widget build(BuildContext context) {
    final accent = _accent;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 6,
      shadowColor: Colors.black.withValues(alpha: 0.18),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent.withValues(alpha: 0.7), width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок: эмодзи + название + слово-сигнал тона + «Понятно».
            Row(
              children: [
                Text(event.emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    event.tone.word,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: accent,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // Кнопка «Понятно» — цель не меньше 48×48 (ТЗ §10).
                InkWell(
                  onTap: onDismiss,
                  borderRadius: BorderRadius.circular(12),
                  child: const Padding(
                    padding: EdgeInsets.all(12),
                    child: Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Объяснение: что изменилось и почему.
            Text(
              event.message,
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
                color: AppColors.ink,
              ),
            ),
            // Питомец: настроение + имя + изменение показателя.
            if (event.petMood != null || event.petStatus != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  if (event.petMood != null) ...[
                    Text(event.petMood!.emoji,
                        style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 6),
                  ],
                  if (event.petName != null)
                    Text(
                      event.petName!,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                  if (event.petName != null && event.petStatus != null)
                    const SizedBox(width: 8),
                  if (event.petStatus != null)
                    Expanded(
                      child: Text(
                        event.petStatus!,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.inkSoft,
                        ),
                      ),
                    ),
                ],
              ),
            ],
            // Чипы изменений: баланс и копилка.
            if (event.balance != null || event.savings != null) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (event.balance != null)
                    _chip(_accent, '🪙 ${event.balance!}'),
                  if (event.savings != null)
                    _chip(_accent, '🏦 ${event.savings!}'),
                ],
              ),
            ],
            // Как исправить неудачный выбор (без страха и стыда).
            if (event.recovery != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('🛠', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        event.recovery!,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // Следующий шаг.
            if (event.nextStep != null) ...[
              const SizedBox(height: 10),
              Text(
                '→ ${event.nextStep!}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.inkSoft,
                ),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: onDismiss,
                child: const Text(
                  'Понятно',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Маленький чип с изменением («−15 монеток», «+20 в копилку»).
Widget _chip(Color accent, String text) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: accent.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: accent,
      ),
    ),
  );
}

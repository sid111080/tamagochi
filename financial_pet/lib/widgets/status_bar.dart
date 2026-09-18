import 'package:flutter/material.dart';
import '../app/theme.dart';

/// Одна полоса статуса питомца (сытость, веселье, чистота).
class PetStatusBar extends StatelessWidget {
  const PetStatusBar({
    super.key,
    required this.label,
    required this.emoji,
    required this.value,
    required this.color,
    this.barHeight = 12,
  });

  final String label;
  final String emoji;
  final double value; // 0..100
  final Color color;

  /// Высота полосы: на главном экране — поменьше, чтобы всё влезло.
  final double barHeight;

  @override
  Widget build(BuildContext context) {
    final isLow = value < 35;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ),
            Text(
              '${value.round()}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: isLow ? AppColors.primaryDark : color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: (value / 100).clamp(0, 1),
            minHeight: barHeight,
            backgroundColor: color.withValues(alpha: 0.18),
            valueColor: AlwaysStoppedAnimation(
                isLow ? AppColors.primary : color),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ],
    );
  }
}

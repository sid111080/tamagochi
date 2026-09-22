import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Вариант отображения метрики состояния питомца в HUD.
enum HudMetricVariant { bar, ring, segments }

extension HudMetricVariantX on HudMetricVariant {
  /// Короткая подпись для переключателя.
  String get label => switch (this) {
    HudMetricVariant.bar => 'шкала',
    HudMetricVariant.ring => 'кольцо',
    HudMetricVariant.segments => 'ячейки',
  };
}

/// Тёплая «приборная» рамка: белый фон, 2px цветная кромка, мягкая тень.
BoxDecoration _panelDecoration(Color color) => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(14),
  border: Border.all(color: color.withValues(alpha: 0.55), width: 2),
  boxShadow: [
    BoxShadow(
      color: AppColors.ink.withValues(alpha: 0.05),
      blurRadius: 8,
      offset: const Offset(0, 3),
    ),
  ],
);

/// Крупная цифра «прибора»: табличные фигуры, чтобы цифры не прыгали.
TextStyle _bigNumber(Color color) => const TextStyle(
  fontSize: 22,
  fontWeight: FontWeight.w900,
  fontFeatures: [FontFeature.tabularFigures()],
).copyWith(color: color);

/// Низкое значение (<35) — цифра краснеет и появляется ⚠️:
/// предупреждение не передаётся одним только цветом (ТЗ §10).
bool _isLow(double value) => value < 35;

/// Вариант A «шкала»: эмодзи + подпись + крупная цифра, снизу горизонтальная
/// полоса. Компактный, как панель приборов.
class HudBarCard extends StatelessWidget {
  const HudBarCard({
    super.key,
    required this.emoji,
    required this.label,
    required this.value,
    required this.color,
  });

  final String emoji;
  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0, 100).toDouble();
    final low = _isLow(v);
    final fillColor = low ? AppColors.primary : color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: _panelDecoration(color),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (low) ...[
                const SizedBox(width: 4),
                const Text('⚠️', style: TextStyle(fontSize: 13)),
              ],
              Text('${v.round()}', style: _bigNumber(fillColor)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 12,
              child: ColoredBox(
                color: color.withValues(alpha: 0.15),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: (v / 100).clamp(0, 1).toDouble(),
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: fillColor),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Вариант B «кольцо»: круговой индикатор с цифрой в центре,
/// подпись снизу. Самый «приборный» из трёх.
class HudRingCard extends StatelessWidget {
  const HudRingCard({
    super.key,
    required this.emoji,
    required this.label,
    required this.value,
    required this.color,
  });

  final String emoji;
  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0, 100).toDouble();
    final low = _isLow(v);
    final fillColor = low ? AppColors.primary : color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: _panelDecoration(color),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: CustomPaint(
              painter: _RingPainter(
                fraction: (v / 100).clamp(0, 1).toDouble(),
                color: fillColor,
                trackColor: color.withValues(alpha: 0.15),
              ),
              child: Center(
                child: Text(
                  '${v.round()}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ).copyWith(color: fillColor),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (low) ...[
                const SizedBox(width: 3),
                const Text('⚠️', style: TextStyle(fontSize: 12)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Вариант C «ячейки»: крупная цифра сверху, снизу — 10 сегментов
/// (как шкала топлива). Самый наглядный для детей.
class HudSegmentCard extends StatelessWidget {
  const HudSegmentCard({
    super.key,
    required this.emoji,
    required this.label,
    required this.value,
    required this.color,
  });

  final String emoji;
  final String label;
  final double value;
  final Color color;

  static const int _segments = 10;

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0, 100).toDouble();
    final low = _isLow(v);
    final fillColor = low ? AppColors.primary : color;
    final filled = (v / 100 * _segments).round().clamp(0, _segments);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: _panelDecoration(color),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 5),
              Text('${v.round()}', style: _bigNumber(fillColor)),
              const Spacer(),
              if (low) const Text('⚠️', style: TextStyle(fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var i = 0; i < _segments; i++) ...[
                if (i > 0) const SizedBox(width: 3),
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    height: 12,
                    decoration: BoxDecoration(
                      color: i < filled
                          ? fillColor
                          : color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Круговой индикатор: дорожка + дуга с закруглёнными концами.
class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.fraction,
    required this.color,
    required this.trackColor,
  });

  final double fraction;
  final Color color;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 5;

    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);

    if (fraction > 0) {
      final fill = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * fraction,
        false,
        fill,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.fraction != fraction ||
      oldDelegate.color != color ||
      oldDelegate.trackColor != trackColor;
}

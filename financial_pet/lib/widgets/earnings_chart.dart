import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/wallet.dart';
import '../theme/app_theme.dart';

/// Подписи дней недели: понедельник — воскресенье.
const List<String> _weekdayLabels = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

/// Столбчатый график: заработок монетками за последние [days] дней.
class EarningsChart extends StatelessWidget {
  const EarningsChart({super.key, required this.incomes, this.days = 7});

  /// Заработанные монетки (только доходы) по датопериодам уже посчитанные
  /// снаружи: список сумм от старых дней к новым.
  final List<double> incomes;

  /// Сколько последних дней показываем.
  final int days;

  @override
  Widget build(BuildContext context) {
    final data = incomes.length <= days
        ? [...incomes]
        : [...incomes.sublist(incomes.length - days)];
    while (data.length < days) {
      data.insert(0, 0);
    }
    final max = data.fold<double>(1, (m, v) => math.max(m, v));
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return SizedBox(
      height: 150,
      child: BarChart(
        BarChartData(
          maxY: max,
          barTouchData: BarTouchData(enabled: false),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            leftTitles: const AxisTitles(),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= days) return const SizedBox.shrink();
                  final d = today.subtract(Duration(days: days - 1 - i));
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      _weekdayLabels[d.weekday - 1],
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < days; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: data[i] > 0 ? data[i] : 0.4,
                    width: 14,
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(7)),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        AppColors.coin.withValues(alpha: 0.55),
                        AppColors.coin,
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
        duration: const Duration(milliseconds: 300),
      ),
    );
  }
}

/// Считает дневной заработок из операций кошелька.
/// Возвращает список сумм за [days] дней, от старых к новым.
List<double> dailyIncomes(
    List<CoinTransaction> transactions, DateTime now,
    {int days = 7}) {
  final result = List<double>.filled(days, 0);
  for (final tx in transactions) {
    if (tx.amount <= 0) continue;
    final today = DateTime(now.year, now.month, now.day);
    final txDay = DateTime(tx.at.year, tx.at.month, tx.at.day);
    final diff = today.difference(txDay).inDays;
    if (diff >= 0 && diff < days) {
      result[days - 1 - diff] += tx.amount;
    }
  }
  return result;
}

/// Пустой график (нет доходов) — дружелюбная заглушка.
class EmptyChartHint extends StatelessWidget {
  const EmptyChartHint({super.key});

  @override
  Widget build(BuildContext context) => Center(
        child: Text(
          'Сделай первое задание — и здесь появится график 📈',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            height: 1.4,
            color: AppColors.inkSoft,
          ),
        ),
      );
}

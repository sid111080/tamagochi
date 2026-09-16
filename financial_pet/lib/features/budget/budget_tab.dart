import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../core/models/budget.dart';
import '../../core/models/pet.dart';
import '../../core/services/pet_service.dart';
import '../../core/services/period_service.dart';

/// Вкладка «Бюджет»: план на период → период → сравнение план/факт.
///
/// Три фазы игрового периода (ТЗ §8.5):
///   1. [PeriodPhase.planning] — распределить монетки по 3 направлениям.
///   2. [PeriodPhase.active]   — план зафиксирован, тратим, виден факт.
///   3. [PeriodPhase.finished] — сравнение плана с фактом и влияние на питомца.
class BudgetTab extends StatefulWidget {
  const BudgetTab({super.key});

  @override
  State<BudgetTab> createState() => _BudgetTabState();
}

class _BudgetTabState extends State<BudgetTab> {
  /// Значения планирования (редактируются локально до подтверждения).
  int _plannedRequired = 0;
  int _plannedOptional = 0;
  int _plannedSavings = 0;

  /// Индекс периода, к которому привязаны локальные значения планирования.
  int _boundPeriodIndex = -1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resyncIfNeeded();
  }

  /// Если открыт новый период — сбросить локальные значения планирования
  /// (чтобы слайдеры не тянули за собой старый период).
  void _resyncIfNeeded() {
    final period = context.read<PeriodService>().period;
    if (period.index != _boundPeriodIndex) {
      _boundPeriodIndex = period.index;
      _plannedRequired = period.plan.required;
      _plannedOptional = period.plan.optional;
      _plannedSavings = period.plan.savings;
    }
  }

  @override
  Widget build(BuildContext context) {
    final periodService = context.watch<PeriodService>();
    final pet = context.watch<PetService>().pet;

    // Сбрасываем локальные значения при смене периода.
    _resyncIfNeeded();

    final period = periodService.period;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Шапка периода.
        _PeriodHeader(
          index: period.index,
          phase: period.phase,
          stage: periodService.stage,
        ),
        const SizedBox(height: 16),
        switch (period.phase) {
          PeriodPhase.planning => _PlanningView(
                budget: periodService.availableBudget,
                requiredAmount: _plannedRequired,
                optionalAmount: _plannedOptional,
                savingsAmount: _plannedSavings,
                onChanged: (required, optional, savings) {
                  setState(() {
                    _plannedRequired = required;
                    _plannedOptional = optional;
                    _plannedSavings = savings;
                  });
                },
                onConfirm: () => periodService.confirmPlan(
                  required: _plannedRequired,
                  optional: _plannedOptional,
                  savings: _plannedSavings,
                ),
              ),
          PeriodPhase.active => _ActiveView(period: period),
          PeriodPhase.finished => _FinishedView(
                period: period,
                lastResult: periodService.lastResult,
                stage: periodService.stage,
                onContinue: periodService.nextPeriod,
              ),
        },
        if (pet != null) ...[
          const SizedBox(height: 16),
          _PetReactionCard(
            pet: pet,
            lastResult: periodService.lastResult,
          ),
        ],
      ],
    );
  }
}

/// Шапка периода: номер, текущая фаза и стадия финансовой ответственности.
class _PeriodHeader extends StatelessWidget {
  const _PeriodHeader({
    required this.index,
    required this.phase,
    required this.stage,
  });

  final int index;
  final PeriodPhase phase;
  final FinancialStage stage;

  String get _phaseLabel => switch (phase) {
        PeriodPhase.planning => 'Составь план',
        PeriodPhase.active => 'Период идёт',
        PeriodPhase.finished => 'Итог',
      };

  String get _phaseEmoji => switch (phase) {
        PeriodPhase.planning => '📝',
        PeriodPhase.active => '⏳',
        PeriodPhase.finished => '✅',
      };

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
      child: Row(
        children: [
          Text(_phaseEmoji, style: const TextStyle(fontSize: 30)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Период $index',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _phaseLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.inkSoft,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(stage.emoji, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text(
                  stage.label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF8A6D00),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Фаза планирования: три слайдера по направлениям + остаток + подтверждение.
class _PlanningView extends StatelessWidget {
  const _PlanningView({
    required this.budget,
    required this.requiredAmount,
    required this.optionalAmount,
    required this.savingsAmount,
    required this.onChanged,
    required this.onConfirm,
  });

  final int budget;
  final int requiredAmount;
  final int optionalAmount;
  final int savingsAmount;

  /// Новый набор значений (required, optional, savings).
  final void Function(int, int, int) onChanged;
  final VoidCallback onConfirm;

  int get _planned => requiredAmount + optionalAmount + savingsAmount;
  int get _remainder => budget - _planned;
  bool get _overBudget => _planned > budget;

  Color _colorFor(BudgetDirection direction) => switch (direction) {
        BudgetDirection.required => AppColors.leaf,
        BudgetDirection.optional => AppColors.grape,
        BudgetDirection.savings => AppColors.sky,
      };

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
          Text(
            '📝 Распредели монетки',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Доступно: $budget монеток. Как потратишь — решишь сам(а).',
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.4,
              color: AppColors.inkSoft,
            ),
          ),
          const SizedBox(height: 16),
          _planner(
            BudgetDirection.required,
            value: requiredAmount,
            onChanged: (v) =>
                onChanged(v.round(), optionalAmount, savingsAmount),
          ),
          _planner(
            BudgetDirection.optional,
            value: optionalAmount,
            onChanged: (v) =>
                onChanged(requiredAmount, v.round(), savingsAmount),
          ),
          _planner(
            BudgetDirection.savings,
            value: savingsAmount,
            onChanged: (v) =>
                onChanged(requiredAmount, optionalAmount, v.round()),
          ),
          const SizedBox(height: 12),
          // Остаток: в плане / свободные монетки.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'В плане: $_planned',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              Text(
                _overBudget ? 'Много! Не хватает' : 'Остаток: $_remainder',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: _overBudget ? AppColors.primaryDark : AppColors.leaf,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed:
                  !_overBudget && budget > 0 ? onConfirm : null,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Начать период'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _planner(
    BudgetDirection direction, {
    required int value,
    required ValueChanged<double> onChanged,
  }) {
    final color = _colorFor(direction);
    final max = mathMax(budget, 5).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(direction.emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                direction.shortLabel,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ),
            Text(
              '$value',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ],
        ),
        Slider(
          value: value.clamp(0, max).toDouble(),
          min: 0,
          max: max,
          divisions: mathMax(max.toInt() ~/ 5, 1),
          activeColor: color,
          inactiveColor: color.withValues(alpha: 0.2),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

/// Фаза «период идёт»: план (зафиксирован) + текущий факт.
class _ActiveView extends StatelessWidget {
  const _ActiveView({required this.period});

  final Period period;

  Color _colorFor(BudgetDirection direction) => switch (direction) {
        BudgetDirection.required => AppColors.leaf,
        BudgetDirection.optional => AppColors.grape,
        BudgetDirection.savings => AppColors.sky,
      };

  @override
  Widget build(BuildContext context) {
    final periodService = context.read<PeriodService>();
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
              const Text('⏳ Период идёт',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  )),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '🪙 ${periodService.availableBudget}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F8A82),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Заботься о питомце и копилке. Факт считает сам.',
            style: TextStyle(
              fontSize: 12.5,
              height: 1.4,
              color: AppColors.inkSoft,
            ),
          ),
          const SizedBox(height: 14),
          for (final d in BudgetDirection.values) ...[
            _ComparisonRow(
              direction: d,
              color: _colorFor(d),
              plan: period.plan.amountFor(d),
              fact: period.fact.amountFor(d),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Потрачено: ${period.fact.total}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              Text(
                'План: ${period.plan.total}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.inkSoft,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => periodService.finishPeriod(),
              icon: const Icon(Icons.flag_rounded),
              label: const Text('Завершить период'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Строка «план → факт» по одному направлению.
class _ComparisonRow extends StatelessWidget {
  const _ComparisonRow({
    required this.direction,
    required this.color,
    required this.plan,
    required this.fact,
  });

  final BudgetDirection direction;
  final Color color;
  final int plan;
  final int fact;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(direction.emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            direction.shortLabel,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ),
        Text(
          'план $plan',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: color.withValues(alpha: 0.85),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'факт $fact',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w900,
            color: fact > plan
                ? AppColors.primaryDark
                : const Color(0xFF3E8E4E),
          ),
        ),
      ],
    );
  }
}

/// Фаза «итог»: сравнение плана с фактом, критерии, влияние, кнопка дальше.
class _FinishedView extends StatelessWidget {
  const _FinishedView({
    required this.period,
    required this.lastResult,
    required this.stage,
    required this.onContinue,
  });

  final Period period;
  final PeriodResult? lastResult;
  final FinancialStage stage;
  final VoidCallback onContinue;

  Color _colorFor(BudgetDirection direction) => switch (direction) {
        BudgetDirection.required => AppColors.leaf,
        BudgetDirection.optional => AppColors.grape,
        BudgetDirection.savings => AppColors.sky,
      };

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
          Text(
            '✅ Итог периода ${period.index}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 14),
          for (final d in BudgetDirection.values) ...[
            _ComparisonRow(
              direction: d,
              color: _colorFor(d),
              plan: period.plan.amountFor(d),
              fact: period.fact.amountFor(d),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 8),
          // Три критерия развития (ТЗ §8.10) — галочками, не только цветом.
          if (lastResult != null) ...[
            const Divider(height: 18),
            _CriterionRow(
              met: lastResult!.requiredCovered,
              label: 'Обязательные — покрыты',
            ),
            const SizedBox(height: 6),
            _CriterionRow(
              met: lastResult!.optionalWithinPlan,
              label: 'Необязательные — по плану',
            ),
            const SizedBox(height: 6),
            _CriterionRow(
              met: lastResult!.savingsConsistent,
              label: 'Копилку — пополнил(а)',
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.bgDeep,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                lastResult!.explanation,
                style: const TextStyle(
                  fontSize: 13.5,
                  height: 1.45,
                  color: AppColors.ink,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onContinue,
              icon: const Icon(Icons.skip_next_rounded),
              label: const Text('Следующий период'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Строка критерия: галочка/крестик + подпись (цвет не единственный сигнал).
class _CriterionRow extends StatelessWidget {
  const _CriterionRow({required this.met, required this.label});

  final bool met;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          met ? Icons.check_circle_rounded : Icons.remove_circle_outline,
          size: 20,
          color: met ? const Color(0xFF3E8E4E) : AppColors.primaryDark,
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

/// Карточка с эмоциональным состоянием питомца после периода.
class _PetReactionCard extends StatelessWidget {
  const _PetReactionCard({required this.pet, required this.lastResult});

  final Pet pet;
  final PeriodResult? lastResult;

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
              Text(
                pet.mood.emoji,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${pet.name}: ${pet.mood.label}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
          if (lastResult != null) ...[
            const SizedBox(height: 10),
            Text(
              lastResult!.explanation,
              style: const TextStyle(
                fontSize: 13,
                height: 1.4,
                color: AppColors.inkSoft,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Математический максимум — без лишний import dart:math на верхнем уровне.
int mathMax(int a, int b) => a > b ? a : b;

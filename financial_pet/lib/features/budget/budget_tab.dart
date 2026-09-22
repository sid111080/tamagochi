import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../core/models/budget.dart';
import '../../core/models/feedback_event.dart';
import '../../core/models/pet.dart';
import '../../core/services/feedback_service.dart';
import '../../core/services/pet_service.dart';
import '../../core/services/period_service.dart';

/// Вкладка «Бюджет»: план на период → период → сравнение план/факт.
///
/// Три фазы игрового периода (ТЗ §8.5):
///   1. [PeriodPhase.planning] — распределить монетки по 3 направлениям.
///   2. [PeriodPhase.active]   — план зафиксирован, тратим, виден факт.
///   3. [PeriodPhase.finished] — сравнение плана с фактом и влияние на питомца.
class BudgetTab extends StatefulWidget {
  const BudgetTab({super.key, this.isActiveTab = true});

  /// Активна ли вкладка в IndexedStack (видна ли она ребёнку).
  ///
  /// Нужна, чтобы праздничный диалог сезона показывался только когда
  /// вкладка реально на экране, а не когда строится в offstage-слое.
  final bool isActiveTab;

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
          season: periodService.season,
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
                season: periodService.season,
                isActiveTab: widget.isActiveTab,
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
    required this.season,
  });

  final int index;
  final PeriodPhase phase;
  final FinancialStage stage;
  final int season;

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
                  '$_phaseLabel · сезон $season',
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
              onPressed: () {
                periodService.finishPeriod();
                // Новый период открыт: объясняем следующий шаг (ТЗ §8.9).
                final pet = context.read<PetService>().pet;
                context.read<FeedbackService>().post(
                  FeedbackEvent(
                    tone: FeedbackTone.info,
                    emoji: '🏁',
                    title: 'Период завершён',
                    message:
                        'Открылся новый период. План не составлен — '
                        'распредели монетки по трём направлениям.',
                    petMood: pet?.mood,
                    petName: pet?.name,
                    nextStep: 'Вкладка «Бюджет»: слайдеры плана.',
                  ),
                );
              },
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
///
/// StatefulWidget: при завершении 5-го периода (конец сезона) показывает
/// праздничный диалог с итогом сезона (ТЗ §8.10, полировка п.3) — один раз.
class _FinishedView extends StatefulWidget {
  const _FinishedView({
    required this.period,
    required this.lastResult,
    required this.stage,
    required this.season,
    required this.onContinue,
    this.isActiveTab = true,
  });

  final Period period;
  final PeriodResult? lastResult;
  final FinancialStage stage;

  /// Сезон, который только что завершён (это 5-й период).
  final int season;

  /// Видна ли вкладка «Бюджет» (актуально в IndexedStack). Диалог сезона
  /// показываем только когда вкладка на экране, а не в offstage-слое.
  final bool isActiveTab;
  final VoidCallback onContinue;

  @override
  State<_FinishedView> createState() => _FinishedViewState();
}

class _FinishedViewState extends State<_FinishedView> {
  // State переживает перестроения вью — поздравляем строго один раз.
  bool _seasonCelebrated = false;

  // Алиасы, чтобы тело build осталось прежним.
  Period get period => widget.period;
  PeriodResult? get lastResult => widget.lastResult;
  VoidCallback get onContinue => widget.onContinue;

  @override
  void initState() {
    super.initState();
    _maybeCelebrateSeason();
  }

  @override
  void didUpdateWidget(covariant _FinishedView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Вкладка стала активной (например, ребёнок переключился на неё после
    // перезапуска приложения) — показываем диалог, если ещё не показывали.
    if (!oldWidget.isActiveTab && widget.isActiveTab) {
      _maybeCelebrateSeason();
    }
  }

  /// Празднуем конец сезона ровно один раз — и только когда вкладка видна.
  void _maybeCelebrateSeason() {
    if (_seasonCelebrated || !widget.isActiveTab) return;
    if (widget.period.index != periodsPerSeason) return;
    _seasonCelebrated = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showSeasonCelebration();
    });
  }

  void _showSeasonCelebration() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _SeasonCelebrationDialog(
        season: widget.season,
        stage: widget.stage,
        onDone: () {
          Navigator.of(dialogContext).pop();
          widget.onContinue(); // Новый сезон: открываем период 1.
        },
      ),
    );
  }

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
          // 5-й период = конец сезона: кнопка и диалог используют один текст.
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onContinue,
              icon: period.index == periodsPerSeason
                  ? const Icon(Icons.emoji_events_rounded)
                  : const Icon(Icons.skip_next_rounded),
              label: Text(
                period.index == periodsPerSeason
                    ? 'К новому сезону!'
                    : 'Следующий период',
              ),
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

/// Праздничный диалог: сезон завершён (5 периодов).
///
/// Заметное поздравление (ТЗ §8.10, полировка п.3): трофей, номер сезона,
/// достигнутая стадия финансовой зрелости и побудительное слово. Только
/// позитив — без страха и стыда (ТЗ §6 «безопасная ошибка»).
class _SeasonCelebrationDialog extends StatelessWidget {
  const _SeasonCelebrationDialog({
    required this.season,
    required this.stage,
    required this.onDone,
  });

  final int season;
  final FinancialStage stage;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🏆', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 12),
            Text(
              'Сезон $season завершён!',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              '5 периодов — целая работа с деньгами.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, height: 1.4, color: AppColors.inkSoft),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.leaf.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  Text(stage.emoji, style: const TextStyle(fontSize: 40)),
                  const SizedBox(height: 6),
                  Text(
                    stage.label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Твоя стадия финансовой зрелости',
                    style: TextStyle(fontSize: 12, color: AppColors.inkSoft),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onDone,
                child: const Text(
                  'К новому сезону!',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Математический максимум — без лишний import dart:math на верхнем уровне.
int mathMax(int a, int b) => a > b ? a : b;

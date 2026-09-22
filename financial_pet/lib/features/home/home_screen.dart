import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/budget.dart';
import '../../core/models/feedback_event.dart';
import '../../core/models/pet.dart';
import '../../core/models/pet_species.dart';
import '../../core/models/piggy_bank_goal.dart';
import '../../core/services/demo_service.dart';
import '../../core/services/feedback_service.dart';
import '../../core/services/pet_service.dart';
import '../../core/services/period_service.dart';
import '../../core/services/piggy_bank_service.dart';
import '../../core/services/task_service.dart';
import '../../core/services/wallet_service.dart';
import '../../app/theme.dart';
import '../../features/adult/adult_section.dart';
import '../../features/budget/budget_tab.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/purchases/purchases_tab.dart';
import '../../features/progress/history_tab.dart';
import '../../features/tasks/tasks_tab.dart';
import '../pet_creation/create_pet_screen.dart';
import '../../widgets/action_button.dart';
import '../../widgets/coin_badge.dart';
import '../../widgets/earnings_chart.dart';
import '../../widgets/feedback_card.dart';
import 'hud_metric_cards.dart';

/// Главный экран: четыре таба — питомец, бюджет, задания, кошелёк.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletService>();
    final demo = context.watch<DemoService>();
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Row(
                children: [
                  const Text(
                    'ФинПитомец',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.ink,
                    ),
                  ),
                  const Spacer(),
                  if (demo.isDemo) ...[
                    _DemoChip(onTap: () => _openDemoDialog(context)),
                    const SizedBox(width: 8),
                  ],
                  CoinBadge(balance: wallet.balance),
                  const SizedBox(width: 8),
                  // Подсказка (ТЗ §8.1): вернуться к знакомству с игрой
                  // в любой момент. Открывается поверх Home → по завершении
                  // возвращаемся назад.
                  IconButton(
                    tooltip: 'Как играть?',
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const OnboardingScreen(fromHint: true),
                      ),
                    ),
                    icon: const Icon(
                      Icons.lightbulb_outline_rounded,
                      color: AppColors.inkSoft,
                    ),
                  ),
                  // Раздел для взрослого (ТЗ §8.12): деликатная иконка,
                  // раздел закрыт барьером (арифметический пример).
                  IconButton(
                    tooltip: 'Для взрослых',
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AdultSection()),
                    ),
                    icon: const Icon(
                      Icons.supervised_user_circle_rounded,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
            // Постоянная строка-сводка (ТЗ §8.3): копилка, текущая цель
            // и активное задание видны на всех табах. Сегменты кликабельны
            // (ведут в соответствующую вкладку), строка прокручивается
            // горизонтально — на узком экране ничего не обрезается.
            Consumer2<PiggyBankService, TaskService>(
              builder: (context, piggy, tasks, _) {
                final goal = piggy.goals.firstOrNull;
                final task = tasks.availableTasks.firstOrNull;
                // Компактные чипы (иконка + суть), чтобы влезть по ширине.
                final goalText = goal == null
                    ? '🎯 —'
                    : '${goal.emoji} ${goal.title}';
                final taskText = task == null ? '📝 ✓' : '📝 ${task.title}';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SizedBox(
                    height: 48,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        // Копилка и цель живут во вкладке «Кошелёк» (индекс 4).
                        _SummaryChip(
                          text: '🏦 ${piggy.totalSaved}',
                          onTap: () => _openTab(4),
                        ),
                        const SizedBox(width: 8),
                        _SummaryChip(text: goalText, onTap: () => _openTab(4)),
                        const SizedBox(width: 8),
                        // Активное задание — во вкладку «Задания» (индекс 3).
                        _SummaryChip(text: taskText, onTap: () => _openTab(3)),
                      ],
                    ),
                  ),
                );
              },
            ),
            // Карточка обратной связи (ТЗ §8.9): баннер между шапкой и
            // табами — обычный поток: не перекрывает контент и безопасно
            // для маленьких экранов. Автоскрывается через несколько секунд.
            Consumer<FeedbackService>(
              builder: (context, feedback, _) {
                final event = feedback.current;
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  reverseDuration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) => SizeTransition(
                    sizeFactor: animation,
                    alignment: const Alignment(0, 1),
                    child: FadeTransition(opacity: animation, child: child),
                  ),
                  child: event == null
                      ? const SizedBox.shrink()
                      : Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                          child: FeedbackCard(
                            key: ValueKey(event),
                            event: event,
                            onDismiss: feedback.dismiss,
                          ),
                        ),
                );
              },
            ),
            Expanded(
              child: IndexedStack(
                index: _tab,
                // Без const: BudgetTab получает динамический isActiveTab,
                // чтобы праздничный диалог сезона показывался только на
                // видимой вкладке, а не в offstage-слое IndexedStack.
                children: [
                  const _PetTab(),
                  BudgetTab(isActiveTab: _tab == 1),
                  const PurchasesTab(),
                  const TasksTab(),
                  const _WalletTab(),
                  const HistoryTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.pets_rounded),
            label: 'Питомец',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart_rounded),
            label: 'Бюджет',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag_rounded),
            label: 'Покупки',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.task_alt_rounded),
            label: 'Задания',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_rounded),
            label: 'Кошелёк',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_rounded),
            label: 'История',
          ),
        ],
      ),
    );
  }

  /// Переключить вкладку по номеру индекса (из строки-сводки, ТЗ §8.3).
  void _openTab(int index) {
    if (index == _tab) return;
    setState(() => _tab = index);
  }

  /// Диалог управления демо-режимом: заново пройти сценарий / выйти.
  void _openDemoDialog(BuildContext context) {
    final demo = context.read<DemoService>();
    final homeContext = context;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        contentPadding: const EdgeInsets.all(20),
        title: const Text(
          '🎬 Демо-режим',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
        content: const Text(
          'Тестовый профиль: этапы проходятся подряд, без ожидания '
          'реального времени. Задания — все сразу.',
          style: TextStyle(
            fontSize: 13.5,
            height: 1.4,
            color: AppColors.inkSoft,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              demo.resetDemo();
              // Профиль пересоздан — устаревшие карточки сбрасываем.
              context.read<FeedbackService>().clear();
              Navigator.of(dialogContext).pop();
            },
            child: const Text(
              'Начать заново',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.inkSoft,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              demo.exitDemo();
              context.read<FeedbackService>().clear();
              Navigator.of(dialogContext).pop();
              // Профиль очищен (питомец удалён) → на экран создания.
              if (homeContext.mounted) {
                Navigator.of(homeContext).pushReplacement(
                  MaterialPageRoute(builder: (_) => const CreatePetScreen()),
                );
              }
            },
            child: const Text(
              'Выйти',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

/// Плашка «демо-режим» в шапке: видна только в демо.
class _DemoChip extends StatelessWidget {
  const _DemoChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.accent, width: 1),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🎬', style: TextStyle(fontSize: 13)),
            SizedBox(width: 4),
            Text(
              'Демо',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFF8A6D00),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Кликабельный сегмент строки-сводки (ТЗ §8.3): ведёт в нужную вкладку.
class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      shadowColor: Colors.black.withValues(alpha: 0.08),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          // Высота ~48 dp — доступная зона тапа (ТЗ §10).
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

/// Таб «Питомец», HUD-раскладка: питомец в центре, «приборы» вокруг —
/// сверху уровень/XP/стадия, снизу метрики состояния и кнопки заботы.
class _PetTab extends StatefulWidget {
  const _PetTab();

  @override
  State<_PetTab> createState() => _PetTabState();
}

class _PetTabState extends State<_PetTab> {
  /// Вид метрик состояния (превью дизайна: переключается на экране).
  HudMetricVariant _metricVariant = HudMetricVariant.bar;

  @override
  Widget build(BuildContext context) {
    final petService = context.watch<PetService>();
    final wallet = context.watch<WalletService>();
    final periods = context.watch<PeriodService>();
    final pet = petService.pet;

    if (pet == null) return const _NoPet();

    final species = PetSpecies.byId(pet.speciesId);
    final emoji = species.emojiForIndex(pet.stage.index);
    // Размер — от уровня (плавный рост каждый уровень), а не от стадии.
    final scale = pet.sizeScale;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Фиксированные блоки: полоса, имя, переключатель, метрики, кнопки.
        // Остаток высоты уйдёт питомцу — он окажется в центре экрана.
        final fixed = _fixedHeight() + 12; // запас против overflow
        final avatarBox =
            (constraints.maxHeight - fixed).clamp(60.0, 560.0).toDouble();
        // Питомец — крупно, как в Tamagotchi: до ~75% ширины экрана.
        final size = (280 * scale).clamp(
          0.0,
          math.min(constraints.maxWidth * 0.75, avatarBox),
        ).toDouble();

        return Column(
          children: [
            const SizedBox(height: 8),
            // Верхняя приборная полоса: уровень, XP, стадия (ТЗ §8.10).
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _HudTopStrip(
                pet: pet,
                species: species,
                stage: periods.stage,
              ),
            ),
            const SizedBox(height: 8),
            // Питомец — в центре оставшегося места.
            // Ровно один AnimatedContainer вокруг аватара —
            // тест pet_growth_test ищет его по эмодзи.
            Expanded(
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutBack,
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    color: species.color.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: species.color.withValues(alpha: 0.5),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: species.color.withValues(alpha: 0.35),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(emoji, style: TextStyle(fontSize: size / 2)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Имя + настроение.
            Column(
              children: [
                Text(
                  pet.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(pet.mood.emoji, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 6),
                    Text(
                      pet.mood.label,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Превью дизайна: вид метрик (шкала / кольцо / ячейки).
            _MetricVariantSwitcher(
              variant: _metricVariant,
              onChanged: (v) => setState(() => _metricVariant = v),
            ),
            const SizedBox(height: 8),
            // Статусы: три карточки в ряд (выбранный вариант HUD).
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _metricCard(
                      emoji: '🍎',
                      label: 'Сытость',
                      value: pet.hunger,
                      color: AppColors.leaf,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _metricCard(
                      emoji: '🎾',
                      label: 'Веселье',
                      value: pet.fun,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _metricCard(
                      emoji: '🫧',
                      label: 'Чистота',
                      value: pet.cleanliness,
                      color: AppColors.sky,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Кнопки заботы: цена на кнопке, а что изменилось — на карточке.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: CareActionButton(
                      emoji: '🍎',
                      label: 'Кормить',
                      cost: CareCosts.feed,
                      color: AppColors.leaf,
                      enabled: pet.canFeed && wallet.canAfford(CareCosts.feed),
                      onTap: () => _care(
                        context,
                        emoji: '🍎',
                        title: 'Покормил(а) питомца',
                        message:
                            '${pet.name} больше не голоден — сытость растёт.',
                        needLabel: 'корм',
                        cost: CareCosts.feed,
                        statusLabel: 'Сытость',
                        statusBefore: pet.hunger,
                        statusAfter: () => pet.hunger,
                        perform: () => petService.feed(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CareActionButton(
                      emoji: '🎾',
                      label: 'Играть',
                      cost: CareCosts.play,
                      color: AppColors.secondary,
                      enabled: pet.canPlay && wallet.canAfford(CareCosts.play),
                      onTap: () => _care(
                        context,
                        emoji: '🎾',
                        title: 'Поиграл(а) с питомцем',
                        message:
                            '${pet.name} отлично проводит время — веселье растёт.',
                        needLabel: 'игру',
                        cost: CareCosts.play,
                        statusLabel: 'Веселье',
                        statusBefore: pet.fun,
                        statusAfter: () => pet.fun,
                        perform: () => petService.play(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CareActionButton(
                      emoji: '🫧',
                      label: 'Мыть',
                      cost: CareCosts.wash,
                      color: AppColors.sky,
                      enabled: pet.canWash && wallet.canAfford(CareCosts.wash),
                      onTap: () => _care(
                        context,
                        emoji: '🫧',
                        title: 'Помыл(а) питомца',
                        message: '${pet.name} чистый — чистота на максимуме.',
                        needLabel: 'купание',
                        cost: CareCosts.wash,
                        statusLabel: 'Чистота',
                        statusBefore: pet.cleanliness,
                        statusAfter: () => pet.cleanliness,
                        perform: () => petService.wash(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  /// Карточка метрики в выбранном варианте HUD.
  Widget _metricCard({
    required String emoji,
    required String label,
    required double value,
    required Color color,
  }) {
    return switch (_metricVariant) {
      HudMetricVariant.bar => HudBarCard(
        emoji: emoji,
        label: label,
        value: value,
        color: color,
      ),
      HudMetricVariant.ring => HudRingCard(
        emoji: emoji,
        label: label,
        value: value,
        color: color,
      ),
      HudMetricVariant.segments => HudSegmentCard(
        emoji: emoji,
        label: label,
        value: value,
        color: color,
      ),
    };
  }

  /// Приблизительная высота фиксированных блоков HUD (полоса, имя,
  /// переключатель, метрики, кнопки, отступы) — чтобы блок питомца
  /// не вылезал за пределы вкладки.
  double _fixedHeight() {
    final metrics = switch (_metricVariant) {
      HudMetricVariant.bar => 62.0,
      HudMetricVariant.ring => 104.0,
      HudMetricVariant.segments => 86.0,
    };
    return 8 + 40 + 8 + 52 + 8 + 30 + 8 + metrics + 12 + 110 + 16;
  }

  /// Забота (кормление / игра / мытьё): списывает монетки, обновляет статусы
  /// и показывает карточку обратной связи (ТЗ §8.9). При нехватке средств —
  /// безопасное объяснение и способ исправить, без обнуления прогресса.
  void _care(
    BuildContext context, {
    required String emoji,
    required String title,
    required String message,
    required String needLabel,
    required int cost,
    required String statusLabel,
    required double statusBefore,
    required double Function() statusAfter,
    required bool Function() perform,
  }) {
    final svc = context.read<PetService>();
    final wallet = context.read<WalletService>();
    final feedback = context.read<FeedbackService>();
    final pet = svc.pet;
    if (pet == null) return;

    final ok = perform();
    if (!ok) {
      feedback.post(
        FeedbackEvent.careInsufficient(
          petName: pet.name,
          needLabel: needLabel,
          needed: (cost - wallet.balance).clamp(0, 999999),
          petMood: pet.mood,
        ),
      );
      return;
    }
    if (svc.justLeveledUp) {
      svc.consumeLevelUp();
      feedback.post(FeedbackEvent.levelUp(level: pet.level, petName: pet.name));
    } else {
      feedback.post(
        FeedbackEvent.care(
          actionEmoji: emoji,
          title: title,
          message: message,
          statusChange:
              '$statusLabel: ${statusBefore.round()} → ${statusAfter().round()}',
          cost: cost,
          nextStep: 'Дальше: сделай задание или добавь в копилку.',
          petMood: pet.mood,
          petName: pet.name,
        ),
      );
    }
  }
}

/// Верхняя приборная полоса HUD: уровень, прогресс XP, стадия
/// финансовой ответственности (ТЗ §8.10: обе оси видны на главном экране).
class _HudTopStrip extends StatelessWidget {
  const _HudTopStrip({
    required this.pet,
    required this.species,
    required this.stage,
  });

  final Pet pet;
  final PetSpecies species;
  final FinancialStage stage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.rust.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          // Уровень — рыжий чип, цифры табличные.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.rust,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Ур. ${pet.level}',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Прогресс до следующего уровня.
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 10,
                child: ColoredBox(
                  color: species.color.withValues(alpha: 0.18),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: pet.progressToNext.clamp(0, 1).toDouble(),
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: species.color),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Стадия финансовой ответственности — отдельная ось (не XP).
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.bgDeep,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.leaf.withValues(alpha: 0.6),
                width: 1.5,
              ),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '${stage.emoji} ${stage.label}',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Переключатель вида метрик (превью дизайна): шкала / кольцо / ячейки.
class _MetricVariantSwitcher extends StatelessWidget {
  const _MetricVariantSwitcher({
    required this.variant,
    required this.onChanged,
  });

  final HudMetricVariant variant;
  final ValueChanged<HudMetricVariant> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final v in HudMetricVariant.values) ...[
          if (v != HudMetricVariant.values.first) const SizedBox(width: 8),
          GestureDetector(
            onTap: () => onChanged(v),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: v == variant ? AppColors.rust : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.rust.withValues(
                    alpha: v == variant ? 1 : 0.4,
                  ),
                  width: 1.5,
                ),
              ),
              child: Text(
                v.label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: v == variant ? Colors.white : AppColors.rust,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Плавающий сниackbar с текстом.
SnackBar _snack(String message) => SnackBar(
  content: Text(message),
  behavior: SnackBarBehavior.floating,
  backgroundColor: AppColors.ink,
  duration: const Duration(seconds: 2),
);

/// Время операции в истории кошелька: «09.18 14:05».
String _fmtOperationAt(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')} '
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

/// Пустое состояние, если питомец не создан.
class _NoPet extends StatelessWidget {
  const _NoPet();

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Text('🐾', style: TextStyle(fontSize: 64)),
        SizedBox(height: 16),
        Text(
          'Создай питомца, чтобы начать!',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.inkSoft,
          ),
        ),
      ],
    ),
  );
}

/// Таб «Кошелёк»: баланс, график заработка и копилка с целями.
class _WalletTab extends StatelessWidget {
  const _WalletTab();

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletService>();
    final piggy = context.watch<PiggyBankService>();
    final petService = context.read<PetService>();

    final incomes = dailyIncomes(wallet.transactions, DateTime.now());
    final hasIncomes = incomes.any((v) => v > 0);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _card(
          child: Column(
            children: [
              const Text(
                '🪙 Баланс',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.inkSoft,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${wallet.balance}',
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Text(
                      'монеток',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ),
                ],
              ),
              if (piggy.totalSaved > 0) ...[
                const SizedBox(height: 12),
                Text(
                  '🏦 В копилке: ${piggy.totalSaved}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF3E8E4E),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Заработок за неделю',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 14),
              hasIncomes
                  ? EarningsChart(incomes: incomes)
                  : const EmptyChartHint(),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // История операций (ТЗ §8.11): откуда появились и куда ушли монетки.
        // Каждая операция объяснена строкой — баланс не меняется молча.
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Последние операции',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 10),
              if (wallet.transactions.isEmpty)
                const Text(
                  'Пока пусто: выполни задание или покорми питомца.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: AppColors.inkSoft,
                  ),
                )
              else
                ...wallet.transactions
                    .take(6)
                    .map(
                      (t) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Text(t.emoji, style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                t.reason,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.ink,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              _fmtOperationAt(t.at),
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.inkSoft,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${t.amount > 0 ? '+' : ''}${t.amount}',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: t.amount > 0
                                    ? const Color(0xFF3E8E4E)
                                    : AppColors.primaryDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Копилка',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () => _openAddGoal(context, piggy),
              icon: const Icon(
                Icons.add_circle_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              label: const Text(
                'Новая цель',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (piggy.goals.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              children: [
                Text('🏦', style: TextStyle(fontSize: 36)),
                SizedBox(height: 10),
                Text(
                  'Пока пусто. Создай цель —\nнапример, копим на велосипед!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.4,
                    fontWeight: FontWeight.w700,
                    color: AppColors.inkSoft,
                  ),
                ),
              ],
            ),
          )
        else
          ...piggy.goals.map(
            (g) => _GoalCard(
              goal: g,
              canSave: wallet.canAfford(5),
              onTopUp: () =>
                  _openSaveGoal(context, wallet, piggy, petService, g),
            ),
          ),
      ],
    );
  }

  Widget _card({required Widget child}) => Container(
    padding: const EdgeInsets.all(20),
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
    child: child,
  );
}

/// Карточка цели копилки: прогресс и кнопка «Копить».
class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.goal,
    required this.canSave,
    required this.onTopUp,
  });

  final PiggyBankGoal goal;
  final bool canSave;
  final VoidCallback onTopUp;

  @override
  Widget build(BuildContext context) {
    final reached = goal.isReached;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.leaf.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(goal.emoji, style: const TextStyle(fontSize: 26)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      reached
                          ? 'Цель достигнута! 🎉'
                          : 'Осталось: ${goal.target - goal.saved} монеток',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: reached
                            ? const Color(0xFF3E8E4E)
                            : AppColors.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
              if (!reached)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canSave
                        ? AppColors.primary
                        : Colors.black.withValues(alpha: 0.08),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    minimumSize: const Size(0, 44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: canSave ? onTopUp : null,
                  child: const Text(
                    'Копить',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Прогресс: 0 → 1.
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 10,
              child: ColoredBox(
                color: AppColors.bgDeep,
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: goal.progress,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: reached ? const Color(0xFF3E8E4E) : AppColors.leaf,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${goal.saved} / ${goal.target} монеток',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppColors.inkSoft.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

/// Диалог «сколько положить в копилку»: 5 / 10 / 20 монеток одним нажатием.
void _openSaveGoal(
  BuildContext context,
  WalletService wallet,
  PiggyBankService piggy,
  PetService petService,
  PiggyBankGoal goal,
) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      contentPadding: const EdgeInsets.all(20),
      title: Row(
        children: [
          Text(goal.emoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Копим: ${goal.title}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'В копилке ${goal.saved} из ${goal.target}. '
            'Осталось: ${goal.target - goal.saved}.',
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.4,
              color: AppColors.inkSoft,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (final amount in const [5, 10, 20]) ...[
                if (amount != 5) const SizedBox(width: 8),
                Expanded(
                  child: _amountChip(
                    amount: amount,
                    enabled: wallet.canAfford(amount),
                    onTap: () {
                      Navigator.of(dialogContext).pop();
                      _doSaveGoal(context, piggy, petService, goal, amount);
                    },
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text(
            'Закрыть',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.inkSoft,
            ),
          ),
        ),
      ],
    ),
  );
}

ElevatedButton _amountChip({
  required int amount,
  required bool enabled,
  required VoidCallback onTap,
}) => ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: enabled
        ? AppColors.primary
        : Colors.black.withValues(alpha: 0.08),
    foregroundColor: enabled
        ? Colors.white
        : Colors.black.withValues(alpha: 0.3),
    minimumSize: const Size(0, 52),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
  ),
  onPressed: enabled ? onTap : null,
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        '$amount',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
      ),
      const Text('🪙', style: TextStyle(fontSize: 12)),
    ],
  ),
);

void _doSaveGoal(
  BuildContext context,
  PiggyBankService piggy,
  PetService petService,
  PiggyBankGoal goal,
  int amount,
) {
  final savedBefore = goal.saved;
  final ok = piggy.saveToGoal(goal.id, amount);
  if (!context.mounted) return;
  final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
  if (!ok) {
    messenger.showSnackBar(_snack('Не хватает монеток 🪙'));
    return;
  }
  // saveToGoal ограничивает сумму до остатка до цели — показываем факт.
  final actual = (goal.saved - savedBefore).clamp(1, 999999);
  final pet = petService.pet;
  final feedback = context.read<FeedbackService>();
  if (goal.isReached && petService.justLeveledUp) {
    // Повышение уровня громче достижения цели.
    petService.consumeLevelUp();
    feedback.post(
      FeedbackEvent.levelUp(
        level: pet?.level ?? 1,
        petName: pet?.name ?? 'Питомец',
      ),
    );
    return;
  }
  feedback.post(
    FeedbackEvent.savings(
      amount: actual,
      goalTitle: goal.title,
      saved: goal.saved,
      target: goal.target,
      petMood: pet?.mood,
      petName: pet?.name,
      reached: goal.isReached,
    ),
  );
}

/// Диалог создания новой цели копилки.
void _openAddGoal(BuildContext context, PiggyBankService piggy) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final dialog = _AddGoalDialog(
        onCreate: (title, emoji, target) {
          piggy.addGoal(title, emoji, target);
          if (dialogContext.mounted) {
            Navigator.of(dialogContext).pop();
          }
        },
      );
      return dialog;
    },
  );
}

class _AddGoalDialog extends StatefulWidget {
  const _AddGoalDialog({required this.onCreate});

  final void Function(String title, String emoji, int target) onCreate;

  @override
  State<_AddGoalDialog> createState() => _AddGoalDialogState();
}

class _AddGoalDialogState extends State<_AddGoalDialog> {
  static const _emojis = ['🎯', '🚲', '🎮', '🧸', '🛴', '📚'];
  static const _targets = [50, 100, 200];

  final _controller = TextEditingController();
  String _emoji = _AddGoalDialogState._emojis.first;
  int _target = 100;

  @override
  void initState() {
    super.initState();
    // Пересчитываем состояние (кнопка «Создать») при вводе названия.
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      contentPadding: const EdgeInsets.all(20),
      title: const Text(
        'Новая цель копилки',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: AppColors.ink,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            maxLength: 24,
            decoration: const InputDecoration(
              labelText: 'На что копишь?',
              hintText: 'Велосипед, игра, книга…',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final e in _AddGoalDialogState._emojis)
                ChoiceChip(
                  label: Text(e, style: const TextStyle(fontSize: 18)),
                  selected: _emoji == e,
                  onSelected: (_) => setState(() => _emoji = e),
                  selectedColor: AppColors.primary.withValues(alpha: 0.2),
                ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Сколько монеток собрать?',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.inkSoft,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final t in _AddGoalDialogState._targets) ...[
                if (t != _AddGoalDialogState._targets.first)
                  const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: Text(
                      '$t',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    selected: _target == t,
                    onSelected: (_) => setState(() => _target = t),
                    selectedColor: AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Отмена',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.inkSoft,
            ),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: _controller.text.trim().isEmpty
              ? null
              : () => widget.onCreate(_controller.text.trim(), _emoji, _target),
          child: const Text(
            'Создать',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

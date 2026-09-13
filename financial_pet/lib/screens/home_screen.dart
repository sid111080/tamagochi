import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/growth_stage.dart';
import '../models/pet.dart';
import '../models/pet_species.dart';
import '../models/piggy_bank_goal.dart';
import '../models/streak_badge.dart';
import '../models/task.dart';
import '../services/pet_service.dart';
import '../services/piggy_bank_service.dart';
import '../services/task_service.dart';
import '../services/wallet_service.dart';
import '../theme/app_theme.dart';
import '../widgets/action_button.dart';
import '../widgets/coin_badge.dart';
import '../widgets/earnings_chart.dart';
import '../widgets/level_indicator.dart';
import '../widgets/status_bar.dart';
import '../widgets/task_card.dart';

/// Главный экран: два таба — питомец и задания.
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
                  CoinBadge(balance: wallet.balance),
                ],
              ),
            ),
            Expanded(
              child: IndexedStack(
                index: _tab,
                children: const [_PetTab(), _TasksTab(), _WalletTab()],
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
            icon: Icon(Icons.task_alt_rounded),
            label: 'Задания',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_rounded),
            label: 'Кошелёк',
          ),
        ],
      ),
    );
  }
}

/// Таб «Питомец»: аватар, настроение, уровень, статусы, забота.
class _PetTab extends StatelessWidget {
  const _PetTab();

  @override
  Widget build(BuildContext context) {
    final petService = context.watch<PetService>();
    final wallet = context.watch<WalletService>();
    final pet = petService.pet;

    if (pet == null) return const _NoPet();

    final species = PetSpecies.byId(pet.speciesId);
    final emoji = species.emojiForIndex(pet.stage.index);
    final scale = pet.stage.sizeScale;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Аватар + имя + настроение.
        Center(
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutBack,
                width: 130 * scale,
                height: 130 * scale,
                decoration: BoxDecoration(
                  color: species.color.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: species.color.withValues(alpha: 0.35),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    emoji,
                    style: TextStyle(fontSize: 64 * scale),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                pet.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(pet.mood.emoji,
                      style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 6),
                  Text(
                    pet.mood.label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        LevelIndicator(pet: pet, species: species),
        const SizedBox(height: 16),
        // Статусы.
        Container(
          padding: const EdgeInsets.all(16),
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
            children: [
              PetStatusBar(
                label: 'Сытость',
                emoji: '🍎',
                value: pet.hunger,
                color: AppColors.leaf,
              ),
              const SizedBox(height: 14),
              PetStatusBar(
                label: 'Веселье',
                emoji: '🎾',
                value: pet.fun,
                color: AppColors.secondary,
              ),
              const SizedBox(height: 14),
              PetStatusBar(
                label: 'Чистота',
                emoji: '🫧',
                value: pet.cleanliness,
                color: AppColors.sky,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Кнопки заботы.
        Row(
          children: [
            Expanded(
              child: CareActionButton(
                emoji: '🍎',
                label: 'Кормить',
                cost: CareCosts.feed,
                color: AppColors.leaf,
                enabled:
                    pet.canFeed && wallet.canAfford(CareCosts.feed),
                onTap: () => _care(context, () => petService.feed()),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: CareActionButton(
                emoji: '🎾',
                label: 'Играть',
                cost: CareCosts.play,
                color: AppColors.secondary,
                enabled:
                    pet.canPlay && wallet.canAfford(CareCosts.play),
                onTap: () => _care(context, () => petService.play()),
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
                onTap: () => _care(context, () => petService.wash()),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _care(BuildContext context, bool Function() perform) {
    final ok = perform();
    if (!ok) {
      _toast(context, 'Не хватает монеток 🪙');
      return;
    }
    final svc = context.read<PetService>();
    if (svc.justLeveledUp) {
      svc.consumeLevelUp();
      _toast(context, '🎉 Уровень повышен!');
    } else {
      _toast(context, 'Готово, питомец доволен 🐾');
    }
  }

  void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.ink,
          duration: const Duration(seconds: 2),
        ),
      );
  }
}

/// Таб «Задания»: доступные сейчас и выполненные.
class _TasksTab extends StatelessWidget {
  const _TasksTab();

  @override
  Widget build(BuildContext context) {
    final taskService = context.watch<TaskService>();
    final petService = context.read<PetService>();

    final available = taskService.availableTasks;
    final completed = taskService.completedTasks;

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
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
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
        _StreakBadgesRow(maxStreak: taskService.maxStreak),
        const SizedBox(height: 14),
        if (available.isEmpty)
          const _EmptyTasks()
        else
          ...available.map(
            (t) => TaskCard(
              task: t,
              onComplete: () => _confirmComplete(context, t, petService),
            ),
          ),
        if (completed.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Text(
            'Выполнено',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.inkSoft,
            ),
          ),
          const SizedBox(height: 14),
          ...completed.map(
            (t) => TaskCard(task: t, onComplete: () {}),
          ),
        ],
      ],
    );
  }

  /// Подтверждение: награда даётся, только если задание действительно сделано.
  void _confirmComplete(
      BuildContext context, Task task, PetService petService) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20))),
        contentPadding: const EdgeInsets.all(20),
        title: Row(
          children: [
            Text(task.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Ты выполнил(а) задание?',
                style: TextStyle(
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
              task.title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              task.description,
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.4,
                color: AppColors.inkSoft,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Расскажи маме или папе, что ты сделал(а). Награда: '
              '🪙 +${task.coinReward}, ⭐ +${task.xpReward} XP',
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.35,
                color: AppColors.inkSoft,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(
              'Пока нет',
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
              padding: const EdgeInsets.symmetric(
                  horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Да, выполнил(а)!',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed != true || !context.mounted) return;
      final ok = context.read<TaskService>().completeTask(task.id);
      if (!ok) return;
      final messenger = ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar();
      if (petService.justLeveledUp) {
        petService.consumeLevelUp();
        messenger.showSnackBar(_snack('🎉 Уровень повышен!'));
      } else {
        messenger.showSnackBar(
          _snack('🎉 +${task.coinReward} 🪙, +${task.xpReward} XP'),
        );
      }
    });
  }
}

/// Плавающий сниackbar с текстом.
SnackBar _snack(String message) => SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.ink,
      duration: const Duration(seconds: 2),
    );

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

/// Пустое состояние, если все задания выполнены.
class _EmptyTasks extends StatelessWidget {
  const _EmptyTasks();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text('🎊', style: TextStyle(fontSize: 48)),
            SizedBox(height: 12),
            Text(
              'Все задания выполнены!\nВозвращайся завтра за новыми.',
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

/// Ряд бейджей стрика: полученные — яркие, будущие — приглушённые.
class _StreakBadgesRow extends StatelessWidget {
  const _StreakBadgesRow({required this.maxStreak});

  final int maxStreak;

  @override
  Widget build(BuildContext context) {
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
              color: earned
                  ? null
                  : Colors.black.withValues(alpha: 0.2),
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
              icon: const Icon(Icons.add_circle_rounded,
                  color: AppColors.primary, size: 20),
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
                  child: Text(goal.emoji,
                      style: const TextStyle(fontSize: 26)),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16),
                    minimumSize: const Size(0, 44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: canSave ? onTopUp : null,
                  child: const Text(
                    'Копить',
                    style:
                        TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800),
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
                      color: reached
                          ? const Color(0xFF3E8E4E)
                          : AppColors.leaf,
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
          borderRadius: BorderRadius.all(Radius.circular(20))),
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
                      _doSaveGoal(
                          context, piggy, petService, goal, amount);
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
}) =>
    ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: enabled
            ? AppColors.primary
            : Colors.black.withValues(alpha: 0.08),
        foregroundColor:
            enabled ? Colors.white : Colors.black.withValues(alpha: 0.3),
        minimumSize: const Size(0, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      onPressed: enabled ? onTap : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$amount',
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w900)),
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
  final ok = piggy.saveToGoal(goal.id, amount);
  if (!context.mounted) return;
  final messenger = ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar();
  if (!ok) {
    messenger.showSnackBar(_snack('Не хватает монеток 🪙'));
    return;
  }
  if (goal.isReached) {
    messenger.showSnackBar(
        _snack('🎉 Цель «${goal.title}» достигнута! +$goalReachedXp XP'));
    if (petService.justLeveledUp) {
      petService.consumeLevelUp();
      messenger.showSnackBar(_snack('🎉 Уровень повышен!'));
    }
  } else {
    messenger.showSnackBar(_snack('В копилку +$amount 🪙'));
  }
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
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20))),
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
            padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: _controller.text.trim().isEmpty
              ? null
              : () => widget.onCreate(
                  _controller.text.trim(), _emoji, _target),
          child: const Text(
            'Создать',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

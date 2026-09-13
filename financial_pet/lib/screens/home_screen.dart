import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/growth_stage.dart';
import '../models/pet.dart';
import '../models/pet_species.dart';
import '../models/task.dart';
import '../services/pet_service.dart';
import '../services/task_service.dart';
import '../services/wallet_service.dart';
import '../theme/app_theme.dart';
import '../widgets/action_button.dart';
import '../widgets/coin_badge.dart';
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
                children: const [_PetTab(), _TasksTab()],
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

  SnackBar _snack(String message) => SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        duration: const Duration(seconds: 2),
      );
}

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

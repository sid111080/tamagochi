import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../core/models/budget.dart';
import '../../core/models/pet.dart';
import '../../core/models/pet_species.dart';
import '../../core/models/task.dart';
import '../../core/services/demo_service.dart';
import '../../core/services/feedback_service.dart';
import '../../core/services/pet_service.dart';
import '../../core/services/piggy_bank_service.dart';
import '../../core/services/period_service.dart';
import '../../core/services/task_service.dart';
import '../../core/services/wallet_service.dart';
import '../../data/content/education_goals.dart';
import '../pet_creation/create_pet_screen.dart';

/// Раздел для взрослого (ТЗ §8.12).
///
/// Отделён барьером (удержание кнопки): за барьером — цели приложения,
/// пройденные темы, общий прогресс и управление профилем (сброс/удаление).
/// Все формулировки нейтральные — без оценок ребёнка.
class AdultSection extends StatefulWidget {
  const AdultSection({super.key});

  @override
  State<AdultSection> createState() => _AdultSectionState();
}

class _AdultSectionState extends State<AdultSection> {
  bool _unlocked = false;

  void _unlock() => setState(() => _unlocked = true);

  /// Обратная навигация из контента: возврат за барьер.
  void _relock() => setState(() => _unlocked = false);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
          onPressed: () {
            if (_unlocked) {
              // Контент → обратно за барьер.
              _relock();
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Text(
          _unlocked ? 'Для взрослых' : 'Проверка',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
      ),
      body: _unlocked
          ? const _AdultContent()
          : _AdultBarrier(onUnlocked: _unlock),
    );
  }
}

/// Барьер: удержание крупной кнопки (ТЗ §8.12: «удержание кнопки»).
/// 5 секунд удержания — ребёнку 7–11 трудно выдержать, взрослому — секунды.
class _AdultBarrier extends StatefulWidget {
  const _AdultBarrier({required this.onUnlocked});

  final VoidCallback onUnlocked;

  @override
  State<_AdultBarrier> createState() => _AdultBarrierState();
}

class _AdultBarrierState extends State<_AdultBarrier>
    with SingleTickerProviderStateMixin {
  static const Duration _holdDuration = Duration(seconds: 5);
  static const int _holdSeconds = 5;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _holdDuration,
  );
  bool _unlocked = false;

  @override
  void initState() {
    super.initState();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_unlocked) {
        _unlocked = true;
        widget.onUnlocked();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startHold() {
    if (!_unlocked) _controller.forward(from: 0);
  }

  void _cancelHold() {
    if (!_unlocked && _controller.isAnimating) _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🔒', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            const Text(
              'Раздел для взрослых',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Удерживайте кнопку 5 секунд,\nчтобы открыть раздел',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.4,
                color: AppColors.inkSoft,
              ),
            ),
            const SizedBox(height: 32),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final remaining =
                    (_holdSeconds * (1 - _controller.value)).ceil();
                return GestureDetector(
                  onPanStart: (_) => _startHold(),
                  onPanEnd: (_) => _cancelHold(),
                  onTapDown: (_) => _startHold(),
                  onTapUp: (_) => _cancelHold(),
                  child: Container(
                    width: 220,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        children: [
                          // Прогресс удержания.
                          FractionallySizedBox(
                            widthFactor: _controller.value,
                            alignment: Alignment.centerLeft,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: AppColors.leaf.withValues(
                                    alpha: 0.45),
                              ),
                            ),
                          ),
                          Center(
                            child: Text(
                              _unlocked
                                  ? 'Открыто ✓'
                                  : 'Держать: $remaining с',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            const Text(
              'Здесь нет оценок — только факты о прогрессе.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: AppColors.inkSoft,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Контент раздела для взрослого (ТЗ §8.12): цели приложения, пройденные
/// темы, общий прогресс и управление профилем (сброс/удаление с подтверждением).
class _AdultContent extends StatelessWidget {
  const _AdultContent();

  static const Color _good = Color(0xFF3E8E4E);

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletService>();
    final petService = context.watch<PetService>();
    final tasks = context.watch<TaskService>();
    final piggy = context.watch<PiggyBankService>();
    final period = context.watch<PeriodService>();
    final pet = petService.pet;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Цели приложения (контент отделён от UI, ТЗ §4).
        _SectionCard(
          title: '🎯 Цели приложения',
          child: Column(
            children: [
              for (final goal in appGoals)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 18,
                        color: _good,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          goal,
                          style: const TextStyle(
                            fontSize: 13.5,
                            height: 1.35,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Пройденные темы (ТЗ §8.12).
        _SectionCard(
          title: '📚 Темы',
          child: Column(
            children: [
              for (final topic in TaskTopic.values) ...[
                _TopicRow(
                  topic: topic,
                  progress: tasks.topicProgress[topic] ?? (0, 0),
                ),
                if (topic.index < TaskTopic.values.length - 1)
                  const SizedBox(height: 14),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Общий прогресс: факты без оценок.
        _SectionCard(
          title: '📈 Общий прогресс',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(period.stage.emoji,
                      style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      period.stage.label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  Text(
                    '${period.points} очков',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Сезон: 5 периодов × 3 очка = максимум 15.
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: (period.points / 15).clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: AppColors.bgDeep,
                  color: AppColors.leaf,
                ),
              ),
              const SizedBox(height: 14),
              _row(
                icon: '🐾',
                label: 'Питомец',
                value: pet == null
                    ? 'ещё не создан'
                    : '${pet.name}, ур. ${pet.level} · ${pet.mood.emoji} ${pet.mood.label}',
              ),
              _row(
                icon: '🏦',
                label: 'Копилка',
                value:
                    '${piggy.totalSaved} монеток, целей: ${piggy.goals.length}',
              ),
              _row(
                icon: '🔥',
                label: 'Лучший стрик',
                value: '${tasks.maxStreak} дн.',
              ),
              _row(
                icon: '🪙',
                label: 'Баланс',
                value: '${wallet.balance} монеток',
              ),
              if (period.lastResult != null) ...[
                const Divider(height: 20),
                Text(
                  'Итог последнего периода: ${period.lastResult!.score}/3 — '
                  '${period.lastResult!.explanation}',
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: AppColors.inkSoft,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Управление профилем: значимые действия — только с подтверждением (ТЗ §10).
        _SectionCard(
          title: '⚙️ Профиль',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Действия применяются только к локальным данным на этом '
                'устройстве.',
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.4,
                  color: AppColors.inkSoft,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.leaf,
                    side: const BorderSide(color: AppColors.leaf),
                    minimumSize: const Size(48, 52),
                  ),
                  onPressed: () => _awardCoins(context),
                  icon: const Icon(Icons.volunteer_activism_rounded),
                  label: const Text('Начислить 25 монеток',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.ink,
                    side: BorderSide(color: AppColors.inkSoft.withValues(alpha: 0.5)),
                    minimumSize: const Size(48, 52),
                  ),
                  onPressed: () => _confirmReset(context),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Сбросить прогресс',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(48, 52),
                  ),
                  onPressed: () => _confirmDelete(context),
                  icon: const Icon(Icons.delete_rounded),
                  label: const Text('Удалить профиль',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Строка «прогресс»: значок + подпись + значение.
  Widget _row({
    required String icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: AppColors.inkSoft,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Доп. баллы от родителя (ТЗ §8.12: «на усмотрение команды»).
  void _awardCoins(BuildContext context) {
    context.read<WalletService>().earn(25, 'Подарок от родителя', '💡');
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Родитель начислил 25 монеток 💡'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.ink,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  /// Сброс прогресса: питомец с тем же именем и видом, всё остальное — к старту.
  /// В демо-режиме — пересоздание демо-профиля.
  Future<void> _confirmReset(BuildContext context) async {
    // Сервисы читаем до async-паузы (диалога подтверждения).
    final demo = context.read<DemoService>();
    final petService = context.read<PetService>();
    final tasks = context.read<TaskService>();
    final wallet = context.read<WalletService>();
    final piggy = context.read<PiggyBankService>();
    final period = context.read<PeriodService>();
    final pet = petService.pet;
    final name = pet?.name ?? 'Питомец';
    final speciesId = pet?.speciesId ?? PetSpecies.all.first.id;

    final ok = await _confirm(
      context,
      title: 'Сбросить прогресс?',
      message:
          'Задания, баланс, копилка и периоды будут обнулены, питомец создан '
          'заново (имя и вид сохранятся). Действие необратимо.',
      confirmLabel: 'Сбросить',
    );
    if (!ok || !context.mounted) return;

    if (demo.isDemo) {
      demo.resetDemo();
    } else {
      tasks.resetProgress();
      wallet.reset();
      piggy.reset();
      period.reset();
      if (pet != null) {
        petService
          ..removePet()
          ..createPet(name, speciesId);
      }
    }
    if (context.mounted) {
      // Профиль пересоздан — старые карточки обратной связи сбрасываем.
      context.read<FeedbackService>().clear();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: const Text('Прогресс сброшен'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.ink,
            duration: const Duration(seconds: 2),
          ),
        );
    }
  }

  /// Удаление профиля: весь локальный профиль удалён, возврат на создание питомца.
  Future<void> _confirmDelete(BuildContext context) async {
    // Сервисы читаем до async-паузы (диалога подтверждения).
    final demo = context.read<DemoService>();
    final petService = context.read<PetService>();
    final tasks = context.read<TaskService>();
    final wallet = context.read<WalletService>();
    final piggy = context.read<PiggyBankService>();
    final period = context.read<PeriodService>();

    final ok = await _confirm(
      context,
      title: 'Удалить профиль?',
      message:
          'Питомец, баланс, задания, копилка и периоды будут полностью '
          'удалены. Вы вернётесь на экран создания питомца.',
      confirmLabel: 'Удалить',
      danger: true,
    );
    if (!ok || !context.mounted) return;

    if (demo.isDemo) {
      demo.exitDemo();
    } else {
      tasks.resetProgress();
      wallet.reset();
      piggy.reset();
      period.reset();
      petService.removePet();
    }
    if (context.mounted) {
      // Профиль удалён — старые карточки обратной связи сбрасываем.
      context.read<FeedbackService>().clear();
      // Чистая стек-навигация: только экран создания питомца.
      // pushAndRemoveUntil — современная замена popAndPushUntil (убран из SDK).
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const CreatePetScreen()),
        (route) => false,
      );
    }
  }

  /// Диалог подтверждения значимого действия (ТЗ §10).
  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    bool danger = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20))),
        contentPadding: const EdgeInsets.all(20),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(
            fontSize: 13.5,
            height: 1.4,
            color: AppColors.inkSoft,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
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
              backgroundColor:
                  danger ? AppColors.primaryDark : AppColors.leaf,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                  horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              confirmLabel,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

/// Карточка-секция раздела для взрослого.
class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

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
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

/// Строка «пройденная тема»: значок, название, счётчик, полоса и галочка.
/// Галочка — не только цветом (ТЗ §10: цвет не единственный сигнал).
class _TopicRow extends StatelessWidget {
  const _TopicRow({required this.topic, required this.progress});

  final TaskTopic topic;

  /// (выполнено, всего) по теме.
  final (int, int) progress;

  @override
  Widget build(BuildContext context) {
    const good = Color(0xFF3E8E4E);
    final (done, all) = progress;
    final complete = all > 0 && done >= all;
    return Column(
      children: [
        Row(
          children: [
            Text(topic.badge, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                topic.label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ),
            Text(
              '$done / $all',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: complete ? good : AppColors.inkSoft,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              complete
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked,
              size: 18,
              color:
                  complete ? good : AppColors.inkSoft.withValues(alpha: 0.5),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: all == 0 ? 0.0 : (done / all).clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: AppColors.bgDeep,
            color: complete ? good : AppColors.leaf,
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../pet_creation/create_pet_screen.dart';

/// Вводный онбординг (ТЗ §8.1): короткое знакомство с целью игры,
/// тремя типами финансовых решений и гостевым режимом.
///
/// Показывается при первом запуске (до создания питомца) и по кнопке
/// «Подсказка» уже из главного экрана.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, this.fromHint = false});

  /// true — открыт из главного экрана как подсказка: по завершении
  /// возвращаемся назад (pop), а не на экран создания питомца.
  final bool fromHint;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const int _pages = 3;

  final PageController _pageController = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Далее → следующий слайд, либо завершение на последнем.
  void _next() {
    if (_page >= _pages - 1) {
      _finish();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  /// Завершение: создание питомца (первый запуск) или возврат (подсказка).
  void _finish() {
    if (widget.fromHint) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const CreatePetScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // «Пропустить» — сверху, всегда доступно.
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                child: TextButton(
                  onPressed: _finish,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(96, 48),
                  ),
                  child: const Text(
                    'Пропустить',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _page = i),
                children: const [
                  _GoalPage(),
                  _DecisionsPage(),
                  _GuestPage(),
                ],
              ),
            ),
            // Точки-индикаторы + кнопка «Далее» / «Начать!».
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < _pages; i++) ...[
                          _Dot(active: i == _page),
                          if (i < _pages - 1) const SizedBox(width: 8),
                        ],
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(132, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    onPressed: _next,
                    child: Text(
                      _page >= _pages - 1
                          ? (widget.fromHint ? 'Готово' : 'Начать!')
                          : 'Далее',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Стр. 1: цель игры.
class _GoalPage extends StatelessWidget {
  const _GoalPage();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const _BigEmoji('🐾'),
            const SizedBox(height: 28),
            const _Title('Давай познакомимся!'),
            const SizedBox(height: 16),
            _Body(
              'Ты становишься хозяином финпитомца. Заботься о нём — '
              'и учишься умно распоряжаться монетками.',
            ),
          ],
        ),
      ),
    );
  }
}

/// Стр. 2: три типа финансовых решений (ядро ТЗ §8.1).
class _DecisionsPage extends StatelessWidget {
  const _DecisionsPage();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const _Title('Как ты тратишь монетки?'),
            const SizedBox(height: 24),
            _DecisionCard(
              emoji: '🍎',
              title: 'Обязательное',
              body: 'Корм и забота. Начинаем с главного.',
              color: AppColors.leaf,
            ),
            const SizedBox(height: 14),
            _DecisionCard(
              emoji: '🎁',
              title: 'Желаемое',
              body: 'Игрушки и радость — если останется.',
              color: AppColors.grape,
            ),
            const SizedBox(height: 14),
            _DecisionCard(
              emoji: '🏦',
              title: 'Отложить',
              body: 'В копилку — на большую цель.',
              color: AppColors.coin,
            ),
          ],
        ),
      ),
    );
  }
}

/// Стр. 3: гостевой режим без регистрации (ТЗ §8.1).
class _GuestPage extends StatelessWidget {
  const _GuestPage();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const _BigEmoji('👤'),
            const SizedBox(height: 28),
            const _Title('Никаких аккаунтов'),
            const SizedBox(height: 16),
            _Body(
              'Нужно только имя питомца. Всё хранится на твоём '
              'устройстве — без интернета и регистрации.',
            ),
          ],
        ),
      ),
    );
  }
}

/// Крупный эмодзи в круге.
class _BigEmoji extends StatelessWidget {
  const _BigEmoji(this.emoji);

  final String emoji;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
            blurRadius: 40,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Center(
        child: Text(emoji, style: const TextStyle(fontSize: 72)),
      ),
    );
  }
}

/// Заголовок слайда.
class _Title extends StatelessWidget {
  const _Title(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w900,
        color: AppColors.ink,
        height: 1.15,
      ),
    );
  }
}

/// Основной текст слайда.
class _Body extends StatelessWidget {
  const _Body(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 16,
        height: 1.5,
        color: AppColors.inkSoft,
      ),
    );
  }
}

/// Карточка типа решения: эмодзи + название + объяснение.
/// Цвет подчёркивает тип, но не единственный сигнал — есть эмодзи и текст.
class _DecisionCard extends StatelessWidget {
  const _DecisionCard({
    required this.emoji,
    required this.title,
    required this.body,
    required this.color,
  });

  final String emoji;
  final String title;
  final String body;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 28)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(
                    fontSize: 14.5,
                    height: 1.3,
                    color: AppColors.inkSoft,
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

/// Точка-индикатор страниц: активная — длиннее и ярче.
class _Dot extends StatelessWidget {
  const _Dot({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      width: active ? 28 : 10,
      height: 10,
      decoration: BoxDecoration(
        color: active
            ? AppColors.primary
            : AppColors.primary.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}

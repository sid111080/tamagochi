import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../core/services/demo_service.dart';
import '../home/home_screen.dart';
import '../onboarding/onboarding_screen.dart';

/// Стартовый экран с логотипом и навигацией.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.hasPet});

  final bool hasPet;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  late final Animation<double> _scale =
      Tween<double>(begin: 0.4, end: 1).animate(
        CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
      );
  late final Animation<double> _fade =
      Tween<double>(begin: 0, end: 1).animate(_controller);

  /// Защита от двойной навигации (авто-переход + нажатие на демо-кнопку).
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _controller.forward();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 1600));
    if (!mounted || _navigated) return;
    _navigated = true;
    // Есть питомец → сразу в Home. Нет → вводный онбординг (ТЗ §8.1),
    // после которого — экран создания питомца.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            widget.hasPet ? const HomeScreen() : const OnboardingScreen(),
      ),
    );
  }

  /// Войти в демо-режим (ТЗ §8.13): чистый тестовый профиль → сразу в Home.
  void _enterDemo() {
    if (_navigated) return;
    _navigated = true;
    context.read<DemoService>().enterDemo();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.bg, AppColors.bgDeep],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _scale,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary
                              .withValues(alpha: 0.3),
                          blurRadius: 40,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text('🐱',
                          style: TextStyle(fontSize: 72)),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'ФинПитомец',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Учись копить и заботиться —\nсвоим питомцем и деньгами',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.4,
                    color: AppColors.inkSoft,
                  ),
                ),
                const SizedBox(height: 40),
                const Text(
                  'Rustore',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.inkSoft,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 28),
                TextButton.icon(
                  onPressed: _enterDemo,
                  icon: const Icon(
                    Icons.play_circle_outline_rounded,
                    color: AppColors.inkSoft,
                  ),
                  label: const Text(
                    'Демо-режим',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

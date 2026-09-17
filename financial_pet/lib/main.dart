import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/theme.dart';
import 'core/models/task.dart';
import 'core/services/demo_service.dart';
import 'core/services/pet_service.dart';
import 'core/services/period_service.dart';
import 'core/services/piggy_bank_service.dart';
import 'core/services/purchase_service.dart';
import 'core/services/task_service.dart';
import 'core/services/wallet_service.dart';
import 'data/content/content_repository.dart';
import 'features/onboarding/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  // Учебный контент (задания) грузим один раз при старте:
  // это слой данных, отделённый от игровой логики (ТЗ §4, §8.14).
  final tasks = await const ContentRepository().loadTasks();
  runApp(App(prefs: prefs, tasks: tasks));
}

/// Корень приложения: предоставляет сервисы, контент и тему.
class App extends StatelessWidget {
  const App({super.key, required this.prefs, required this.tasks});

  final SharedPreferences prefs;
  final List<Task> tasks;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WalletService(prefs)),
        ChangeNotifierProvider(
          create: (ctx) =>
              PetService(prefs, ctx.read<WalletService>()),
        ),
        ChangeNotifierProvider(
          create: (ctx) => TaskService(
            prefs,
            ctx.read<WalletService>(),
            ctx.read<PetService>(),
            tasks,
          ),
        ),
        ChangeNotifierProvider(
          create: (ctx) => PiggyBankService(
            prefs,
            ctx.read<WalletService>(),
            ctx.read<PetService>(),
          ),
        ),
        // Магазин: каталог товаров и покупка (ТЗ §8.6).
        ChangeNotifierProvider(
          create: (ctx) => PurchaseService(
            ctx.read<WalletService>(),
            ctx.read<PetService>(),
          ),
        ),
        // Периоды и план бюджета: движок игровой экономики. Регистрируется
        // последним, чтобы иметь доступ к кошельку, питомцу и копилке.
        ChangeNotifierProvider(
          create: (ctx) {
            final period = PeriodService(
              prefs,
              ctx.read<WalletService>(),
              ctx.read<PetService>(),
            );
            // Тратопредупреждение: забота → «обязательные»,
            // копилка → «накопления», покупки → по категории.
            ctx.read<PetService>().spendReporter = period;
            ctx.read<PiggyBankService>().spendReporter = period;
            ctx.read<PurchaseService>().spendReporter = period;
            return period;
          },
        ),
        // Демо-режим (ТЗ §8.13): оркестратор тестового профиля.
        // Последний в дереве — имеет доступ ко всем сервисам выше.
        ChangeNotifierProvider(
          create: (ctx) => DemoService(
            prefs,
            ctx.read<WalletService>(),
            ctx.read<PetService>(),
            ctx.read<TaskService>(),
            ctx.read<PiggyBankService>(),
            ctx.read<PeriodService>(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'ФинПитомец',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: Consumer<PetService>(
          builder: (context, petService, _) =>
              SplashScreen(hasPet: petService.hasPet),
        ),
      ),
    );
  }
}

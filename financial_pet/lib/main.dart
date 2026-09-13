import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/splash_screen.dart';
import 'services/pet_service.dart';
import 'services/task_service.dart';
import 'services/wallet_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(App(prefs: prefs));
}

/// Корень приложения: предоставляет сервисы и тему.
class App extends StatelessWidget {
  const App({super.key, required this.prefs});

  final SharedPreferences prefs;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WalletService(prefs)),
        ChangeNotifierProvider(
          create: (_) =>
              PetService(prefs, context.read<WalletService>()),
        ),
        ChangeNotifierProvider(
          create: (_) => TaskService(
            prefs,
            context.read<WalletService>(),
            context.read<PetService>(),
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

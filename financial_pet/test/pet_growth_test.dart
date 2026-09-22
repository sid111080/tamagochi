import 'package:financial_pet/core/models/pet.dart';
import 'package:financial_pet/core/models/task.dart';
import 'package:financial_pet/core/services/demo_service.dart';
import 'package:financial_pet/core/services/feedback_service.dart';
import 'package:financial_pet/core/services/period_service.dart';
import 'package:financial_pet/core/services/pet_service.dart';
import 'package:financial_pet/core/services/piggy_bank_service.dart';
import 'package:financial_pet/core/services/purchase_service.dart';
import 'package:financial_pet/core/services/task_service.dart';
import 'package:financial_pet/core/services/wallet_service.dart';
import 'package:financial_pet/features/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ТЗ §8.10: при новом уровне изображение питомца увеличивается
/// (sizeScale от уровня, аватар в AnimatedContainer).
///
/// Регрессия: «уровень поднимается, а картинка не меняется» — обычно
/// означает устаревшую сборку (размер был привязан к стадии, а не к уровню).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('аватар растёт при повышении уровня', (tester) async {
    // Крупный экран, чтобы вкладки и аватар целиком помещались.
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
    });

    final prefs = await SharedPreferences.getInstance();
    final wallet = WalletService(prefs);
    final pet = PetService(prefs, wallet);
    final tasks = TaskService(prefs, wallet, pet, const <Task>[]);
    final piggy = PiggyBankService(prefs, wallet, pet);
    final purchase = PurchaseService(wallet, pet);
    final feedback = FeedbackService();
    final period = PeriodService(prefs, wallet, pet);
    pet.spendReporter = period;
    piggy.spendReporter = period;
    purchase.spendReporter = period;
    final demo = DemoService(prefs, wallet, pet, tasks, piggy, period);

    pet.createPet('Муся', 'kitten');

    final app = MultiProvider(
      providers: [
        ChangeNotifierProvider<WalletService>.value(value: wallet),
        ChangeNotifierProvider<PetService>.value(value: pet),
        ChangeNotifierProvider<TaskService>.value(value: tasks),
        ChangeNotifierProvider<PiggyBankService>.value(value: piggy),
        ChangeNotifierProvider<PurchaseService>.value(value: purchase),
        ChangeNotifierProvider<FeedbackService>.value(value: feedback),
        ChangeNotifierProvider<PeriodService>.value(value: period),
        ChangeNotifierProvider<DemoService>.value(value: demo),
      ],
      child: const MaterialApp(home: HomeScreen()),
    );

    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    // Аватар — AnimatedContainer, внутри которого эмодзи стадии (котёнок: 🐱).
    final avatar = find.ancestor(
      of: find.text('🐱'),
      matching: find.byType(AnimatedContainer),
    );
    expect(avatar, findsOneWidget);
    final sizeAtLevel1 = tester.getSize(avatar);

    // 60 XP → уровень 2 → стадия «Ребёнок» (🐱 → 🐈) + sizeScale 0.68 → 0.93.
    pet.addXp(Pet.xpPerLevel);
    expect(pet.pet!.level, 2);
    // pumpAndSettle: доводим анимацию AnimatedContainer до конца.
    await tester.pumpAndSettle();

    // Ключевой сигнал роста: облик поменялся (мордочка → кошка).
    expect(find.text('🐱'), findsNothing);
    expect(find.text('🐈'), findsOneWidget);
    // Аватар и после смены эмодзи — тот же AnimatedContainer.
    final grownAvatar = find.ancestor(
      of: find.text('🐈'),
      matching: find.byType(AnimatedContainer),
    );
    expect(grownAvatar, findsOneWidget);
    final sizeAtLevel2 = tester.getSize(grownAvatar);
    expect(sizeAtLevel2.width, greaterThan(sizeAtLevel1.width));
    expect(sizeAtLevel2.height, greaterThan(sizeAtLevel1.height));

    // Размонтируем дерево и освободим сервисы: периодический таймер
    // PetService не должен «висеть» к концу теста.
    await tester.pumpWidget(const SizedBox());
    for (final service in [
      wallet,
      pet,
      tasks,
      piggy,
      purchase,
      feedback,
      period,
      demo,
    ]) {
      service.dispose();
    }
  });
}

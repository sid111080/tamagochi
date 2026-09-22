import 'package:financial_pet/core/models/budget.dart';
import 'package:financial_pet/core/services/feedback_service.dart';
import 'package:financial_pet/core/services/period_service.dart';
import 'package:financial_pet/core/services/pet_service.dart';
import 'package:financial_pet/core/services/wallet_service.dart';
import 'package:financial_pet/features/budget/budget_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Деревце с управляемым [isActiveTab]: эмулирует переключение вкладки
/// в IndexedStack, где State вью переживает перестроения (didUpdateWidget).
class _ToggleHost extends StatefulWidget {
  const _ToggleHost({
    required this.initial,
    required this.wallet,
    required this.pet,
    required this.feedback,
    required this.period,
  });

  final bool initial;
  final WalletService wallet;
  final PetService pet;
  final FeedbackService feedback;
  final PeriodService period;

  @override
  State<_ToggleHost> createState() => _ToggleHostState();
}

class _ToggleHostState extends State<_ToggleHost> {
  bool _active = false;

  @override
  void initState() {
    super.initState();
    _active = widget.initial;
  }

  void makeActive() => setState(() => _active = true);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<WalletService>.value(value: widget.wallet),
        ChangeNotifierProvider<PetService>.value(value: widget.pet),
        ChangeNotifierProvider<FeedbackService>.value(value: widget.feedback),
        ChangeNotifierProvider<PeriodService>.value(value: widget.period),
      ],
      child: MaterialApp(
        home: Scaffold(body: BudgetTab(isActiveTab: _active)),
      ),
    );
  }
}

/// Праздничный диалог сезона (ТЗ §8.10, полировка п.3).
///
/// Ключевое поведение: диалог показывается ровно один раз при завершении 5-го
/// периода (конец сезона) и ТОЛЬКО когда вкладка «Бюджет» реально видна.
/// В IndexedStack неактивные вкладки строятся в offstage-слое — там диалог
/// показываться не должен (иначе всплыл бы поверх другой вкладки).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  late WalletService wallet;
  late PetService pet;
  late FeedbackService feedback;
  late PeriodService period;

  Future<void> buildServices() async {
    final prefs = await SharedPreferences.getInstance();
    wallet = WalletService(prefs);
    pet = PetService(prefs, wallet);
    feedback = FeedbackService();
    period = PeriodService(prefs, wallet, pet);
    pet.spendReporter = period;
  }

  /// Доводим до состояния «период [targetIndex] завершён».
  void driveToFinished(int targetIndex) {
    while (period.period.index < targetIndex) {
      period
        ..confirmPlan(required: 1)
        ..finishPeriod()
        ..nextPeriod();
    }
    if (period.period.phase != PeriodPhase.finished) {
      period
        ..confirmPlan(required: 1)
        ..finishPeriod();
    }
  }

  /// Размонтировать и освободить сервисы (иначе периодический таймер
  /// PetService оставался бы «висячим» к концу теста).
  Future<void> cleanup(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    period.dispose();
    feedback.dispose();
    pet.dispose();
    wallet.dispose();
  }

  testWidgets('период 5 завершён, вкладка активна → праздничный диалог',
      (tester) async {
    await buildServices();
    pet.createPet('Муся', 'kitten');
    driveToFinished(5);
    expect(period.period.index, 5);
    expect(period.period.phase, PeriodPhase.finished);

    await tester.pumpWidget(_ToggleHost(
      initial: true,
      wallet: wallet,
      pet: pet,
      feedback: feedback,
      period: period,
    ));
    await tester.pumpAndSettle();

    // Диалог сезона показан.
    expect(find.text('Сезон 1 завершён!'), findsOneWidget);
    // «К нового сезона!» есть и на инлайн-кнопке (период 5), и в диалоге.
    expect(find.text('К новому сезону!'), findsNWidgets(2));

    // Тапаем по кнопке именно диалога: она открывает новый сезон.
    await tester.tap(
      find.descendant(
        of: find.byType(Dialog),
        matching: find.text('К новому сезону!'),
      ),
    );
    await tester.pumpAndSettle();
    expect(period.period.index, 1);
    expect(period.season, 2);
    expect(period.period.phase, PeriodPhase.planning);

    await cleanup(tester);
  });

  testWidgets('вкладка offstage → диалога нет; переключение → диалог',
      (tester) async {
    await buildServices();
    pet.createPet('Муся', 'kitten');
    driveToFinished(5);

    // Вкладка строится в offstage-слое (isActiveTab: false).
    await tester.pumpWidget(_ToggleHost(
      initial: false,
      wallet: wallet,
      pet: pet,
      feedback: feedback,
      period: period,
    ));
    await tester.pumpAndSettle();
    expect(find.text('Сезон 1 завершён!'), findsNothing);

    // Ребёнок переключается на вкладку «Бюджет» (State переживает,
    // isActiveTab: false → true). Диалог показывается.
    final host = tester.state<_ToggleHostState>(find.byType(_ToggleHost));
    host.makeActive();
    await tester.pumpAndSettle();
    expect(find.text('Сезон 1 завершён!'), findsOneWidget);

    await cleanup(tester);
  });

  testWidgets('периоды 1–4: диалог не показан даже на активной вкладке',
      (tester) async {
    await buildServices();
    pet.createPet('Муся', 'kitten');
    driveToFinished(3); // завершён 3-й период — не конец сезона.
    expect(period.period.index, 3);

    await tester.pumpWidget(_ToggleHost(
      initial: true,
      wallet: wallet,
      pet: pet,
      feedback: feedback,
      period: period,
    ));
    await tester.pumpAndSettle();

    expect(find.text('Сезон 1 завершён!'), findsNothing);
    // Инлайн-кнопка для не-сезонного периода — «Следующий период».
    expect(find.text('Следующий период'), findsOneWidget);

    await cleanup(tester);
  });
}

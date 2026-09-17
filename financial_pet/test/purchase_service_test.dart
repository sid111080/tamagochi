import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:financial_pet/core/services/period_service.dart';
import 'package:financial_pet/core/services/pet_service.dart';
import 'package:financial_pet/core/services/purchase_service.dart';
import 'package:financial_pet/core/services/wallet_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late WalletService wallet;
  late PetService pet;
  late PurchaseService purchase;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    wallet = WalletService(prefs);
    pet = PetService(prefs, wallet);
    pet.createPet('Муся', 'kitten');
    purchase = PurchaseService(wallet, pet);
  });

  tearDown(() {
    purchase.dispose();
    pet.dispose();
    wallet.dispose();
  });

  test('каталог: 8 товаров, 4 обязательных + 4 необязательных', () {
    expect(purchase.catalog, hasLength(8));
    expect(purchase.required, hasLength(4));
    expect(purchase.optional, hasLength(4));
    for (final p in purchase.catalog) {
      expect(p.id, isNotEmpty);
      expect(p.price, greaterThan(0));
    }
  });

  test('покупка: монеты списываются, эффект применяется к питомцу', () {
    final balanceBefore = wallet.balance; // 50
    pet.pet!.fun = 50; // понижаем, чтобы дельта не упёрлась в 100.

    final result = purchase.buy('bear'); // 28, веселье +25

    expect(result.success, isTrue);
    expect(result.message, contains('Медвежонок'));
    expect(wallet.balance, balanceBefore - 28);
    expect(pet.pet!.fun, 75);
  });

  test('не хватает средств: отказ с объяснением, баланс не уходит в минус', () {
    wallet.trySpend(wallet.balance, 'Обнуление', '💸'); // → 0
    expect(wallet.balance, 0);

    final result = purchase.buy('bear'); // 28

    expect(result.success, isFalse);
    expect(result.message, contains('Не хватает'));
    expect(wallet.balance, 0); // баланс не в минус
  });

  test('обязательный товар фиксируется в направлении «Обязательные»', () {
    final period = PeriodService(prefs, wallet, pet);
    purchase.spendReporter = period;
    period.confirmPlan(required: 20); // период → активная фаза.

    purchase.buy('feed'); // 15, required.

    expect(period.period.fact.required, 15);
    expect(period.period.fact.optional, 0);
  });

  test('необязательный товар фиксируется в направлении «Необязательные»', () {
    final period = PeriodService(prefs, wallet, pet);
    purchase.spendReporter = period;
    period.confirmPlan(required: 0, optional: 30);

    purchase.buy('bow'); // 18, optional.

    expect(period.period.fact.optional, 18);
    expect(period.period.fact.required, 0);
  });
}

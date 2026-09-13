import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:financial_pet/services/pet_service.dart';
import 'package:financial_pet/services/piggy_bank_service.dart';
import 'package:financial_pet/services/wallet_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late WalletService wallet;
  late PetService pet;
  late PiggyBankService piggy;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    wallet = WalletService(prefs);
    pet = PetService(prefs, wallet);
    pet.createPet('Муся', 'kitten');
    piggy = PiggyBankService(prefs, wallet, pet);
  });

  tearDown(() {
    piggy.dispose();
    pet.dispose();
    wallet.dispose();
  });

  test('создание цели: пустое имя и нулевая цель отклоняются', () {
    expect(piggy.addGoal('', '🎯', 100), isFalse);
    expect(piggy.addGoal('Велосипед', '🚲', 0), isFalse);
    expect(piggy.goals, isEmpty);
    expect(piggy.addGoal('Велосипед', '🚲', 100), isTrue);
    expect(piggy.goals, hasLength(1));
  });

  test('пополнение: монеты уходят из кошелька в цель', () {
    piggy.addGoal('Велосипед', '🚲', 100);
    final balanceBefore = wallet.balance;

    expect(piggy.saveToGoal(piggy.goals.first.id, 20), isTrue);

    expect(wallet.balance, balanceBefore - 20);
    expect(piggy.goals.first.saved, 20);
    expect(piggy.totalSaved, 20);
  });

  test('не хватает монет: пополнение не происходит', () {
    piggy.addGoal('Велосипед', '🚲', 100);
    wallet.trySpend(wallet.balance, 'Обнуление', '💸');

    expect(piggy.saveToGoal(piggy.goals.first.id, 5), isFalse);
    expect(piggy.goals.first.saved, 0);
  });

  test('переполнение обрезается до остатка до цели', () {
    piggy.addGoal('Велосипед', '🚲', 30);
    final balanceBefore = wallet.balance;

    expect(piggy.saveToGoal(piggy.goals.first.id, 50), isTrue);

    expect(piggy.goals.first.saved, 30);
    expect(wallet.balance, balanceBefore - 30);
  });

  test('достижение цели: опыт питомцу, награда одна', () {
    piggy.addGoal('Велосипед', '🚲', 30);
    final xpBefore = pet.pet!.totalXp;

    piggy.saveToGoal(piggy.goals.first.id, 30);
    expect(piggy.goals.first.isReached, isTrue);
    expect(pet.pet!.totalXp, xpBefore + goalReachedXp);

    // Цель достигнута — дальше копить нельзя, награда не дублируется.
    final xpAfter = pet.pet!.totalXp;
    expect(piggy.saveToGoal(piggy.goals.first.id, 5), isFalse);
    expect(pet.pet!.totalXp, xpAfter);
  });

  test('цели сохраняются: новый сервис видит накопления', () {
    piggy.addGoal('Велосипед', '🚲', 100);
    piggy.saveToGoal(piggy.goals.first.id, 10);

    piggy.dispose();
    piggy = PiggyBankService(prefs, wallet, pet);

    expect(piggy.goals, hasLength(1));
    expect(piggy.goals.first.saved, 10);
    expect(piggy.totalSaved, 10);
  });
}

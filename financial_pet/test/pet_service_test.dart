import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:financial_pet/services/pet_service.dart';
import 'package:financial_pet/services/wallet_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PetService petService;
  late WalletService walletService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    walletService = WalletService(prefs);
    petService = PetService(prefs, walletService);
  });

  tearDown(() {
    petService.dispose();
    walletService.dispose();
  });

  test('создание питомца: hasPet становится true', () {
    expect(petService.hasPet, isFalse);
    petService.createPet('Муся', 'kitten');
    expect(petService.hasPet, isTrue);
    expect(petService.pet!.name, 'Муся');
  });

  test('кормление: тратит монеты и даёт опыт', () {
    petService.createPet('Муся', 'kitten');
    final balanceBefore = walletService.balance;
    final xpBefore = petService.pet!.totalXp;

    petService.feed();

    expect(walletService.balance, balanceBefore - CareCosts.feed);
    expect(petService.pet!.totalXp, xpBefore + 5);
  });

  test('кормление при нехватке монет не тратит и не даёт опыт', () {
    petService.createPet('Муся', 'kitten');
    // Обнуляем баланс, чтобы забота была невозможна.
    walletService.trySpend(walletService.balance, 'Обнуление', '💸');
    final xpBefore = petService.pet!.totalXp;

    expect(petService.feed(), isFalse);
    expect(petService.pet!.totalXp, xpBefore);
  });

  test('опыт за задание может повысить уровень', () {
    petService.createPet('Муся', 'kitten');
    final levelBefore = petService.pet!.level;
    // 55 XP до порога 60, ещё 5 => уровень +1.
    petService.pet!.addXp(55);
    petService.addXpForTask(5);
    expect(petService.pet!.level, greaterThan(levelBefore));
    expect(petService.justLeveledUp, isTrue);
  });
}

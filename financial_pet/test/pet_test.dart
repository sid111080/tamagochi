import 'package:flutter_test/flutter_test.dart';

import 'package:financial_pet/core/models/growth_stage.dart';
import 'package:financial_pet/core/models/pet.dart';

void main() {
  group('Pet', () {
    test('старт: 1 уровень, стадия «Малыш»', () {
      final pet = Pet(id: 'p1', name: 'Муся', speciesId: 'kitten');
      expect(pet.level, 1);
      expect(pet.stage, GrowthStage.baby);
    });

    test('уровень растёт с опытом', () {
      final pet = Pet(id: 'p1', name: 'Муся', speciesId: 'kitten');
      pet.addXp(Pet.xpPerLevel * 2); // 120 XP
      expect(pet.level, 3);
      expect(pet.stage, GrowthStage.child);
    });

    group('sizeScale — видимый рост по уровню', () {
      test('растёт на 1→2 (баг: раньше размер не менялся)', () {
        final pet = Pet(id: 'p', name: 'x', speciesId: 'panda');
        final s1 = pet.sizeScale;
        pet.addXp(Pet.xpPerLevel); // → уровень 2
        expect(pet.level, 2);
        expect(pet.sizeScale, greaterThan(s1));
      });

      test('монотонен до потолка, затем стабилен', () {
        final pet = Pet(id: 'p', name: 'x', speciesId: 'panda');
        var prev = pet.sizeScale;
        for (var i = 0; i < 6; i++) {
          pet.addXp(Pet.xpPerLevel);
          expect(pet.sizeScale, greaterThan(prev));
          prev = pet.sizeScale;
        }
        // Дальше — потолок (взрослый): рост останавливается.
        pet.addXp(Pet.xpPerLevel * 3);
        expect(pet.sizeScale, lessThanOrEqualTo(1.40));
        expect(pet.sizeScale, prev);
      });
    });

    test('кормление повышает сытость и даёт опыт', () {
      final pet = Pet(
          id: 'p1', name: 'Муся', speciesId: 'kitten', hunger: 50);
      pet.feed();
      expect(pet.hunger, 90); // 50 + 40
      expect(pet.totalXp, 5);
    });

    test('настроение отражает средний статус', () {
      final happy = Pet(
          id: 'p',
          name: 'x',
          speciesId: 'kitten',
          hunger: 90,
          fun: 90,
          cleanliness: 90);
      expect(happy.mood, Mood.happy);

      final sad = Pet(
          id: 'p',
          name: 'x',
          speciesId: 'kitten',
          hunger: 10,
          fun: 10,
          cleanliness: 10);
      expect(sad.mood, Mood.sad);
    });

    test('спад статусов со временем', () {
      final pet = Pet(
          id: 'p',
          name: 'x',
          speciesId: 'kitten',
          hunger: 100,
          fun: 100,
          cleanliness: 100);
      pet.decay(const Duration(minutes: 10));
      expect(pet.hunger, lessThan(100));
      expect(pet.fun, lessThan(100));
      expect(pet.cleanliness, lessThan(100));
    });

    test('сериализация: круговой путь сохраняет состояние', () {
      final pet = Pet(
          id: 'p1', name: 'Муся', speciesId: 'kitten', hunger: 60, totalXp: 45);
      final restored = Pet.fromJson(pet.toJson());
      expect(restored.id, 'p1');
      expect(restored.name, 'Муся');
      expect(restored.hunger, 60);
      expect(restored.totalXp, 45);
    });
  });
}

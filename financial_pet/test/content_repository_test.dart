import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:financial_pet/core/models/task.dart';
import 'package:financial_pet/core/services/pet_service.dart';
import 'package:financial_pet/core/services/task_service.dart';
import 'package:financial_pet/core/services/wallet_service.dart';
import 'package:financial_pet/data/content/content_repository.dart';

/// Тест требования ТЗ §8.14: новое задание добавляется в JSON-контент
/// без изменения кода логики приложения.
///
/// [ContentRepository] отдаёт список заданий, а [TaskService] принимает
/// его через конструктор — сервис не знает о конкретных заданиях.
/// В unit-тесте asset-бандл недоступен, поэтому loader подменяется
/// строковым (тот же jsonDecode-путь, что и production).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late WalletService wallet;
  late PetService pet;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    wallet = WalletService(prefs);
    pet = PetService(prefs, wallet);
    pet.createPet('Муся', 'kitten');
  });

  tearDown(() {
    pet.dispose();
    wallet.dispose();
  });

  test('§8.14: задание, добавленное только в JSON, подхватывается сервисом',
      () async {
    // Контент «после правки»: старое задание + одно новое — код не меняли.
    final newJson = '''
[
  {
    "id": "task_01",
    "topic": "planning_budget",
    "title": "Старое задание",
    "scenario": "Ситуация",
    "competency_ref": "ref",
    "type": "choice",
    "options": [
      {
        "id": "a",
        "text": "вариант",
        "is_correct": true,
        "consequence_pet": "happy",
        "consequence_balance": 0,
        "explanation_correct": "молодец",
        "explanation_wrong": ""
      }
    ],
    "reward": 30,
    "min_age": 7,
    "max_age": 11,
    "difficulty": "easy"
  },
  {
    "id": "task_02",
    "topic": "savings",
    "title": "Новое задание",
    "scenario": "Другая ситуация",
    "competency_ref": "ref",
    "type": "choice",
    "options": [
      {
        "id": "a",
        "text": "вариант",
        "is_correct": true,
        "consequence_pet": "happy",
        "consequence_balance": 0,
        "explanation_correct": "молодец",
        "explanation_wrong": ""
      }
    ],
    "reward": 25,
    "min_age": 7,
    "max_age": 11,
    "difficulty": "easy"
  }
]
''';

    final repo = ContentRepository(loader: (path) async => newJson);
    final content = await repo.loadTasks();

    expect(content.map((t) => t.id), containsAll(['task_01', 'task_02']));

    // Демо-режим: все задания из контента доступны сразу (без ротации) —
    // новое задание подхватывается без единой строки изменённого кода.
    final tasks = TaskService(prefs, wallet, pet, content)
      ..setDemoAll(true);
    expect(tasks.availableTasks.map((t) => t.id),
        containsAll(['task_01', 'task_02']));
    expect(tasks.availableTasks, hasLength(2));
  });

  test('битый объект в JSON отбрасывается, валидные остаются', () async {
    final json = '''
[
  {
    "id": "",
    "options": []
  },
  {
    "id": "task_ok",
    "topic": "payments",
    "title": "Валидное",
    "scenario": "Ситуация",
    "competency_ref": "ref",
    "type": "choice",
    "options": [
      {
        "id": "a",
        "text": "вариант",
        "is_correct": true,
        "consequence_pet": "neutral",
        "consequence_balance": 0,
        "explanation_correct": "хорошо",
        "explanation_wrong": ""
      }
    ],
    "reward": 20,
    "min_age": 7,
    "max_age": 11,
    "difficulty": "easy"
  }
]
''';

    final repo = ContentRepository(loader: (path) async => json);
    final content = await repo.loadTasks();

    expect(content.map((t) => t.id), ['task_ok']);
    // Тема и награда читаются из JSON.
    expect(content.first.topic, TaskTopic.payments);
    expect(content.first.reward, 20);
  });
}

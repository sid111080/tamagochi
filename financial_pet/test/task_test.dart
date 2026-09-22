import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:financial_pet/core/models/task.dart';
import 'package:financial_pet/data/content/content_repository.dart';

/// Собирает задание из JSON (удобно для тестов модели).
Task _task(Map<String, dynamic> json) => Task.fromJson(json);

Map<String, dynamic> _option(
  String id, {
  bool isCorrect = false,
  String pet = 'happy',
  int balance = 0,
  String ok = 'ok-explanation',
  String wrong = 'wrong-explanation',
}) =>
    {
      'id': id,
      'text': 'Вариант $id',
      'is_correct': isCorrect,
      'consequence_pet': pet,
      'consequence_balance': balance,
      'explanation_correct': ok,
      'explanation_wrong': wrong,
    };

Map<String, dynamic> _taskJson(String id, String topic) => {
      'id': id,
      'topic': topic,
      'title': 'Задание $id',
      'scenario': 'Ситуация $id',
      'competency_ref': 'ref $id',
      'type': 'choice',
      'options': [
        _option('a', isCorrect: true),
        _option('b', isCorrect: false, pet: 'sad'),
      ],
      'reward': 30,
      'min_age': 7,
      'max_age': 11,
      'difficulty': 'easy',
    };

void main() {
  group('Топик', () {
    test('json-имена соответствуют ТЗ', () {
      expect(TaskTopic.planningBudget.jsonName, 'planning_budget');
      expect(TaskTopic.savings.jsonName, 'savings');
      expect(TaskTopic.payments.jsonName, 'payments');
    });

    test('parse: неизвестная тема → по умолчанию', () {
      expect(TaskTopicX.parse('savings'), TaskTopic.savings);
      expect(TaskTopicX.parse('planning_budget'), TaskTopic.planningBudget);
      expect(TaskTopicX.parse('??'), TaskTopic.planningBudget);
      expect(TaskTopicX.parse(null), TaskTopic.planningBudget);
    });
  });

  group('Сложность / последствие', () {
    test('difficulty: неизвестная → easy', () {
      expect(TaskDifficultyX.parse('medium'), TaskDifficulty.medium);
      expect(TaskDifficultyX.parse('hard'), TaskDifficulty.easy);
      expect(TaskDifficultyX.parse(null), TaskDifficulty.easy);
    });

    test('pet consequence: неизвестное → neutral', () {
      expect(PetConsequenceX.parse('happy'), PetConsequence.happy);
      expect(PetConsequenceX.parse('sad'), PetConsequence.sad);
      expect(PetConsequenceX.parse('bogus'), PetConsequence.neutral);
    });
  });

  group('Task.fromJson', () {
    test('парсит все поля', () {
      final t = _task(_taskJson('x', 'savings'));
      expect(t.id, 'x');
      expect(t.topic, TaskTopic.savings);
      expect(t.title, 'Задание x');
      expect(t.scenario, 'Ситуация x');
      expect(t.competencyRef, 'ref x');
      expect(t.type, TaskType.choice);
      expect(t.options, hasLength(2));
      expect(t.reward, 30);
      expect(t.minAge, 7);
      expect(t.maxAge, 11);
      expect(t.difficulty, TaskDifficulty.easy);
    });

    test('optionById находит нужный вариант', () {
      final t = _task(_taskJson('x', 'payments'));
      expect(t.optionById('a')?.isCorrect, isTrue);
      expect(t.optionById('b')?.isCorrect, isFalse);
      expect(t.optionById('zzz'), isNull);
    });

    test('hasCorrectOption: есть хотя бы один верный', () {
      expect(_task(_taskJson('x', 'savings')).hasCorrectOption, isTrue);
      final noCorrect = _task(_taskJson('y', 'savings')
        ..['options'] = [
          _option('a', isCorrect: false),
        ]);
      expect(noCorrect.hasCorrectOption, isFalse);
    });

    test('пояснение зависит от правильности варианта', () {
      final t = _task(_taskJson('x', 'savings'));
      expect(t.optionById('a')!.explanation, 'ok-explanation');
      expect(t.optionById('b')!.explanation, 'wrong-explanation');
    });

    test('round-trip json', () {
      final t = _task(_taskJson('x', 'planning_budget'));
      final restored = Task.fromJson(t.toJson());
      expect(restored.id, t.id);
      expect(restored.topic, t.topic);
      expect(restored.options, hasLength(2));
      expect(restored.options.first.isCorrect, isTrue);
    });
  });

  group('Контент из assets (ТЗ §8.14)', () {
    test('10 заданий, 3 темы, у каждого есть верный вариант', () async {
      final raw = await File('assets/content/tasks.json').readAsString();
      final tasks = (jsonDecode(raw) as List)
          .map((e) => Task.fromJson(e as Map<String, dynamic>))
          .toList();
      expect(tasks, hasLength(10));
      expect(tasks.map((t) => t.topic).toSet(), hasLength(3));
      // Choice-задания: каждый вариант имеет пояснение (ТЗ §8.8).
      expect(
        tasks
            .where((t) => t.type == TaskType.choice)
            .every((t) => t.options.every((o) => o.explanation.isNotEmpty)),
        isTrue,
      );
      // Sequence-задания: есть элементы и правильный порядок.
      final seqTasks = tasks.where((t) => t.type == TaskType.sequence).toList();
      expect(seqTasks, isNotEmpty);
      for (final t in seqTasks) {
        expect(t.sequenceItems, isNotEmpty);
        expect(t.correctOrder, hasLength(t.sequenceItems.length));
      }
    });

    test('ContentRepository: подгружает через инъекцию loader', () async {
      final raw = await File('assets/content/tasks.json').readAsString();
      final repo = ContentRepository(
        loader: (path) async => raw,
      );
      final tasks = await repo.loadTasks();
      expect(tasks, hasLength(10));
    });
  });
}

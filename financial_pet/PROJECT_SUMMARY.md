# Project Summary

## Overall Goal
Build **"ФинПитомец" (Financial Pet)** — an offline Flutter mobile app teaching financial literacy to kids (7–11) in Moscow, for RuStore (Android). Guided by `QWEN.md` (full ТЗ: 4-layer architecture, budget/purchases/savings/periods/adult/demo, Приложение А) and `fg_competencies.md` (competencies for the 3 topics + quiz JSON format).

## Key Knowledge

### Conventions (QWEN.md)
- UI text + comments in **Russian**, code identifiers in **English**.
- Offline only — no API/analytics/ads; no child PII, no real money, no accounts (guest mode).
- **Stack: provider + shared_preferences** (user chose this; do NOT migrate to BLoC/Hive without re-request). QWEN.md recommends BLoC+Hive+go_router+freezed but the working prototype stays provider-based.
- Accessibility: ≥48dp targets, ≥16sp text, color never the only signal, confirm destructive actions.
- "Safe mistake" principle: a bad choice creates a task (retry / fix budget), never zeroes progress, never scares/shames.

### Tech / environment
- Dir: `/Users/alexander/tamagochi/financial_pet`. **Git root = parent `/Users/alexander/tamagochi`** (no nested `.git`). Android `applicationId`: `ru.rustore.financial_pet`; Android-only (no `ios/`).
- Flutter Dart 3.x (uses `withValues(alpha:)`, `CardThemeData`, Material 3). Deps: provider, shared_preferences, intl, fl_chart ^0.70.2, flutter_launcher_icons.
- Verify: `flutter analyze` + `flutter test` from project dir. **CURRENT STATE: 45 tests pass, analyze clean, `flutter build apk` succeeds** (asset `assets/content/tasks.json` bundles).
- Device: `emulator-5554` (AVD Pixel_10a); `adb` via `~/Library/Android/sdk/platform-tools/adb`.

### fl_chart 0.70 gotchas
- `BarChart(data, duration:)` — **data is positional** (no `data:` named param).
- No `List.takeLast` in this SDK — slice with `sublist`.
- `BarChartGroupData` has **no `showTooltips`** in 0.70.

### Architecture — 4-layer (this session; ТЗ §4, §13)
`lib/` → `app/theme.dart` + `core/{models,services}` + `data/content` + `features/{onboarding,pet_creation,home,tasks}` + `widgets/`.

- **core/models/**: `Pet`, `Wallet`+`CoinTransaction`, `PetSpecies`, `GrowthStage`, `StreakBadge`, `PiggyBankGoal`, **`Task` (quiz format)** + `TaskOption`. Enums: `TaskTopic` (planning_budget|savings|payments), `TaskType` (choice), `TaskDifficulty` (easy|medium), `PetConsequence` (happy|neutral|sad). All enum `parse()` return **non-nullable** with defaults. `Task` is content-only; runtime state lives in the service.
  - `firstWhereOrNull` is a **local top-level helper** in task.dart (Dart core `Iterable` has `firstOrNull` but NOT `firstWhereOrNull`).
- **core/services/** (ChangeNotifier + SharedPreferences, `main.dart` order): `WalletService(prefs)` → `PetService(prefs, wallet)` → `TaskService(prefs, wallet, pet, content)` → `PiggyBankService(prefs, wallet, pet)`.
  - `TaskService` (quiz): injectable `clock`. Storage key `quiz_tasks_v1` = `{day, ids, streak, maxStreak, lastStreakDay, completed{}}`. Rotates **3/day** from the content pool, seeded `Random(int.parse(dayKey))` ("приходи завтра" is true). `answer(taskId, optionId) → QuizResult?`: correct → reward (coins) + `quizXp=20` + pet `reactToQuiz(happy)` + completed + streak; wrong → no reward + pet sad + retryable. `resetProgress()` for demo/reset.
  - `PetService` gained `reactToQuiz(moodDelta)` (happy +15 / neutral 0 / sad −15 to fun & hunger) — separates pet from the Task model.
- **data/content/**: `ContentRepository` (const ctor; `loadTasks()` via `rootBundle`; injectable `loader` for tests) → `assets/content/tasks.json` = **9 quiz tasks (3/topic: planning_budget, savings, payments), 27 options**, exactly per fg_competencies.md format.
- **features/**: `onboarding/splash_screen.dart`, `pet_creation/create_pet_screen.dart` (5 species, 9+ combos, name), `home/home_screen.dart` (3 tabs: Питомец / `TasksTab` / Кошелёк, `IndexedStack`), `tasks/{TasksTab, QuizScreen, QuizTaskCard}.dart`.
- **Quiz UI**: `QuizScreen` = scenario → options → feedback panel (pet reaction emoji + explanation + reward on correct; "Попробовать ещё" on wrong, disables tried-wrong options).
- **Removed this session**: old `lib/widgets/task_card.dart` + activity-task `TaskPool` (12 daily + 6 weekly) — replaced by the quiz system.
- Mechanics: `xpPerLevel 60`; quiz reward = content `reward` (coins) + 20 XP; wallet starts 50; daily streak 🔥 + badges 3/7/30 (by maxStreak) retained; piggy bank (goals, save 5/10/20, +20 XP on reach) retained.

## What's still TODO (ТЗ, not yet built)
- **Игровые периоды** (5 sequential, plan-vs-fact) — no period system yet.
- **План бюджета** (3 directions: обязательные/необязательные/накопления, остаток) — the ТЗ §8.5 core, absent.
- **Покупки** (8 positions, 2 types, price/category/effect, history) — only 3 care actions exist.
- **Финансовые цели** (3 predefined with cost) — piggy bank has user-created goals only.
- **Развитие питомца** (3 stages by decisions over periods) — currently XP/level only.
- **Раздел для взрослого** (barrier, progress, reset/delete), **демо-режим**, **онбординг** (3 decision types), **история + глоссарий**.
- 9 pet combos / 3 stages — 5 species × 4 growth stages exist (meets ≥9).

## Device-testing notes (model can't view images)
- Drive UI via `adb -s emulator-5554 shell uiautomator dump /sdcard/ui.xml` → `shell cat` → split single-line XML with `tr '>' '\n'`; Flutter text often empty, use `content-desc`+bounds; tap `adb shell input tap X Y` at center.
- If app process dead: `adb shell monkey -p ru.rustore.financial_pet -c android.intent.category.LAUNCHER 1`.
- Cyrillic input untested (`adb shell input text "Велосипед"`); goal creation requires a text field.
- Watch `adb logcat` for `EXCEPTION` (esp. fl_chart on wallet tab).

## Git
- **Do NOT commit without asking** (user previously declined commit; git-tracking anomaly in parent repo uninvestigated). If committing, stage only project paths — never `.DS_Store`/`.qwen`.

---

## Summary Metadata
**Update time**: 2026-09-15 (post 4-layer refactor + quiz task system; 45 tests, analyze clean, APK builds)

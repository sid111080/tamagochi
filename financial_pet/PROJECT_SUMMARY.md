# Project Summary

## Overall Goal
Build **"ФинПитомец" (Financial Pet)** — an offline Flutter mobile app teaching financial literacy to kids/youth (7–14) in Moscow via a virtual pet, for RuStore (Android), then verify the new task/piggy-bank/earnings features work end-to-end on a device (Pixel 10a emulator).

## Key Knowledge

### Language & conventions (from QWEN.md)
- **UI text and code comments in Russian; code identifiers in English.**
- No external API calls, no analytics, no ads — fully offline.
- QWEN.md *recommends* BLoC+Hive+go_router+freezed, but **user explicitly chose to keep the existing stack: provider + shared_preferences**. Do NOT migrate unless user re-requests.

### Tech / environment
- Project dir: `/Users/alexander/tamagochi/financial_pet`. **Git root is the PARENT `/Users/alexander/tamagochi`**. Android `applicationId`: `ru.rustore.financial_pet`. Android-only (no `ios/`).
- SDK: Flutter (Dart 3.x, uses `withValues(alpha:)`, `CardThemeData`, Material 3); deps: provider, shared_preferences, intl, **fl_chart 0.70.2** (resolves from `^0.67.0`).
- `adb` is NOT on PATH — use `~/Library/Android/sdk/platform-tools/adb`.
- Device: **`emulator-5554` (AVD `Pixel_10a`)** — this is the "device" to test on. Verify: `~/Library/Android/sdk/platform-tools/adb devices`.
- Verify: `flutter analyze && flutter test` (both run from project dir). **Currently 43 tests pass, analyze clean.**

### fl_chart 0.70 API gotchas (learned the hard way)
- `BarChart(data, duration: ...)` — **data is a positional argument** (`data:` named param does NOT exist).
- `List.takeLast` is not available in this SDK — slice manually with `sublist`.
- `BarChartGroupData` has **no `showTooltips`** param in 0.70.

### Architecture (provider-based, all services `ChangeNotifier` + SharedPreferences)
- **Models** (`lib/models/`): `Pet`, `Wallet`+`CoinTransaction` (amount>0=income, <0=spend, max 40 tx stored), `Task`+`TaskPool`, `PetSpecies`, `GrowthStage`, **NEW `StreakBadge`** (3/7/30 days, `isEarned(maxStreak)`), **NEW `PiggyBankGoal`** (id/title/emoji/target/saved/rewarded, `isReached`, `progress`).
- **Services** (`lib/services/`), dependency order in `lib/main.dart`: `WalletService(prefs)` → `PetService(prefs, wallet)` → `TaskService(prefs, wallet, pet)` → **`PiggyBankService(prefs, wallet, pet)`**.
  - `TaskService`: injectable `DateTime Function() clock = DateTime.now` (tests override by reassigning a shared `now` var). Rotation: `tasks_v2` storage `{day, week, ids, streak, maxStreak, lastStreakDay, completed{}}`; 3 daily + 2 weekly per period, seeded `Random(int.parse(dayKey))`; v1 migration; history pruned to 30 days.
  - `PetService.addXp(amount)` (generic) with `addXpForTask` delegating to it.
  - `PiggyBankService`: `piggy_bank_v1` storage; `addGoal(title, emoji, target)`, `saveToGoal(id, amount)` (clamps to remaining, `wallet.trySpend`), `goalReachedXp = 20` granted once.
- **UI** (`lib/screens/home_screen.dart`): 3 bottom tabs — Питомец / Задания / Кошелёк (`IndexedStack`).
  - Tasks tab: header row (Доступно: N + 🔥 streak chip), `_StreakBadgesRow`, `TaskCard`s, `_EmptyTasks` ("Все задания выполнены! Возвращайся завтра за новыми."), completion via `_confirmComplete` dialog (buttons: **"Да, выполнил(а)!"** / **"Пока нет"**).
  - Wallet tab: balance card, `EarningsChart` (`lib/widgets/earnings_chart.dart` — 7-day bars + `dailyIncomes()` + `EmptyChartHint`), piggy bank goals (`_GoalCard`, button **"Копить"** → dialog 5/10/20), **"Новая цель"** → `_AddGoalDialog` (TextField "На что копишь?", emoji chips 🎯🚲🎮🧸🛴📚, target chips 50/100/200, button **"Создать"** disabled when title empty).
  - Care buttons on pet tab: Кормить(15) / Играть(10) / Мыть(10).
- **Top-level helper `SnackBar _snack(String)`** in home_screen.dart (moved out of `_TasksTab` after define-before-use errors).
- Mechanics: xpPerLevel 60; daily tasks easy 15/25, medium 20/30, hard 25/35; weekly 30–40 / 40–50; wallet starts 50.

### Device-testing notes (this model can't view images)
- Drive UI via **`adb -s emulator-5554 shell uiautomator dump /sdcard/ui.xml`** then `adb -s emulator-5554 shell cat /sdcard/ui.xml` and extract bounds (single-line XML — split with `tr '>' '\n'`, look for `text="..." clickable="true"` and `bounds=[x1,y1][x2,y2]`), tap with `adb shell input tap X Y` at center.
- `flutter run` debug session died (Dart VM service websocket error) but app process may still be alive (PID 17707); check with `adb shell pidof ru.rustore.financial_pet`; if dead, start via `adb shell monkey -p ru.rustore.financial_pet -c android.intent.category.LAUNCHER 1`.
- Cyrillic input untested: try `adb -s emulator-5554 shell input text "Велосипед"`; fallback needed if it mangles (text field is required for goal creation).
- Watch for crashes: `adb -s emulator-5554 logcat` / flutter log for `EXCEPTION` (esp. fl_chart on wallet tab).

### Git (do NOT commit without asking)
- Earlier the user **denied/cancelled** investigation of why the parent repo doesn't list `lib/`/`test/` changes (suspected nested `.git` in `financial_pet`). Never commit until user clarifies; if committing, stage only project paths, never `.DS_Store`/`.qwen`.

## Recent Actions
1. **[DONE]** MVP task system (prior turn, user approved): pool 12 daily + 6 weekly, 3+2/day seeded rotation, difficulty 🌱/🌿/🌳, confirmation dialog, daily streak 🔥. 35 tests.
2. **[DONE]** This session (user: "давай вот это сделай…"):
   - `lib/models/streak_badge.dart` (3/7/30, 🥉🥈🥇); `TaskService` gained `maxStreak` (persisted, badge basis) + load/save of `maxStreak`.
   - `lib/models/piggy_bank_goal.dart` + `lib/services/piggy_bank_service.dart`; wired into `main.dart`.
   - `PetService.addXp()` added (used by piggy-bank goal reward).
   - `lib/widgets/earnings_chart.dart`: `EarningsChart` (fl_chart bars, weekday labels from real dates) + `dailyIncomes()` + `EmptyChartHint`.
   - `home_screen.dart`: 3rd tab Кошелёк (balance, chart, piggy bank), `_StreakBadgesRow` in tasks tab, `_GoalCard`, `_openSaveGoal`/`_openAddGoal` dialogs, top-level `_snack`.
   - Tests: new `test/piggy_bank_service_test.dart` (6 tests), 2 new streak/badge tests in `task_service_test.dart`, 3 new pool tests in `task_test.dart` → **43 tests pass, analyze clean**.
   - `TODO.md` updated to reflect current state.
3. **[DONE]** Build: `flutter build apk --debug` → `build/app/outputs/flutter-apk/app-debug.apk` (exit 0).
4. **[DONE]** Started emulator Pixel_10a (`emulator-5554`, boot completed); a second `emulator` launch attempt failed (duplicate AVD lock) — the original emulator instance is what's running, **leave it alone**.
5. **[DONE]** Installed APK via `adb -s emulator-5554 install -r build/app/outputs/flutter-apk/app-debug.apk` (Success); `flutter run -d emulator-5554` launched app (PID 17707, "flutter loaded normally") but then its VM-service connection died (exit 2, benign for a plain tap-test).
6. **[IN PROGRESS]** UI walk-through: first `uiautomator dump` on the (fresh-install) screen returned only `text=""` (likely the Create-pet splash — Flutter text nodes often surface with empty `text` attr; the dump may need `shell cat` parsing of `content-desc`/bounds, or the app may be on the species-picker step).

## Current Plan
1. **[TODO]** Confirm app is alive: `adb -s emulator-5554 shell pidof ru.rustore.financial_pet`; if dead, relaunch via `adb shell monkey -p ru.rustore.financial_pet -c android.intent.category.LAUNCHER 1`.
2. **[TODO]** Parse `uiautomator dump` properly (dump is single-line XML; split with `tr '>' '\n'`; also look at `content-desc` since Flutter text may be empty there) to identify the current screen (expected: pet-creation splash) and find tappable elements/bounds.
3. **[TODO]** Tap-test the requested flow: create pet (name may be skippable — default "Питомец") → tab **Задания**: for each available card tap "Выполнить" then "Да, выполнил(а)!" (5 times, 3 daily + 2 weekly; note weekly reward buttons) → expect "Все задания выполнены! Возвращайся завтра…" + 🔥1 streak + first badge row; watch `logcat` for exceptions.
4. **[TODO]** Tab **Кошелёк**: balance, earnings chart (check no fl_chart crash), create a goal ("Новая цель" — try `input text` for Cyrillic; emoji/target chips preselected by default; "Создать"), tap "Копить" → 10 → verify progress + "В копилку +10" toast; try saving until goal reached to see "Цель достигнута! +20 XP".
5. **[TODO]** Report results in Russian (what worked, any overflow/crash findings, fix any found, re-verify with analyze/tests).
6. **[TODO, needs user OK]** Commit question is still open (git-tracking anomaly in `tamagochi` root; user denied investigating it before) — re-ask before any commit.

---

## Summary Metadata
**Update time**: 2026-09-13T21:03:53.271Z

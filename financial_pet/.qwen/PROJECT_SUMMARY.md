# Project Summary

## Overall Goal
Build **"Финансовый питомец" (Financial Pet)** — an offline Flutter Android app for RuStore that teaches children/youth (7–11, Moscow) financial literacy via a virtual pet whose development depends on the player's financial decisions (budgeting, spending, saving).

## Key Knowledge

### Technology & Conventions
- **Real stack: `provider` + `shared_preferences`** (ChangeNotifier services). This is NOT the BLoC + Hive + go_router + freezed that `QWEN.md` "recommends." **Do not migrate to BLoC/Hive without explicit request** — it would be a rewrite the user hasn't asked for. Follow the existing `ChangeNotifier`-service pattern.
- **Language:** All UI text + code comments in **Russian**; code identifiers in **English**.
- **Constraints (ТЗ):** fully offline (no API/analytics/ads), no real money, no child PII, guest mode (no registration), no scary/shaming mechanics ("safe mistake" — a bad choice creates a fix task, never zeroes progress), accessibility ≥48dp targets / ≥16sp text, color never the only signal.

### Environment & Build
- Working dir: `/Users/alexander/tamagochi/financial_pet`. **Git root is the PARENT** `/Users/alexander/tamagochi` (financial_pet is a subdir; paths appear as `financial_pet/lib/...`).
- **Verify with:** `flutter analyze` (must be clean) + `flutter test` from project dir.
- User is on a MacBook Pro (Homebrew Python 3.14) — use project venv for pip, not `--break-system-packages` (only relevant if Python tasks arise).
- No device currently connected (`flutter devices` → none found); APK builds work headless.
- `fl_chart 0.70.2` gotchas: `BarChart(data, duration:)` data is **positional**; `BarChartGroupData` has **no `showTooltips`**; no `List.takeLast` in this SDK (use `sublist`). Colors use `.withValues(alpha:)` (Dart 3.x / Material 3).

### Git Discipline
- **Commit only project paths** (`lib/`, `test/`). Do **NOT** stage parent-repo files: `../.DS_Store`, `../.qwen/settings.json`, `../Documents/`.
- User commits in **Russian**; recent messages are terse ("Новые доработки 2", etc.).
- `budget.dart`, `period_service.dart`, `budget_tab.dart`, `period_service_test.dart` were **already committed** in a prior commit (clean vs HEAD) — confirmed the `_openNextPeriod` fix was in the committed version.

### Architecture (4 layers)
- `lib/core/models/`: `Pet` (hunger/fun/cleanliness 0..100; `level = 1 + totalXp/60`; mood = avg of 3 statuses), `Wallet` (start 50; no negative balance; `CoinTransaction`), `PetSpecies` (5 species × 4 stages), `StreakBadge`, `PiggyBankGoal`, `Task`+`TaskOption` (quiz), `budget.dart` (`BudgetDirection`[required/optional/savings], `FinancialStage`[beginner/confident/master; `fromPoints`: ≥10 master, ≥5 confident], `BudgetAmounts`, `PeriodPhase`[planning/active/finished], `PeriodResult`, `Period`, `SpendReporter` interface).
- `lib/core/services/` (created in `main.dart` in this order): `WalletService` → `PetService` → `TaskService` → `PiggyBankService` → `PeriodService` (sets itself as `spendReporter` on Pet+Piggy) → `DemoService` (last, orchestrates all).
- `CareCosts`: feed=15, play=10, wash=10 coins, +5 XP each.
- `lib/features/`: `onboarding/splash_screen`, `pet_creation/create_pet_screen`, `home/home_screen` (4 tabs), `budget/budget_tab`, `tasks/{tasks_tab,quiz_screen,quiz_task_card}`.

## Recent Actions

1. **Wired the «Бюджет» tab** into `home_screen.dart` (was imported but unused). Now 4 tabs: Питомец / Бюджет / Задания / Кошелёк (`IndexedStack` + `BottomNavigationBar`, icon `pie_chart`).
2. **Period engine tests + bug fix** (`test/period_service_test.dart`, 19 tests): caught & fixed `PeriodService._openNextPeriod` — it always reopened period 1 because `finishPeriod` never incremented `_seasonPeriod`. Fixed to `_seasonPeriod = (_period.index % periodsPerSeason) + 1` (5→1, else +1).
3. **Built Demo Mode (ТЗ §8.13)** — the main work of the session:
   - Added `reset()` to `WalletService` (balance→50, clear txns), `removePet()` + `demoMode` flag (skip time-decay) to `PetService`, `reset()` to `PiggyBankService`.
   - `TaskService`: added `_demoAll` flag, `setDemoAll(bool)`, `allTasksAvailable` getter; `availableTasks`/`completedTasks`/`_isAvailable` return **all content** in demo (no daily rotation, answered = closed until reset).
   - **New `DemoService`** (ChangeNotifier): `isDemo` persisted in prefs; `enterDemo()` (test profile: pet «Муся»/kitten, 50 coins, all tasks, empty piggy, period 1), `resetDemo()` (re-seed, stay in demo), `exitDemo()` (clean slate, no pet). Re-applies demo flags on app load.
   - UI: «🎬 Демо-режим» button on `splash_screen` (with `_navigated` double-nav guard); «Демо» chip in Home header → dialog (Начать заново / Выйти → `CreatePetScreen`).
   - **New `test/demo_service_test.dart`** (5 tests).
4. **Verification:** `flutter analyze` clean, `flutter test` → **69/69 pass** (was 64).
5. **Committed** `da18e00` "Демо-режим (ТЗ §8.13): тестовый профиль" (9 files, +481).
6. **Built debug APK** `build/app/outputs/flutter-apk/app-debug.apk` (162 MB) — succeeded, exit 0.
7. User chose **"Сначала проверю демо"** (verify the demo on device first) before the adult section.

## Current Plan

1. [DONE] Demo mode — built, tested (69 green), committed (`da18e00`), debug APK built.
2. [IN PROGRESS] **User verifying demo on device** — waiting for their verdict (checks: demo button→Home, all 9 tasks, budget plan→period→finish, demo chip reset/exit, Кошелёк fl_chart layout).
3. [TODO] **Раздел для взрослого** (ТЗ §8.12) — next feature after demo confirmed: barrier (long-press / arithmetic), visible app goals/topics/progress (no negative judgment of child), reset/delete local profile.
4. [TODO] **Онбординг** (ТЗ §8.1) — 3-decision-types intro (обязательное / желаемое / отложить) + guest-mode welcome.

**Next turn:** await user's device-test feedback on the demo. If it passes, start the adult section. If something broke, diagnose (watch for fl_chart overflow, which caused a prior "OVERFLOWED BY 30 PIXELS" bug).

---

## Summary Metadata
**Update time**: 2026-09-16T18:48:45.205Z

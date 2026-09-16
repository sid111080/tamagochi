# Project Summary

## Overall Goal
Build **"ФинПитомец" (Financial Pet)** — an offline Flutter mobile app teaching financial literacy to kids (7–11) in Moscow, for RuStore (Android). Guided by `QWEN.md` (full ТЗ: 4-layer architecture, budget/purchases/savings/periods/adult/demo, Приложение А) and `fg_competencies.md` (competencies for the 3 topics + quiz JSON format).

## Key Knowledge

### Conventions (QWEN.md)
- UI text + comments in **Russian**, code identifiers in **English**.
- Offline only — no API/analytics/ads; no child PII, no real money, no accounts (guest mode).
- **Stack: provider + shared_preferences** (user's working prototype; do NOT migrate to BLoC/Hive/go_router/freezed without explicit request, despite QWEN.md recommending them). Services are `ChangeNotifier` + SharedPreferences persistence.
- Accessibility: ≥48dp targets, ≥16sp text, color never the only signal, confirm destructive actions.
- "Safe mistake" principle: a bad choice creates a task (retry / fix budget), never zeroes progress, never scares/shames.

### Tech / environment
- Dir: `/Users/alexander/tamagochi/financial_pet`. **Git root = parent `/Users/alexander/tamagochi`** (financial_pet files show up under it; there's a git-tracking anomaly — user said do NOT commit without asking; never stage `.DS_Store`/`.qwen`). Android `applicationId`: `ru.rustore.financial_pet`; Android-only (no `ios/`).
- Flutter Dart 3.x (uses `withValues(alpha:)`, Material 3). Deps: provider, shared_preferences, intl, fl_chart ^0.70.2, flutter_launcher_icons.
- Verify: `flutter analyze` + `flutter test` from project dir. **CURRENT STATE: 64 tests pass, analyze clean.**
- Device: `emulator-5554` (AVD Pixel_10a); `adb` via `~/Library/Android/sdk/platform-tools/adb`.

### fl_chart 0.70 gotchas
- `BarChart(data, duration:)` — **data is positional** (no `data:` named param).
- No `List.takeLast` in this SDK — slice with `sublist`.
- `BarChartGroupData` has **no `showTooltips`** in 0.70.

### Architecture — 4-layer
`lib/` → `app/theme.dart` + `core/{models,services}` + `data/content` + `features/{onboarding,pet_creation,home,tasks,budget}` + `widgets/`.

- **core/models/**: `Pet` (3 statuses 0..100, XP 60/level, mood = avg of statuses), `Wallet`+`CoinTransaction` (start 50, no negative balance), `PetSpecies` (5 species × 4 growth stages = 20 combos ≥9), `StreakBadge`, `PiggyBankGoal`, `Task` (quiz) + `TaskOption`, **`budget.dart`** (new this session: `BudgetDirection` [required/optional/savings], `FinancialStage` [beginner/confident/master, fromPoints: ≥10/≥5/else], `BudgetAmounts`, `PeriodPhase` [planning/active/finished], `PeriodResult`, `Period`, `SpendReporter` interface).
- **core/services/** (constructor order in main.dart): `WalletService(prefs)` → `PetService(prefs, wallet)` → `TaskService(prefs, wallet, pet, content)` → `PiggyBankService(prefs, wallet, pet)` → **`PeriodService(prefs, wallet, pet)` (last)** — registers itself as `spendReporter` on PetService + PiggyBankService (nullable fields, backward-compatible).
  - `PeriodService`: season of 5 periods, phase machine. `confirmPlan(r,o,s)` — clamps, rejects if total > wallet.balance, snapshot budget, → active. `reportSpend(direction, amount)` — only in active phase, accumulates into `period.fact` (does NOT deduct wallet — deduction happens in feed()/saveToGoal()). `finishPeriod()` → 3 criteria (required fact>0; fact.optional ≤ plan.optional; savings: plan==0 ? fact>0 : fact≥plan), score 0..3 → moodDelta +15/+5/0/−10 → `pet.applyPeriodResult` (hunger+Δ, fun+Δ, cleanliness+Δ·0.6, clamped — reversible), phase → finished. `nextPeriod()` → `_openNextPeriod` computes `index % 5 + 1` (FIXED this session), fresh Period in planning. `reset()` for demo/profile reset. Persists via key `periods_v1` {seasonPeriod, points, completed, lastResult, period}. `stage` = `FinancialStageX.fromPoints(points)`; points += score per finished period.
  - `PetService`: care actions (feed 15 / play 10 / wash 10 coins, +5 XP) → `spendReporter?.reportSpend(required, cost)`; `applyPeriodResult(moodDelta)` added this session; `reactToQuiz` for quiz.
  - `PiggyBankService`: `saveToGoal` → `spendReporter?.reportSpend(savings, amount)`.
- **data/content/**: `ContentRepository` (`assets/content/tasks.json` = 9 quiz tasks, 3/topic) → quiz system (see below).
- **Quiz task system**: `TaskService` (injectable clock; key `quiz_tasks_v1` {day, ids, streak, maxStreak, lastStreakDay, completed}), rotates 3/day seeded `Random(int.parse(dayKey))`, `answer(taskId, optionId) → QuizResult?` (correct → coins reward + 20 XP + pet reactToQuiz(happy) + streak; wrong → pet sad, retryable). UI: `features/tasks/{TasksTab, QuizScreen, QuizTaskCard}`.
- **features/home/home_screen.dart**: NOW **4 tabs** — Питомец / **Бюджет** (`BudgetTab`) / Задания / Кошелёк (`IndexedStack` + BottomNavigationBar, icons pets/pie_chart/task_alt/account_balance_wallet).
- **features/budget/budget_tab.dart**: three phase views — planning (3 sliders, остаток, disabled button when over budget), active (plan vs fact rows per direction, «Завершить период»), finished (plan/fact, 3 criteria with check/cross icons, explanation, «Следующий период») + pet reaction card. Local slider state resyncs on period index change (`_boundPeriodIndex`).

### Open design decision (unresolved, needs user)
**How a period ends** — currently manual button. Options: manual / timer / event-based. ТЗ §5: «способ завершения — определяет команда».

## What's still TODO (ТЗ)
- **Покупки** (8 positions, 2 types, price/category/effect, history) — only 3 care actions exist.
- **Финансовые цели** (3 predefined with cost) — piggy bank has user-created goals only.
- **Раздел для взрослого** (barrier, progress, reset/delete).
- **Демо-режим** (ТЗ §8.13: fast-forward stages, reset to initial) — `PeriodService.reset()` exists as a building block.
- **Онбординг** (3 decision types intro, ТЗ §8.1).
- **История + глоссарий** (ТЗ §8.11).
- Device test of the budget flow (plan → care/spend → finish → next period) on `emulator-5554`.

## Device-testing notes (model can't view images)
- Drive UI via `adb -s emulator-5554 shell uiautomator dump /sdcard/ui.xml` → `shell cat` → split single-line XML with `tr '>' '\n'`; Flutter text often empty, use `content-desc`+bounds; tap `adb shell input tap X Y` at center.
- If app process dead: `adb shell monkey -p ru.rustore.financial_pet -c android.intent.category.LAUNCHER 1`.
- Watch `adb logcat` for `EXCEPTION` (esp. fl_chart on wallet tab).

## Git
- **Do NOT commit without asking** (user declined before; anomaly: git root is parent dir, `M ../.DS_Store`, `M ../.qwen/settings.json`). Uncommitted this session: `?? lib/core/models/budget.dart`, `?? lib/core/services/period_service.dart`, `?? lib/features/budget/`, `M lib/main.dart`, `M lib/features/home/home_screen.dart`, `M lib/core/services/{pet_service,piggy_bank_service}.dart`, `?? test/period_service_test.dart`. Stage only project paths.

# Session Log (2026-09-16)

## Recent Actions (this session — "Продолжаем работу")
1. [DONE] Discovered uncommitted WIP from prior session: `budget.dart` models + `PeriodService` + `BudgetTab` UI were built but the tab was **not wired** (unused import warning in home_screen).
2. [DONE] Wired «Бюджет» as 2nd tab in `HomeScreen` (IndexedStack + BottomNavigationBar item, `Icons.pie_chart_rounded`); updated doc comment.
3. [DONE] Wrote `test/period_service_test.dart` — 19 tests: initial state, confirmPlan (valid/over-budget/idempotent guard), reportSpend (phase-gated, non-positive ignored), finishPeriod criteria (score 3/2/0, moodDelta mapping, pet status changes, savings plan=0 edge case), stage thresholds, season cycle 1→5→1 wrap, reset, persistence round-trip (new service instance).
4. [DONE] **Fixed bug**: `finishPeriod` incremented `_completed` but never `_seasonPeriod`, so `nextPeriod()` always reopened period 1. Fix: `_openNextPeriod` now derives index from `_period.index % periodsPerSeason + 1`. Caught by 3 failing tests.
5. [DONE] Final verification: `flutter analyze` clean, `flutter test` → **64/64 pass**.
6. [TODO, awaiting user] Choose period-end method (manual vs timer vs event). Then: demo mode and/or adult section. User hasn't answered yet.

## Summary Metadata
**Update time**: 2026-09-16 (budget tab wired, period engine tested, nextPeriod bug fixed; 64 tests green, analyze clean)

---

## Summary Metadata
**Update time**: 2026-09-16T14:51:20.482Z

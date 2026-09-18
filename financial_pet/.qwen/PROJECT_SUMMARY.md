# Project Summary

## Overall Goal
Build **"Финансовый питомец" (Financial Pet)** — an offline Flutter Android app for RuStore that teaches children/youth (7–11, Moscow) financial literacy via a virtual pet whose development depends on the player's financial decisions (budgeting, spending, saving).

## Key Knowledge

### Technology & Conventions
- **Real stack: `provider` + `shared_preferences`** (ChangeNotifier services). NOT the BLoC + Hive + go_router + freezed that `QWEN.md` lists. **Do not migrate without explicit request.**
- **Language:** all UI text + comments in Russian; code identifiers in English.
- **Constraints (ТЗ):** fully offline (no API/analytics/ads), no real money, no child PII, guest mode (no registration), «безопасная ошибка» (a bad choice creates a fix task, never zeroes progress), accessibility ≥48dp targets / ≥16sp text, color never the only signal.
- **Common pitfall this session (twice): controller + non-rebuilding ancestor.** When a `TextEditingController` drives UI outside the `TextField` (e.g., button `onPressed` in an `AlertDialog`), the ancestor must `setState` via `_controller.addListener(...)` — typing only rebuilds the field itself.

### Environment & Build
- Working dir: `/Users/alexander/tamagochi/financial_pet`. **Git root = parent** `/Users/alexander/tamagochi` (paths appear as `financial_pet/lib/...`). Branch `main` tracks `origin/main`.
- **Verify:** `flutter analyze` (must be clean) + `flutter test` from project dir. Latest run: **99/99 green**.
- **APK:** `flutter build apk --debug` → `build/app/outputs/flutter-apk/app-debug.apk`.
- **Do NOT commit parent-repo files** (`../.DS_Store`, `../.qwen/settings.json`, `../Documents/`) — they show as modified in `git status`.
- **Commits: user commits themselves, in Russian.** Recent style: terse, sometimes verbatim from the bug report (e.g., `47df3f6` message is the user's original bug text; `a821471 8.10.Что добавлено (полировка §8.10)`).
- **Device testing:** user is actively testing on **Pixel 10a** (Android 17) — a log file `Pixel-10a-Android-17_2026-09-13_033656.txt` sits in the project root. Findings come back as short bug reports; verify their fixes on narrow screens.
- `fl_chart 0.70.2` gotchas: `BarChart(data, duration:)` positional; no `showTooltips` on `BarChartGroupData`; colors `.withValues(alpha:)`.

### SDK version gotchas (Flutter on /opt/homebrew/share/flutter — new master)
- **flutter_test API:** parameter type is `WidgetTester` (NOT `TestWidgetTester`); `takeAllExceptions`/`takeAllExceptionDetails` do NOT exist; `tester.view.physicalSize` works.
- **`Element`** has no `child`/`nextSibling`/`childElements` — use `element.visitChildren((c) { ... })`.
- **`IndexedStack` inactive tabs are OFFSTAGE** → default `find.*` doesn't see them; switch tabs via BottomNavigationBar label in tests first.
- **`AnimatedSwitcher` (new implementation) + fake async:** single `pump(300ms)` does NOT complete the transition; use `pumpAndSettle()`.
- **Pending timers:** binding asserts `!timersPending` at end of test body BEFORE addTearDown. Periodic timers (PetService 15s) must be disposed in test body (unmount tree, then dispose services). Auto-dismiss timers: call `dismiss()` before test end.
- **Ahem font in tests** has taller lines than real fonts — cards that fit on device can overflow in tests.
- New-SDK `AnimatedSwitcher` mis-positions children inside `Positioned` — prefer in-flow placement over overlays.

### Architecture (4 layers)
- `lib/core/models/`: `Pet` (hunger/fun/cleanliness 0..100; level=1+totalXp/60; mood), `Wallet` (start 50, no negative), `PetSpecies` (5×4 stages), `StreakBadge`, `PiggyBankGoal`, `Task`+`TaskOption`, `budget.dart`, `purchase.dart`, `growth_stage.dart`, `feedback_event.dart`.
- `lib/core/services/` (creation order in `main.dart`): WalletService → PetService (care 15/10/10) → TaskService (rotation, demo-all) → PiggyBankService → PurchaseService (8 items) → FeedbackService (event + history ≤30, 5s auto-dismiss) → PeriodService (5/season, sets `spendReporter`) → DemoService (test profile «Муся»/kitten).
- `lib/features/`: onboarding (splash + 3 slides, hint lightbulb), pet_creation, home (**6 tabs**: Питомец/Бюджет/Покупки/Задания/Кошелёк/История; FeedbackCard banner between header and tabs), budget, purchases, tasks (quiz with own inline `_FeedbackPanel` — does NOT post to FeedbackService; **now auto-scrolls to feedback after answer**), progress (`history_tab.dart` §8.11), adult (hold barrier, reset/delete).
- `lib/data/content/`: `content_repository` (tasks JSON), `education_goals`, `purchases`, `glossary.dart`.
- `lib/widgets/`: action_button, coin_badge, earnings_chart, level_indicator, status_bar, feedback_card.

### ТЗ §8 coverage
| § | Status |
|---|---|
| 8.1–8.7, 8.8 | ✅ all built (onboarding, pet, home, currency, budget, purchases, savings, tasks/quiz) |
| 8.9 feedback | ✅ `aa91e8c` (care/purchase/piggy/period-end; quiz uses inline panel) |
| 8.10 pet development | ✅ polish committed `a821471`; seasons/species variety still open |
| 8.11 history/progress | ✅ `e35665e` (`history_tab.dart`) |
| 8.12 adult section | ✅ `63b706d` |
| 8.13 save + demo | ✅ `da18e00` |
| 8.14 content management | ✅ (ContentRepository + JSON) |

### Git state (end of session)
- `main` = `origin/main` = `47df3f6` (goal-button fix, committed + pushed by user).
- **`lib/features/tasks/quiz_screen.dart` is STAGED, NOT committed** (quiz auto-scroll fix) — user to commit.
- Parent-repo noise present (`.DS_Store`, `.qwen/settings.json`, `Documents/`) — never stage it.

## Recent Actions
1. **Fixed «Создать» button in `_AddGoalDialog`** (`lib/features/home/home_screen.dart`): button enabled based on `_controller.text` in the dialog's `build`, but typing only rebuilt the `TextField` (dialog is a separate State) → button stayed disabled until a chip click triggered `setState`. Fix: `_controller.addListener(() => setState(() {}))` in `initState`. Also fixed the same staleness for the name preview in `lib/features/pet_creation/create_pet_screen.dart`. Verified: analyze clean, 99/99 tests. → **User committed as `47df3f6` and pushed** (user confirmed on device: «тут хорошо сделал, молодец»).
2. **Fixed quiz «К заданиям» button below the fold** (`lib/features/tasks/quiz_screen.dart`): after answering, the feedback panel + button appended to the `ListView` were below the screen bottom on Pixel 10a. Fix: `ScrollController` on the `ListView`; `_scrollToFeedback()` runs `animateTo(maxScrollExtent, 300ms, easeOut)` in a post-frame callback after the answer (no-op when content fits); `_retry()` jumps back to top. Added `dispose()`. Verified: analyze clean, 99/99. **Staged, awaiting user commit.**
3. **Built debug APKs** (two requests; second was Gradle up-to-date, ~1s) — output at `build/app/outputs/flutter-apk/app-debug.apk`.
4. User asked for `/summary` + `/recap` (no such skills exist) — was updating `.qwen/PROJECT_SUMMARY.md` and root `TODO.md` (stale: says 94 tests, lists §8.11 as uncommitted) when the summary request arrived.

## Current Plan
1. [DONE] Goal-button fix — committed `47df3f6`, pushed, user-verified on device.
2. [DONE] Quiz auto-scroll fix — tested green; **staged, user will commit** (Russian message, e.g., about button being below screen).
3. [IN PROGRESS] **Device verification on Pixel 10a** (user is driving): remaining checks — 6 bottom-nav tabs on narrow screen («Кошелёк»/«История» labels fit, no overflow), feedback cards on feed/purchase/piggy/period-end, purchases grid, populated История tab, quiz flow end-to-end. Bug reports arrive as short user messages.
4. [TODO] Finish summary housekeeping: update root `TODO.md` (test count 99; remove stale «закоммитить §8.11» item) and `.qwen/PROJECT_SUMMARY.md`; deliver the chat recap.
5. [TODO] **§8.10 polish**: stage visualization, seasons, pet species variety, history in wallet.
6. [TODO] Push pending quiz commit once user commits (user pushes themselves).

---

## Summary Metadata
**Update time**: 2026-09-18T21:53:27.888Z

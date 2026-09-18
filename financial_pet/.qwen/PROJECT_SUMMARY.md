# Project Summary

## Overall Goal
Build **"Финансовый питомец" (Financial Pet)** — an offline Flutter Android app for RuStore that teaches children/youth (7–11, Moscow) financial literacy via a virtual pet whose development depends on the player's financial decisions (budgeting, spending, saving).

## Key Knowledge

### Technology & Conventions
- **Real stack: `provider` + `shared_preferences`** (ChangeNotifier services). NOT the BLoC + Hive + go_router + freezed that `QWEN.md` lists. **Do not migrate without explicit request.**
- **Language:** all UI text + comments in Russian; code identifiers in English.
- **Constraints (ТЗ):** offline, no real money, no child PII, guest mode, «безопасная ошибка» (bad choice → fix task, never zeroes progress), ≥48dp targets / ≥16sp text, color never the only signal.

### Environment & Build
- Working dir: `/Users/alexander/tamagochi/financial_pet`. **Git root = parent** `/Users/alexander/tamagochi` (paths appear as `financial_pet/lib/...`). Branch `main` tracks `origin/main`.
- **Verify:** `flutter analyze` (must be clean) + `flutter test` from project dir.
- **Do NOT commit parent-repo files** (`../.DS_Store`, `../.qwen/settings.json`, `../Documents/`).
- Commits in Russian, style: `«Фича» (ТЗ §8.X): краткое описание`.
- `fl_chart 0.70.2` gotchas: `BarChart(data, duration:)` positional; no `showTooltips` on `BarChartGroupData`; colors `.withValues(alpha:)`.

### SDK version gotchas (Flutter on /opt/homebrew/share/flutter — new master)
Discovered while writing widget tests; they will bite again:
- **flutter_test API:** parameter type is `WidgetTester` (NOT `TestWidgetTester`); `takeAllExceptions`/`takeAllExceptionDetails` do NOT exist; `tester.view.physicalSize` works.
- **`Element`** has no `child`/`nextSibling`/`childElements` — use `element.visitChildren((c) { ... })` (void visitor, no bool return).
- **`IndexedStack` inactive tabs are OFFSTAGE** (wrapped in `_VisibilityScope`/`ExcludeFocus`) → default `find.*` (skipOffstage: true) does NOT see them. In tests: switch to the tab via the BottomNavigationBar label first.
- **`AnimatedSwitcher` (new implementation, own file) + fake async:** a single `pump(300ms)` does NOT complete the transition (SizeTransition stuck, card renders off-screen); use `pumpAndSettle()`.
- **Pending timers:** binding asserts `!timersPending` at end of test body, BEFORE addTearDown callbacks. Periodic timers (PetService 15s) must be disposed inside the test body: unmount tree (`pumpWidget(SizedBox())`) then dispose services. Auto-dismiss timers: call `dismiss()` before test end.
- **Ahem font in tests** has taller lines than real fonts: a card that fits on device can overflow in tests. Product card fixed with `mainAxisExtent: 160` (was `childAspectRatio: 1.3` → 12px RenderFlex overflow at 800×600 / narrow widths).

### Architecture (4 layers)
- `lib/core/models/`: `Pet` (hunger/fun/cleanliness 0..100; level=1+totalXp/60; Mood happy/okay/sad + `MoodX.emoji/label` extension), `Wallet` (start 50, no negative, `CoinTransaction`), `PetSpecies` (5×4 stages), `StreakBadge`, `PiggyBankGoal`, `Task`+`TaskOption`, `budget.dart` (BudgetDirection, FinancialStage, Period…), `purchase.dart`, `growth_stage.dart`, **`feedback_event.dart`** (FeedbackTone success/info/caution/celebration; factories: care, careInsufficient, purchaseSuccess, purchaseInsufficient, savings(reached:), levelUp).
- `lib/core/services/` (created in `main.dart`): WalletService → PetService (care 15/10/10, `justLeveledUp`) → TaskService (rotation, demo-all) → PiggyBankService (`saveToGoal` clamps to goal remainder, +20xp on reach) → PurchaseService (8 items, `trySpend`+`applyPurchaseEffect`) → **FeedbackService** (current event + history(≤30), 5s auto-dismiss, `post/dismiss/clear`) → PeriodService (5/season, sets `spendReporter` on pet+piggy+purchase) → DemoService (last; test profile «Муся»/kitten).
- `lib/features/`: onboarding (splash + 3-slide onboarding, hint lightbulb), pet_creation, home (`home_screen` **6 tabs**: Питомец/Бюджет/Покупки/Задания/Кошелёк/**История**; **FeedbackCard banner** between header and tabs), budget, purchases, tasks (quiz with own inline `_FeedbackPanel` — does NOT post to FeedbackService), **progress** (`history_tab.dart`, ТЗ §8.11), adult (hold barrier, progress, reset/delete).
- `lib/data/content/`: `content_repository` (tasks JSON), `education_goals` (adult section), `purchases` (catalog), **`glossary.dart`** (`GlossaryTerm` + `glossary` const — справочник терминов §8.11).
- `lib/widgets/`: action_button, coin_badge, earnings_chart, level_indicator, status_bar, **feedback_card** (tone color+word+emoji, chips, «Понятно» 48dp).

### ТЗ §8 coverage
| § | Status |
|---|---|
| 8.1 onboarding/profile | ✅ dd8757f |
| 8.2 pet creation | ✅ |
| 8.3 main screen | ✅ (5 tabs) |
| 8.4 currency/income | ✅ |
| 8.5 budget planning | ✅ |
| 8.6 purchases | ✅ f103f1a/88b889d + overflow fix aa91e8c |
| 8.7 savings/goals | ✅ |
| 8.8 tasks | ✅ |
| 8.9 feedback | ✅ aa91e8c (care/purchase/piggy/period-end; quiz uses inline panel) |
| 8.10 pet development | ~ stages + xp exist; visualization partly in budget tab |
| 8.11 history/progress | ✅ e35665e `history_tab.dart` (6th tab): период-итог, темы, цели, задания, операции, словарь |
| 8.12 adult section | ✅ 63b706d |
| 8.13 save + demo | ✅ da18e00 |
| 8.14 content management | ✅ (ContentRepository, purchaseCatalog) |

## Recent Actions
1. **Feedback layer (ТЗ §8.9) completed** — commit `aa91e8c` (9 files, +753/−46):
   - Fixed compile error (`required bool reached` in `FeedbackEvent.savings`).
   - Registered `FeedbackService` in `main.dart`; new `feedback_card.dart`.
   - **Card placement: banner in normal flow** (between header and tabs in `home_screen` Column). First attempt used `Positioned` overlay — new-SDK `AnimatedSwitcher` mis-positions children inside `Positioned` (card rendered off-screen). Banner is also safer on small phones.
   - Events posted from: care actions (`_care` in `_PetTab`), purchases (success/insufficient), piggy top-up (savings/levelUp), period finish (info); cleared on demo reset/exit and adult reset/delete.
   - Care flow rewritten: buttons pass statusBefore/labels; card shows «Сытость: 80 → 100», «−15 монеток», next step; level-up wins over care event.
   - Fixed product-card overflow (`mainAxisExtent: 160`).
2. **Tests: 91 green** (was 89 pre-feedback; +13 new: 8 unit in `feedback_service_test.dart` + … incl. factory safety checks, 2 widget in `home_feedback_test.dart`).
3. `flutter analyze` clean.
4. **«История и прогресс» (ТЗ §8.11) built + committed** `e35665e`: new `lib/features/progress/history_tab.dart` (6th tab: период-итог, умения по темам, цели копилки, пройденные задания, история операций, словарь), new `lib/data/content/glossary.dart`, `TaskService.completedHistory`/`completedCount` getters, 6th tab in `home_screen` (`history_rounded` icon), bottom-nav label size locked to 12px in theme. +4 tests → **95 green**, analyze clean.

## Current Plan
1. [DONE] Feedback layer §8.9 — committed `aa91e8c`, NOT pushed (user pushes themselves).
2. [DONE] §8.11 «История» UI — committed `e35665e`, NOT pushed.
3. [NEXT] **Device verification** on Pixel 10a: 6 bottom-nav tabs on a narrow screen (check «Кошелёк»/«История» labels fit, no overflow), feedback card on feed/purchase/piggy/period-end, purchases grid, and the new История tab populated. Then **push** (user pushes themselves).
4. [TODO] Polish: §8.10 stage visualization, seasons, pet species variety, history in wallet.

**Verification recipe for device:** feed pet → card appears → «Понятно»/auto-dismiss; buy «Корм» → card; piggy 20 → info card (or celebration on goal); finish period → info card; demo reset/exit → no stale card; adult reset/delete → no stale card.

---
## Summary Metadata
**Update time**: 2026-09-17 (session: feedback layer)

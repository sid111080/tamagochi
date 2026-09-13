# Project Summary

## Overall Goal
Build **"ФинПитомец" (Financial Pet)** — a mobile Flutter app that teaches financial literacy to children/youth (7–14) in Moscow via a virtual pet, for distribution on RuStore (Android/iOS), fully offline.

## Key Knowledge

### Language & Conventions (from QWEN.md system prompt)
- **UI text and code comments in Russian; code identifiers in English.**
- Target audience: kids 7–14, Moscow. Child-friendly, age-appropriate UX.
- Accessibility: large tap targets, high contrast, minimal text, icon-first navigation.
- **No external API calls, no analytics, no ads — must work fully offline.**
- QWEN.md *recommends* stack: Feature-First (domain/data/presentation), BLoC/Cubit, Hive, go_router, freezed+json_serializable, Lottie if needed.

### ⚠️ CRITICAL DECISION — Stack Mismatch (user resolved)
- QWEN.md prescribes **BLoC + Hive + go_router + freezed**, but the **existing code uses `provider` + `shared_preferences` + manual JSON serialization**.
- **User explicitly chose to KEEP the current stack** (`provider` + `shared_preferences`). Do **NOT** migrate to BLoC/Hive/go_router/freezed unless the user re-requests it. Treat QWEN.md's stack as a *future* refactor option only.

### Tech / Build Facts
- Path: `/Users/alexander/tamagochi/financial_pet`
- **Git root is the PARENT dir `/Users/alexander/tamagochi`** (not `financial_pet`).
- Flutter recent (uses `withValues(alpha:)` API, `CardThemeData`, Material 3). SDK `^3.13.3`.
- `pubspec.yaml` deps: `provider ^6.1.2`, `shared_preferences ^2.3.2`, `intl ^0.20.2`, `fl_chart ^0.70.2`; dev: `flutter_test`, `flutter_lints ^6.0.0`, `flutter_launcher_icons ^0.14.3`.
- Android `applicationId`: `ru.rustore.financial_pet`.
- No `ios/` directory (Android-only target for RuStore).
- Verify commands: `flutter analyze`, `flutter test`, `flutter build apk --debug`.

### Architecture (existing, provider-based)
- **Models** (`lib/models/`): `Pet` (hunger/fun/cleanliness 0–100, totalXp, level, mood, stage, decay, feed/play/wash, toJson/fromJson), `GrowthStage` (baby/child/teen/adult + `GrowthStageX` ext: label/sizeScale/index/fromLevel), `Wallet`+`CoinTransaction`, `Task`+`TaskPool` (12 tasks: 8 daily, 4 weekly), `PetSpecies` (5: kitten/chick/dragon/panda/unicorn, uses Flutter `Color`).
- **Services** (`lib/services/`, all `ChangeNotifier` + `SharedPreferences`): `WalletService(prefs)`, `PetService(prefs, wallet)` (has periodic decay `Timer`), `TaskService(prefs, wallet, pet)`. Dependency order matters: wallet → pet → task.
- **Screens** (`lib/screens/`): `SplashScreen(hasPet)`, `CreatePetScreen`, `HomeScreen` (new this session).
- **Widgets** (`lib/widgets/`): `CoinBadge`, `CareActionButton`, `TaskCard`, `LevelIndicator`, `PetStatusBar`.
- **Theme** (`lib/theme/app_theme.dart`): `AppColors` + `AppTheme.light`.

### Game Mechanics
- Care costs (coins): feed 15, play 10, wash 10; each grants 5 XP.
- `xpPerLevel = 60`. Level = `1 + totalXp ~/ 60`. Stage: <3 baby, 3–4 child, 5–7 teen, 8+ adult.
- Decay: 0.6/min (fun ×0.8, cleanliness ×0.5); offline decay capped at 6h.
- Mood = avg(hunger,fun,cleanliness): ≥70 happy, ≥40 okay, else sad.
- Task rewards: daily = 15 coins / 25 XP; weekly = 35 coins / 45 XP. Starting balance = 50.

### App Icon
- Source: `assets/icon.png` (1024×1024, generated via Python/PIL — orange cat face with cream background circle).
- Generated via `flutter_launcher_icons` into all 5 mipmap densities (48→192px).
- Config in `pubspec.yaml` under `flutter_launcher_icons:` block (android: true, ios: false).

## Recent Actions (this session)
1. **[DONE]** Diagnosed app did not compile: `home_screen.dart` was imported by `splash_screen.dart`/`create_pet_screen.dart` but **missing** (5 errors); `main.dart` was still the default counter demo.
2. **[DONE]** Asked user about stack conflict → user chose **keep provider+shared_preferences**.
3. **[DONE]** Created `lib/screens/home_screen.dart`: `HomeScreen` (StatefulWidget, `BottomNavigationBar` 2 tabs, `IndexedStack` of private `_PetTab` + `_TasksTab`, top bar with `CoinBadge`). Pet tab: animated avatar (scales by stage), name, mood, `LevelIndicator`, 3 status bars, 3 care buttons (enabled = `canX && canAfford`), level-up SnackBar. Tasks tab: available + completed `TaskCard`s, empty states.
4. **[DONE]** Rewrote `lib/main.dart`: `main()` → `SharedPreferences.getInstance()` → `App` widget with `MultiProvider` (Wallet→Pet→Task, using `context.read` for deps), `AppTheme.light`, `home: Consumer<PetService>` → `SplashScreen(hasPet:)`.
5. **[DONE]** Fixed `wallet.dart` lint: `Wallet({this.balance = 50});` (initializing formal).
6. **[DONE]** Fixed `create_pet_screen.dart`: removed invalid `const` on `MaterialPageRoute` (not const-constructible) → `MaterialPageRoute(builder: (_) => const HomeScreen())`.
7. **[DONE]** Added 4 test files: `test/pet_test.dart`, `test/wallet_test.dart`, `test/task_test.dart`, `test/pet_service_test.dart` (uses `SharedPreferences.setMockInitialValues({})` + `TestWidgetsFlutterBinding.ensureInitialized()`, disposes services in `tearDown` to cancel the decay `Timer`).
8. **[DONE] Verification:** `flutter analyze` → **No issues found**; `flutter test` → **21 tests passed**; `flutter build apk --debug` → **built successfully** (`build/app/outputs/flutter-apk/app-debug.apk`). App now runs end-to-end: splash → create pet → home (2 tabs) → care/earn/complete/level-up.
9. **[DONE]** Generated app icon (cat face) + `flutter_launcher_icons` config; rebuilt APK.
10. **[DONE]** Fixed **RenderFlex overflow on CreatePetScreen** (pet species cards): increased `SizedBox` height 96→120, added `mainAxisSize: MainAxisSize.min` to the card's inner `Column`.
11. **[DONE]** Fixed **RenderFlex overflow on TaskCard** (30px horizontal): restructured bottom section from single `Row` [rewards + Spacer + button] into two rows — rewards on one line, button on its own line (right-aligned, slightly larger tap target).

## Current Plan
1. **[BLOCKED / NEEDS INVESTIGATION] Git state anomaly (user CANCELLED the check).** `git status` (root `/Users/alexander/tamagochi`) shows only `.DS_Store`, `.qwen/settings.json`, `financial_pet/.qwen/settings.json` as modified — my `lib/` + `test/` changes are **NOT listed**, even though `git ls-files lib/` confirms `lib/main.dart` is tracked. Hypothesis: a **nested `.git` inside `financial_pet`** (making it a gitlink/submodule) or a gitignore rule. **The user denied the tool call that would confirm this.** Do NOT commit until the git tracking situation is clarified with the user.
2. **[TODO] Commit** the session's work (home_screen.dart, main.dart, wallet.dart, create_pet_screen.dart, 4 test files, pubspec.yaml icon config, assets/icon.png, task_card.dart overflow fix) once the git anomaly is resolved — stage only these paths, never the unrelated `.DS_Store`/`.qwen/settings.json`.
3. **[TODO] Next feature candidates** (align with QWEN.md functional scope): piggy bank / savings goal (копилка как сейф), badges/streaks/seasons, progress chart (fl_chart is already a dep but unused), pet selection variety, weekly task scheduling.

### Suggested next step for the agent
Re-ask the user (non-destructively, read-only) how they want the git tracking issue handled before attempting any commit — e.g., confirm whether `financial_pet` should be its own repo or part of the `tamagochi` repo, since the last investigation was cancelled.

---

## Summary Metadata
**Update time**: 2026-09-13T16:08:45.190Z

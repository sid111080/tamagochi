# ФинПитомец

Мобильное приложение по финансовой грамотности для детей 7–11 лет. Ребёнок создаёт виртуального питомца, планирует бюджет, выполняет задания и копит на цель — состояние питомца зависит от финансовых решений.

- **Платформа:** Android 8.0+ (API 21+), портретная ориентация
- **Язык интерфейса:** русский
- **Работает офлайн:** нет зависимостей от сети, сервера, аккаунтов

## Локальный запуск

### Требования

| Компонент | Минимальная версия | Где взять |
|---|---|---|
| Flutter SDK | 3.22+ (Dart 3.13+) | https://docs.flutter.dev/get-started/install |
| Android Studio | Ladybug (2024.2)+ | https://developer.android.com/studio |
| Android SDK | API 34 (compile) / API 21 (min) | Устанавливается через Android Studio |
| Java JDK | 17 | Входит в Android Studio |

Проверка установки:

```bash
flutter doctor
```

Все пункты должны быть зелёные (✓). Если Android SDK или эмулятор не найдены — следуйте подсказкам `flutter doctor --android-libs`.

### Запуск на эмуляторе

1. **Создать эмулятор** (один раз):

   - Android Studio → **Tools → Device Manager**
   - **Create Device** → выбрать телефон (например Pixel 6)
   - **Choose a System Image** → API 34 (UpsideDownCake) или новее
   - **Finish** → запустить эмулятор (иконка ▶️)

2. **Запустить приложение:**

   ```bash
   cd financial_pet
   flutter run
   ```

   Команда автоматически найдёт запущенный эмулятор и установит debug-сборку.

   Если подключено физическое устройство (Android Debug Bridge):
   ```bash
   # увидеть список устройств
   flutter devices

   # запустить на конкретном устройстве
   flutter run -d <device-id>
   ```

### Сборка APK

```bash
# Debug APK (для локальной проверки)
flutter build apk --debug
# → build/app/outputs/flutter-apk/app-debug.apk

# Release APK
flutter build apk --release
# → build/app/outputs/flutter-apk/app-release.apk
```

Установка на устройство:

```bash
adb install build/app/outputs/flutter-apk/app-debug.apk
```

Или перетащить файл APK на устройство и открыть.

### Сборка AAB (для RuStore)

```bash
flutter build appbundle --release
# → build/app/outputs/bundle/release/app-release.aab
```

> ⚠️ Релизная сборка сейчас подписана debug-ключом (см. `android/app/build.gradle.kts`). Перед публикацией в RuStore нужно настроить собственный signing config.

### Тесты

```bash
flutter test
```

### Полезные команды

| Команда | Что делает |
|---|---|
| `flutter run` | Запуск в debug-режиме с hot-reload |
| `flutter run --release` | Запуск в release-режиме (реалистичная производительность) |
| `flutter clean && flutter pub get` | Пересобрать после проблем с зависимостями |
| `flutter build apk --debug` | Собрать APK для установки на устройство |
| `flutter test` | Прогнать unit/widget-тесты |
| `flutter analyze` | Статический анализ (lint) |

### Горячая перезагрузка (hot-reload)

При `flutter run` в терминале:

| Клавиша | Действие |
|---|---|
| `r` | Hot-reload — применить изменения кода без потери состояния |
| `R` | Hot-restart — полный перезапуск приложения |
| `q` | Остановить |

### Структура проекта

```
lib/
├── main.dart              # точка входа
├── app/                   # тема, маршруты
├── core/
│   ├── models/            # Pet, Budget, Purchase, Goal, Task, GameState
│   ├── services/          # StorageService, GameEngine (ChangeNotifier)
│   └── constants/         # игровые константы
├── data/
│   └── content/           # JSON: задания, товары, цели (отдельно от логики)
├── features/
│   ├── onboarding/        # первый запуск
│   ├── pet_creation/      # создание питомца
│   ├── home/              # главный экран (HUD)
│   ├── budget/            # планирование бюджета
│   ├── purchases/         # каталог покупок
│   ├── tasks/             # финансовые задания
│   ├── progress/          # история, стадии развития
│   ├── adult_section/     # раздел для взрослого
│   └── demo/              # демо-режим
└── widgets/               # переиспользуемые виджеты
```

## Архитектура

### Стек

| Слой | Технология |
|---|---|
| State management | `provider` (ChangeNotifier-сервисы) |
| Persistence | `shared_preferences` (JSON-строки под versioned-ключами) |
| Навигация | `Navigator` + `IndexedStack` (без роутера) |
| UI | Material 3, тёплая палитра (coral/cream/rust) |
| Графики | `fl_chart` |
| Контент | JSON-ассет + const Dart-списки |

### Четыре слоя

```
┌─────────────────────────────────────────────────────────┐
│  UI (features/)                                         │
│  Экраны, вкладки, HUD. Реагируют через context.watch()  │
├─────────────────────────────────────────────────────────┤
│  Сервисы (core/services/)                               │
│  8 ChangeNotifier'ов. Каждый владеет одной областью.    │
│  Методы мутации → notifyListeners()                     │
├─────────────────────────────────────────────────────────┤
│  Модели (core/models/)                                  │
│  Plain Dart, ручные toJson/fromJson. Без freezed.       │
│  + интерфейс SpendReporter (развязка сервисов)          │
├─────────────────────────────────────────────────────────┤
│  Контент (data/content/ + assets/content/)             │
│  Задания — JSON. Товары/цели/глоссарий — const Dart.   │
│  Добавление контента не требует изменения логики.       │
└─────────────────────────────────────────────────────────┘
```

### Сервисы и зависимости

```
main.dart (MultiProvider)
│
├── WalletService          ← prefs
│   баланс, транзакции, earn/trySpend
│
├── PetService             ← prefs, WalletService
│   питомец, XP, level, decay (15s timer), care actions
│   └── spendReporter: SpendReporter?  ← назначает PeriodService
│
├── TaskService            ← prefs, WalletService, PetService, List<Task> (JSON)
│   quiz-ротация (3/день), completion, streaks
│
├── PiggyBankService       ← prefs, WalletService, PetService
│   цели копилки, save/withdraw
│   └── spendReporter: SpendReporter?
│
├── PurchaseService        ← WalletService, PetService, purchaseCatalog
│   buy() → wallet + pet effect + spendReporter
│   └── spendReporter: SpendReporter?
│
├── FeedbackService        (in-memory, не персистится)
│   текущее FeedbackEvent + история (30), auto-dismiss
│
├── PeriodService          ← prefs, WalletService, PetService
│   период (planning→active→finished), season (5),
│   FinancialStage, реализует SpendReporter
│   → назначает spendReporter на Pet/PiggyBank/Purchase
│
└── DemoService            ← prefs + все 5 доменных
    enterDemo / resetDemo / exitDemo
```

**Ключевой механизм развязки** — интерфейс `SpendReporter` (один метод `reportSpend(direction, amount)`). `PeriodService` реализует его. `PetService`, `PiggyBankService`, `PurchaseService` держат nullable-ссылку, которую `main.dart` подставляет после конструирования `PeriodService`. Нижние сервисы не знают о периоде — нет циклической зависимости.

### Поток данных (пример: покупка)

```
UI: PurchaseService.buy(id)
  → WalletService.trySpend(price)       // баланс, транзакция
  → PetService.applyPurchaseEffect()    // статусы питомца
  → PeriodService.reportSpend(...)      // факт периода
  → UI: FeedbackService.post(event)     // карточка объяснения
  → каждый сервис: notifyListeners()    // UI перерисовывается
```

### Две оси роста

| Ось | Источник | Результат |
|---|---|---|
| **Уровень питомца** (GrowthStage) | XP: care (+5), задания (+20), копилка (+20). Время: decay каждые 15 с | baby → child → teen → adult (уровни 2/5/8) |
| **Финансовая стадия** (FinancialStage) | Очки за план-факт каждого периода (5 периодов = сезон) | beginner → confident → master (0/5/10 очков) |

Оси независимы: питомец может быть взрослым, но финансово — beginner.

### Сохранение состояния

Каждый сервис сериализует свои модели в **один versioned-ключ** SharedPreferences:

| Ключ | Содержимое |
|---|---|
| `wallet_v1` | баланс + последние 40 транзакций |
| `pet_v1` | вид, цвет, имя, статусы, XP, xpHistory |
| `periods_v1` | список периодов + текущий сезон |
| `piggy_bank_v1` | список целей |
| `quiz_tasks_v1` | карта выполненных заданий + streaks |
| `demo_mode_v1` | флаг демо-режима |

При запуске `main()` загружает `SharedPreferences` → конструкторы сервисов гидратируют модели → UI готов. Нет централизованного store — каждый сервис сам управляет своим слайсом.

### Контент и логика

- **Задания** — `assets/content/tasks.json` (10 шт: 4 планирование + 3 сбережения + 3 покупки). Загружаются `ContentRepository` при старте. Новое задание = новый JSON-объект.
- **Товары** — `data/content/purchases.dart` (const список, 8 позиций).
- **Цели копилки** — `data/content/preset_goals.dart` (3 пресета).
- **Глоссарий** — `data/content/glossary.dart` (6 терминов).

### Демо-режим

`DemoService` — оркестратор:
- `enterDemo()` — сбрасывает все сервисы, создаёт тестового питомца, открывает все задания, отключает decay.
- `resetDemo()` — повторный сброс (из раздела для взрослого).
- `exitDemo()` — возвращает к «чистому» состоянию.

Игровой цикл в демо проходит без реального ожидания: периоды мгновенны, задания доступны сразу.

### Тесты

16 файлов в `test/`:
- **Модели:** pet, wallet, task
- **Сервисы:** wallet, pet, task, period, piggy_bank, purchase, feedback, demo
- **Контент:** content_repository
- **UI (widget):** home_feedback, history_tab, onboarding_screen, quiz_levelup, pet_growth

Запуск: `flutter test`

Актуальность

Современные дети рано знакомятся с денежными средствами (карманные деньги, подарки), но не имеют интуитивно понятных и увлекательных инструментов для формирования базовых финансовых навыков. 
При этом финансовые привычки, заложенные в детском возрасте, определяют дальнейшее поведение во взрослой жизни.
Описание задачи
Разработать мобильное приложение для Rustore, которое в формате виртуального питомца научит ребенка основам планирования бюджета, приоритезации расходов и формированию накоплений.

Приложение должно иметь следующий функционал:

- для детей: 
возможность выбрать и создать уникального виртуального питомца; кормить, играть с ним или ухаживать за ним, тратя виртуальную валюту, которую нужно зарабатывать и разумно распределять; 
получать ежедневные или еженедельные (в зависимости от сложности) задания на тему финансов; 
видеть прогресс и рост питомца, который напрямую зависит от разумного управления ресурсами.

![Preview](pet1.png)
![Preview](pet2.png)
![Preview](pet3.png)
![Preview](pet4.png)


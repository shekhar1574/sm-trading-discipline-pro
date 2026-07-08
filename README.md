# SM Trading Discipline Pro
**Discipline First. Profits Follow.**

Phase 1 delivery: a working Flutter Android app implementing the Discipline
Engine, Emotion Control Module, Trade Checklist, Trade Journal, and Dashboard.

## What's included in this Phase 1 build

- **Dashboard** — account balance, today's P&L, win rate, trades taken today,
  0–100 discipline score gauge, current emotional status.
- **Discipline Engine** (`lib/data/services/discipline_engine.dart`) —
  deterministic rule checks: max trades/day (default 2), daily max loss %,
  daily profit target %, cooldown period between trades. Also owns the
  discipline scoring logic (rewards/penalties) and the 30-Day Challenge
  trader-level lookup.
- **Emotion Control Module** — mandatory emotion check before every trade.
  Negative emotions (Fear, Greed, Revenge, FOMO, Frustration) trigger a
  10-minute cooldown screen with a breathing animation and focus prompts.
- **Trade Checklist** — 6-point confirmation (trend, setup, volume, R:R,
  stop loss, position size) before a trade can be logged; skipping is
  allowed but penalizes the discipline score.
- **Trade Journal** — full entry: symbol, entry/exit, SL, target, quantity,
  strategy, screenshot upload, emotion, mistakes, lessons learned.
- **AI Trading Coach (rule-based, Phase 1)** — `JournalProvider.generateCoachFeedback()`
  produces feedback like *"You followed your rules today. Your discipline
  score improved."* This is a deterministic placeholder; Phase 2 can swap
  it for an LLM-backed FastAPI endpoint without touching the UI.
- **Settings** — configurable discipline rules (balance, trade limit, loss
  limit, profit target, cooldown minutes), persisted locally.

Not yet built (by design — these are Phase 2+ per the brief): broker API
integrations (Zerodha/Angel One/Upstox/Fyers/Dhan), cloud PostgreSQL sync,
FastAPI backend, full 30-Day Challenge UI/badges, and the analytics charts
screen (the data layer — `DisciplineEngine.summarize()` — is already in
place for it).

## Folder structure

```
sm_trading_discipline_pro/
├── pubspec.yaml
├── assets/images/
└── lib/
    ├── main.dart
    ├── core/
    │   ├── constants/app_constants.dart      # rules defaults, emotion list, checklist items
    │   └── theme/app_theme.dart              # premium dark theme
    ├── data/
    │   ├── models/
    │   │   ├── trade_model.dart
    │   │   ├── emotion_entry.dart
    │   │   └── discipline_settings.dart
    │   └── services/
    │       ├── database_service.dart         # SQLite persistence
    │       └── discipline_engine.dart        # rule engine + scoring
    └── presentation/
        ├── providers/
        │   ├── dashboard_provider.dart
        │   └── journal_provider.dart
        ├── screens/
        │   ├── dashboard_screen.dart
        │   ├── emotion_check_screen.dart
        │   ├── cooldown_screen.dart
        │   ├── trade_checklist_screen.dart
        │   ├── add_trade_screen.dart
        │   ├── trade_journal_screen.dart
        │   └── settings_screen.dart
        └── widgets/
            ├── stat_card.dart
            ├── discipline_gauge.dart
            └── emotion_selector.dart
```

Clean Architecture separation: `data/` (models + services, no Flutter UI
imports) is independent of `presentation/` (UI + state). This is what
makes broker integrations, PostgreSQL, and the FastAPI backend addable in
Phase 2 without rewriting screens.

## Easiest option: let GitHub build the APK for you

This project includes `.github/workflows/build-apk.yml`, which builds a
release APK automatically every time you push to GitHub — no Flutter
install needed on your own machine.

1. Create a new **public or private** GitHub repo (e.g. `sm-trading-discipline-pro`).
2. Push this entire folder to it:
   ```bash
   cd sm_trading_discipline_pro
   git init
   git add .
   git commit -m "Phase 1: SM Trading Discipline Pro"
   git branch -M main
   git remote add origin https://github.com/<your-username>/<your-repo>.git
   git push -u origin main
   ```
3. Go to your repo on GitHub → the **Actions** tab. You'll see "Build
   Android APK" running (takes ~3-5 minutes the first time).
4. When it finishes (green check), click into that run → scroll to
   **Artifacts** → download **sm-trading-discipline-pro-apk**. It's a
   zip containing the release APK(s), split per CPU architecture
   (arm64-v8a covers essentially all modern Android phones).
5. Copy the APK to your phone and tap to install (allow "install from
   unknown sources" once, if prompted).

You can re-trigger a build anytime without pushing new code via
**Actions → Build Android APK → Run workflow**.

## How to build the APK locally (alternative)

If you'd rather build on your own machine instead of GitHub:

### 1. Install prerequisites (one-time)
- Install [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable channel).
- Install Android Studio (for the Android SDK + an emulator, optional).
- Run `flutter doctor` and resolve any red flags.

### 2. Scaffold the native Android/iOS wrapper
Flutter's native platform folders (`android/`, `ios/`) are generated by
the tooling and aren't included here. In an empty folder:

```bash
flutter create --org com.smtrading --project-name sm_trading_discipline_pro .
```

Then copy this project's `lib/`, `pubspec.yaml`, and `assets/` into that
scaffolded folder, overwriting the generated placeholders.

### 3. Fetch dependencies
```bash
flutter pub get
```

### 4. Run on a connected device / emulator
```bash
flutter run
```

### 5. Build the release APK
```bash
flutter build apk --release
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

For a smaller, per-architecture build:
```bash
flutter build apk --split-per-abi --release
```

### 6. (Optional) App icon / name
Update `android/app/src/main/AndroidManifest.xml` (`android:label`) and
replace `android/app/src/main/res/mipmap-*/ic_launcher.png` with your
branded icon, or use the `flutter_launcher_icons` package.

## Notes on production hardening (called out honestly, per the brief)

- **Encrypted DB**: `database_service.dart` currently uses plain `sqflite`.
  Swap to `sqflite_sqlcipher` (API-compatible) and pass a password to
  `openDatabase` for at-rest encryption — isolated to one file by design.
- **Auth**: no login screen yet in Phase 1 (single local user). Add
  Firebase Auth or a FastAPI JWT flow in Phase 2 alongside the backend.
- **API keys (Phase 2 broker integration)**: use `flutter_secure_storage`
  (already in `pubspec.yaml`) — never store broker API keys in plain
  SQLite or SharedPreferences.
- **P&L uses realized trades only**: Bhavcopy/EOD-style constraints from
  your other tools don't apply here since this app takes manual entry,
  but if you wire in a broker feed later, keep the same "don't fake
  numbers you don't have" principle (e.g. don't compute live MTM without
  a live price feed).

## Next steps (Phase 2, per your spec)

1. FastAPI backend + PostgreSQL for cloud sync/multi-device.
2. Broker adapters (Zerodha Kite Connect, Angel One SmartAPI, Upstox,
   Fyers, Dhan) behind a common `BrokerService` interface so the UI never
   needs to know which broker is active.
3. Replace the rule-based coach with an LLM-backed `/coach/feedback`
   FastAPI endpoint fed by the journal export.
4. Analytics charts screen using `fl_chart` (dependency already included)
   on top of `DisciplineEngine.summarize()`.
5. 30-Day Challenge UI: streak calendar + badge grid using
   `AppConstants.traderLevels` / `traderLevelThresholds` (already defined).

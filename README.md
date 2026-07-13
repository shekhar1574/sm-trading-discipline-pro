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

Not yet built (by design — these are Phase 2+ per the brief): Zerodha/
Angel One/Upstox/Dhan broker integrations (Fyers is done — see below),
cloud PostgreSQL sync, and full 30-Day Challenge badge UI (the level
lookup logic already exists in `DisciplineEngine.traderLevelForPoints()`).

## Phase 2 additions

- **P&L Calendar** (`pnl_calendar_screen.dart`) — day-by-day realized P&L
  grid, month navigation, color intensity scaled to that day's size.
- **AI Analytics** (`analytics_screen.dart` + `analytics_service.dart`) —
  three tabs:
  - *Overview*: weekday P&L bar chart, win rate / net P&L summary, most
    traded symbols.
  - *Your Mistakes*: rule-based categorization (Revenge Trading, FOMO,
    Emotional Trading, Poor Risk-Reward, Checklist Skipped) with a
    severity badge and a suggested fix per category — computed from
    fields already in your journal (emotion tag, R:R ratio, checklist
    completion), not a black box.
  - *AI Tips*: short coaching feed grouped by Psychology / Strategy /
    Time-Session, e.g. "your best trading hour is 10:00 AM."
  - Honesty note: none of this calls a real LLM — it's deterministic
    pattern-matching over your own data, which keeps it explainable and
    free to run on-device. Swapping in real LLM-generated tips later
    means adding a `/coach/tips` endpoint to the FastAPI backend (already
    started for Fyers) — ask if you want that wired in.
- **Strategies Tracker** (`strategies_screen.dart` + `strategy_provider.dart`)
  — create/edit strategies, see per-strategy trade count, win rate, and
  net P&L computed automatically by matching `TradeModel.strategy`.
- **Report Export** (`report_export_service.dart`) — Excel (.xlsx) and
  PDF export for All Trades / Month Wise / Profitable / Losing /
  Strategy Overview, shared via the platform share sheet. Triggered from
  the export icon in the Trading Journal's app bar.
- **Multi-segment tracking** — `TradeModel.segment` (Equity/F&O/Forex/
  Crypto), with `DisciplineEngine.summarizeBySegment()` already built for
  per-segment breakdowns.

## Fyers live broker integration

Architecture is broker-agnostic by design: `BrokerService` (an abstract
interface in `lib/data/services/broker/broker_service.dart`) is what the
UI talks to. `FyersBrokerService` is the first implementation; adding
Zerodha/Angel One/Upstox/Dhan later means writing one new class, not
touching any screen.

**Important — this needs your action to actually go live:**
1. A FastAPI backend (`/backend`) handles the Fyers OAuth handshake and
   API calls — this **cannot** run inside the mobile app because Fyers
   needs a public HTTPS redirect URL and your API secret must never sit
   inside a phone app. Full deployment steps (Render, free tier works):
   **see `backend/README.md`**.
2. You need a Fyers trading account and to register an API app at
   https://myapi.fyers.in/dashboard to get an App ID + Secret Key.
3. Once deployed, set your backend's URL in
   `lib/core/constants/backend_config.dart`.

Until steps 1–3 are done, the **Connect Broker** screen shows a
"backend not configured" notice instead of crashing — the rest of the
app works fully offline without it.

I wrote `backend/app/services/fyers_service.py` from Fyers' general API
v3 patterns and syntax/route-tested it (see the FastAPI test output —
all endpoints respond correctly), but I have **not** been able to test
it against a real, live Fyers account (no sandbox access from here).
Verify the exact response field names against
https://myapi.fyers.in/docsv3 the first time you connect a real account,
in case Fyers' API has since changed.

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

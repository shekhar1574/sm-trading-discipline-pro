/// Central place for every "magic number" and static list in the app.
/// Keeping these here means the Discipline Engine, UI, and Analytics
/// modules all read from a single source of truth.
class AppConstants {
  AppConstants._();

  static const String appName = 'SM Trading Discipline Pro';
  static const String appTagline = 'Discipline First. Profits Follow.';

  // ---------------- Discipline Engine defaults ----------------
  static const int defaultMaxTradesPerDay = 2;
  static const double defaultDailyMaxLossPercent = 2.0; // % of account
  static const double defaultDailyProfitTargetPercent = 3.0; // % of account
  static const int defaultCooldownMinutes = 15; // after every trade
  static const int negativeEmotionCooldownMinutes = 10;

  // ---------------- Discipline score weighting ----------------
  static const int scoreStartValue = 70; // new users start "neutral-good"
  static const int scorePenaltyOverTrade = 15;
  static const int scorePenaltyLossLimitBreach = 20;
  static const int scorePenaltySkippedChecklist = 10;
  static const int scorePenaltyNegativeEmotionOverride = 12;
  static const int scoreRewardRuleFollowed = 5;
  static const int scoreRewardFullChecklist = 3;

  // ---------------- Emotions ----------------
  static const List<String> emotions = [
    'Calm',
    'Confident',
    'Fear',
    'Greed',
    'Revenge',
    'FOMO',
    'Frustration',
  ];

  static const List<String> negativeEmotions = [
    'Fear',
    'Greed',
    'Revenge',
    'FOMO',
    'Frustration',
  ];

  // ---------------- Trade checklist ----------------
  static const List<String> tradeChecklistItems = [
    'Trend direction confirmed',
    'Setup matches strategy',
    'Volume confirmation',
    'Risk reward ratio checked',
    'Stop loss defined',
    'Position size calculated',
  ];

  // ---------------- Trader levels (30-day challenge) ----------------
  static const List<String> traderLevels = [
    'Beginner',
    'Disciplined Trader',
    'Professional Trader',
    'Master Trader',
  ];

  /// Minimum cumulative discipline points required to reach each level,
  /// indices matching [traderLevels].
  static const List<int> traderLevelThresholds = [0, 150, 400, 800];
}

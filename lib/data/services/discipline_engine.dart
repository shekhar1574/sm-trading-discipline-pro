import '../../core/constants/app_constants.dart';
import '../models/discipline_settings.dart';
import '../models/trade_model.dart';
import 'database_service.dart';

/// The result of asking the Discipline Engine "can I trade right now?"
class DisciplineCheckResult {
  final bool allowed;
  final String reason;

  const DisciplineCheckResult({required this.allowed, required this.reason});

  static const ok = DisciplineCheckResult(allowed: true, reason: 'OK');
}

/// Rule-based system that decides, before every trade, whether the user
/// is allowed to proceed. This is intentionally deterministic (no AI)
/// so traders can always trust exactly why they were blocked.
class DisciplineEngine {
  final DatabaseService _db = DatabaseService.instance;

  /// Runs every hard rule in order and returns the first violation found,
  /// or [DisciplineCheckResult.ok] if the user may proceed.
  Future<DisciplineCheckResult> canTakeTrade(
      DisciplineSettings settings) async {
    final todayTrades = await _db.getTradesForToday();

    // Rule 1: Maximum trades per day
    if (todayTrades.length >= settings.maxTradesPerDay) {
      return DisciplineCheckResult(
        allowed: false,
        reason:
            'Daily trade limit reached (${settings.maxTradesPerDay} trades). '
            'Stop trading for today — protect your discipline score.',
      );
    }

    // Rule 2: Daily max loss limit
    final closedToday = todayTrades.where((t) => t.isClosed);
    final realizedPnlToday =
        closedToday.fold<double>(0, (sum, t) => sum + (t.pnl ?? 0));

    if (realizedPnlToday <= -settings.dailyMaxLossAmount) {
      return DisciplineCheckResult(
        allowed: false,
        reason:
            'Daily max loss limit hit (-₹${settings.dailyMaxLossAmount.toStringAsFixed(0)}). '
            'Trading is locked for the rest of the day.',
      );
    }

    // Rule 3: Daily profit target reached — encourage stopping while ahead
    if (realizedPnlToday >= settings.dailyProfitTargetAmount) {
      return DisciplineCheckResult(
        allowed: false,
        reason:
            'Daily profit target reached (+₹${settings.dailyProfitTargetAmount.toStringAsFixed(0)}). '
            'Lock in gains — avoid giving profits back.',
      );
    }

    // Rule 4: Cooldown period after the most recent trade
    if (todayTrades.isNotEmpty) {
      final lastTrade = todayTrades.first; // ordered DESC by createdAt
      final minutesSinceLast =
          DateTime.now().difference(lastTrade.createdAt).inMinutes;
      if (minutesSinceLast < settings.cooldownMinutes) {
        final remaining = settings.cooldownMinutes - minutesSinceLast;
        return DisciplineCheckResult(
          allowed: false,
          reason:
              'Cooldown active. Wait $remaining more minute(s) before your next trade.',
        );
      }
    }

    return DisciplineCheckResult.ok;
  }

  /// Computes the current discipline score (0-100) from the cumulative
  /// score log. Score is clamped so it always stays in range.
  Future<int> computeDisciplineScore() async {
    final delta = await _db.getCumulativeScoreDelta();
    final raw = AppConstants.scoreStartValue + delta;
    return raw.clamp(0, 100);
  }

  Future<void> rewardRuleFollowed(String reason) async {
    await _db.logScoreChange(AppConstants.scoreRewardRuleFollowed, reason);
  }

  Future<void> rewardChecklistCompleted() async {
    await _db.logScoreChange(
        AppConstants.scoreRewardFullChecklist, 'Full checklist completed');
  }

  Future<void> penalizeOverTrade() async {
    await _db.logScoreChange(
        -AppConstants.scorePenaltyOverTrade, 'Exceeded daily trade limit');
  }

  Future<void> penalizeLossLimitBreach() async {
    await _db.logScoreChange(-AppConstants.scorePenaltyLossLimitBreach,
        'Traded past daily loss limit');
  }

  Future<void> penalizeSkippedChecklist() async {
    await _db.logScoreChange(
        -AppConstants.scorePenaltySkippedChecklist, 'Skipped trade checklist');
  }

  Future<void> penalizeNegativeEmotionOverride() async {
    await _db.logScoreChange(
        -AppConstants.scorePenaltyNegativeEmotionOverride,
        'Traded through unresolved negative emotion');
  }

  /// Determines the trader's current level in the 30-Day Discipline
  /// Challenge from cumulative discipline points earned (separate track
  /// from the 0-100 score; points only ever accumulate upward).
  String traderLevelForPoints(int points) {
    String level = AppConstants.traderLevels.first;
    for (var i = 0; i < AppConstants.traderLevelThresholds.length; i++) {
      if (points >= AppConstants.traderLevelThresholds[i]) {
        level = AppConstants.traderLevels[i];
      }
    }
    return level;
  }

  /// Simple win-rate / analytics helper used by the Dashboard.
  Map<String, dynamic> summarize(List<TradeModel> trades) {
    final closed = trades.where((t) => t.isClosed).toList();
    final wins = closed.where((t) => t.isWin).length;
    final winRate = closed.isEmpty ? 0.0 : (wins / closed.length) * 100;
    final totalPnl = closed.fold<double>(0, (s, t) => s + (t.pnl ?? 0));
    final avgPnl = closed.isEmpty ? 0.0 : totalPnl / closed.length;

    return {
      'totalTrades': trades.length,
      'closedTrades': closed.length,
      'wins': wins,
      'winRate': winRate,
      'totalPnl': totalPnl,
      'avgPnl': avgPnl,
    };
  }

  /// Realized P&L grouped by calendar day (yyyy-mm-dd -> total pnl),
  /// used by the monthly P&L calendar screen.
  Map<String, double> dailyPnlMap(List<TradeModel> trades) {
    final map = <String, double>{};
    for (final t in trades.where((t) => t.isClosed)) {
      final key =
          '${t.createdAt.year}-${t.createdAt.month.toString().padLeft(2, '0')}-${t.createdAt.day.toString().padLeft(2, '0')}';
      map[key] = (map[key] ?? 0) + (t.pnl ?? 0);
    }
    return map;
  }

  /// Win rate / P&L broken down per market segment (Equity/F&O/Forex/Crypto).
  Map<String, Map<String, dynamic>> summarizeBySegment(
      List<TradeModel> trades) {
    final result = <String, Map<String, dynamic>>{};
    final segments = trades.map((t) => t.segment).toSet();
    for (final segment in segments) {
      final segTrades = trades.where((t) => t.segment == segment).toList();
      result[segment] = summarize(segTrades);
    }
    return result;
  }

  /// Groups closed trades by hour-of-day to find the trader's best and
  /// worst performing trading windows.
  Map<int, double> pnlByHourOfDay(List<TradeModel> trades) {
    final map = <int, double>{};
    for (final t in trades.where((t) => t.isClosed)) {
      final hour = t.createdAt.hour;
      map[hour] = (map[hour] ?? 0) + (t.pnl ?? 0);
    }
    return map;
  }

  /// Tally of free-text "mistakes made" entries, lower-cased and trimmed,
  /// to surface the most frequently repeated mistake.
  Map<String, int> commonMistakes(List<TradeModel> trades) {
    final tally = <String, int>{};
    for (final t in trades) {
      final mistake = t.mistakesMade?.trim();
      if (mistake == null || mistake.isEmpty) continue;
      final key = mistake.toLowerCase();
      tally[key] = (tally[key] ?? 0) + 1;
    }
    return tally;
  }

  /// Win rate / average P&L broken down by the emotion declared before
  /// each trade — the core "emotional trading analysis" metric.
  Map<String, Map<String, dynamic>> summarizeByEmotion(
      List<TradeModel> trades) {
    final result = <String, Map<String, dynamic>>{};
    final emotions = trades.map((t) => t.emotionBeforeTrade).toSet();
    for (final emotion in emotions) {
      final emoTrades =
          trades.where((t) => t.emotionBeforeTrade == emotion).toList();
      result[emotion] = summarize(emoTrades);
    }
    return result;
  }
}

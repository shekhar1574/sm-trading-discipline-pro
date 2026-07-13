import '../models/trade_model.dart';

/// Severity levels for a detected mistake pattern, driving the badge
/// color shown in the UI (High = red, Medium = amber, Low = grey).
enum MistakeSeverity { high, medium, low }

class MistakePattern {
  final String title;
  final String description;
  final int occurrences;
  final MistakeSeverity severity;
  final String suggestedFix;

  const MistakePattern({
    required this.title,
    required this.description,
    required this.occurrences,
    required this.severity,
    required this.suggestedFix,
  });
}

class AiTip {
  final String category; // Psychology, Strategy, Time/Session
  final String message;
  const AiTip({required this.category, required this.message});
}

/// Turns raw journal data into the same kind of behavioral analysis
/// shown in apps like TradeFix: categorized mistakes with severity and
/// a suggested fix, plus a short feed of AI coaching tips.
///
/// This is rule-based (not a real LLM call) — deterministic, explainable,
/// and free to run entirely on-device. It can be swapped later for an
/// LLM-backed FastAPI endpoint without changing how the UI consumes it.
class AnalyticsService {
  /// Scans trades and returns every mistake pattern found, ordered by
  /// occurrence count (most frequent first).
  List<MistakePattern> categorizeMistakes(List<TradeModel> trades) {
    if (trades.isEmpty) return [];

    final patterns = <MistakePattern>[];
    final total = trades.length;

    int countWhere(bool Function(TradeModel) test) =>
        trades.where(test).length;

    MistakeSeverity severityFor(int count) {
      final ratio = count / total;
      if (ratio >= 0.3) return MistakeSeverity.high;
      if (ratio >= 0.15) return MistakeSeverity.medium;
      return MistakeSeverity.low;
    }

    // 1. Revenge trading — trades taken while flagged "Revenge".
    final revengeCount = countWhere((t) => t.emotionBeforeTrade == 'Revenge');
    if (revengeCount > 0) {
      patterns.add(MistakePattern(
        title: 'Revenge Trading',
        description:
            'Trades taken immediately after losses to try to recover money.',
        occurrences: revengeCount,
        severity: severityFor(revengeCount),
        suggestedFix:
            'Stop trading after a loss. Review your journal before the next trade.',
      ));
    }

    // 2. FOMO trading.
    final fomoCount = countWhere((t) => t.emotionBeforeTrade == 'FOMO');
    if (fomoCount > 0) {
      patterns.add(MistakePattern(
        title: 'FOMO Trading',
        description: 'Entries or exits driven by fear of missing out.',
        occurrences: fomoCount,
        severity: severityFor(fomoCount),
        suggestedFix:
            'Wait for your setup to confirm. A missed trade costs nothing; a bad one does.',
      ));
    }

    // 3. General emotional trading — Fear, Greed, Frustration (Revenge/FOMO
    // already broken out above so they aren't double-counted here).
    final emotionalCount = countWhere((t) =>
        t.emotionBeforeTrade == 'Fear' ||
        t.emotionBeforeTrade == 'Greed' ||
        t.emotionBeforeTrade == 'Frustration');
    if (emotionalCount > 0) {
      patterns.add(MistakePattern(
        title: 'Emotional Trading',
        description:
            'Trades taken while frustrated, fearful, or greedy rather than calm.',
        occurrences: emotionalCount,
        severity: severityFor(emotionalCount),
        suggestedFix:
            'Trade only in a calm, neutral state. Add a cool-off rule after any strong emotion.',
      ));
    }

    // 4. Poor risk-reward — reward smaller than risk (R:R < 1.5).
    final poorRrCount = countWhere((t) => t.riskRewardRatio < 1.5 && t.riskRewardRatio > 0);
    if (poorRrCount > 0) {
      patterns.add(MistakePattern(
        title: 'Poor Risk-Reward Trades',
        description: 'Many trades have reward lower than 1.5x the risk taken.',
        occurrences: poorRrCount,
        severity: severityFor(poorRrCount),
        suggestedFix: 'Only take trades with a minimum 1:2 risk-reward ratio.',
      ));
    }

    // 5. Checklist skipped.
    final skippedCount = countWhere((t) => !t.checklistCompleted);
    if (skippedCount > 0) {
      patterns.add(MistakePattern(
        title: 'Checklist Skipped',
        description: 'Trades entered without confirming your full strategy checklist.',
        occurrences: skippedCount,
        severity: severityFor(skippedCount),
        suggestedFix: 'Complete every checklist item before entering — no exceptions.',
      ));
    }

    patterns.sort((a, b) => b.occurrences.compareTo(a.occurrences));
    return patterns;
  }

  /// Generates a short feed of AI coaching tips grouped loosely by
  /// category, similar to the "AI Tips" tab shown in reference apps.
  List<AiTip> generateTips(List<TradeModel> trades) {
    if (trades.isEmpty) {
      return const [
        AiTip(category: 'Psychology', message: 'Log a few trades to unlock personalized tips.')
      ];
    }

    final tips = <AiTip>[];
    final closed = trades.where((t) => t.isClosed).toList();

    // Psychology: emotion vs P&L correlation.
    final byEmotion = <String, List<double>>{};
    for (final t in closed) {
      byEmotion.putIfAbsent(t.emotionBeforeTrade, () => []).add(t.pnl ?? 0);
    }
    String? worstEmotion;
    double worstAvg = 0;
    byEmotion.forEach((emotion, pnls) {
      final avg = pnls.reduce((a, b) => a + b) / pnls.length;
      if (avg < worstAvg) {
        worstAvg = avg;
        worstEmotion = emotion;
      }
    });
    if (worstEmotion != null) {
      tips.add(AiTip(
        category: 'Psychology',
        message:
            "Mood affects your results. Your average loss is highest when trading in a '$worstEmotion' state — avoid trading then.",
      ));
    } else {
      tips.add(const AiTip(
        category: 'Psychology',
        message: "You're showing good discipline — no single emotion is dragging down your results right now.",
      ));
    }

    // Strategy: best vs worst strategy by win rate.
    final byStrategy = <String, List<TradeModel>>{};
    for (final t in closed) {
      byStrategy.putIfAbsent(t.strategy, () => []).add(t);
    }
    if (byStrategy.length > 1) {
      String? bestStrategy;
      double bestWinRate = -1;
      byStrategy.forEach((strategy, list) {
        final wins = list.where((t) => t.isWin).length;
        final winRate = wins / list.length;
        if (winRate > bestWinRate) {
          bestWinRate = winRate;
          bestStrategy = strategy;
        }
      });
      if (bestStrategy != null) {
        tips.add(AiTip(
          category: 'Strategy',
          message:
              '"$bestStrategy" is your strongest setup at ${(bestWinRate * 100).toStringAsFixed(0)}% win rate. Consider sizing up on high-confidence signals here.',
        ));
      }
    }

    // Time/Session: best trading hour.
    final byHour = <int, List<double>>{};
    for (final t in closed) {
      byHour.putIfAbsent(t.createdAt.hour, () => []).add(t.pnl ?? 0);
    }
    if (byHour.isNotEmpty) {
      int? bestHour;
      double bestTotal = double.negativeInfinity;
      byHour.forEach((hour, pnls) {
        final total = pnls.reduce((a, b) => a + b);
        if (total > bestTotal) {
          bestTotal = total;
          bestHour = hour;
        }
      });
      if (bestHour != null) {
        final label = bestHour! == 0
            ? '12 AM'
            : bestHour! < 12
                ? '$bestHour AM'
                : bestHour! == 12
                    ? '12 PM'
                    : '${bestHour! - 12} PM';
        tips.add(AiTip(
          category: 'Time/Session',
          message: 'Your most profitable trading window is around $label. Consider concentrating activity there.',
        ));
      }
    }

    return tips;
  }
}

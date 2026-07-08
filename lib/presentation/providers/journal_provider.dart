import 'package:flutter/foundation.dart';

import '../../data/models/emotion_entry.dart';
import '../../data/models/trade_model.dart';
import '../../data/services/database_service.dart';
import '../../data/services/discipline_engine.dart';

/// Manages the Trading Journal: adding trades, recording emotion
/// check-ins, and exposing analytics used by the Analytics Dashboard.
class JournalProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;
  final DisciplineEngine engine = DisciplineEngine();

  List<TradeModel> trades = [];
  bool loading = true;

  Future<void> loadTrades() async {
    loading = true;
    notifyListeners();
    trades = await _db.getAllTrades();
    loading = false;
    notifyListeners();
  }

  Future<void> addTrade(TradeModel trade, {required bool checklistCompleted}) async {
    await _db.insertTrade(trade);

    if (checklistCompleted) {
      await engine.rewardChecklistCompleted();
    } else {
      await engine.penalizeSkippedChecklist();
    }
    await engine.rewardRuleFollowed('Trade logged within daily limits');

    await loadTrades();
  }

  Future<void> closeTrade(TradeModel trade, double exitPrice) async {
    final updated = trade.copyWith(exitPrice: exitPrice);
    await _db.updateTrade(updated);
    await loadTrades();
  }

  Future<void> recordEmotionEntry(EmotionEntry entry) async {
    await _db.insertEmotionEntry(entry);
    if (entry.isNegative && !entry.cooldownCompleted) {
      await engine.penalizeNegativeEmotionOverride();
    }
    notifyListeners();
  }

  /// Feeds journal history into a lightweight rule-based "AI Coach"
  /// feedback string. See ai_coach_service if extended further.
  List<String> generateCoachFeedback() {
    if (trades.isEmpty) {
      return ['Log your first trade to start receiving discipline feedback.'];
    }

    final feedback = <String>[];
    final summary = engine.summarize(trades);
    final winRate = summary['winRate'] as double;

    if (winRate >= 60) {
      feedback.add('Strong win rate (${winRate.toStringAsFixed(0)}%). '
          'Your setup selection is working — keep following your checklist.');
    } else if (winRate > 0) {
      feedback.add('Win rate is ${winRate.toStringAsFixed(0)}%. '
          'Review your losing trades for recurring mistakes before your next session.');
    }

    final skippedChecklist =
        trades.where((t) => !t.checklistCompleted).length;
    if (skippedChecklist > 0) {
      feedback.add('You skipped the checklist on $skippedChecklist trade(s). '
          'Avoid entering positions without full confirmation.');
    }

    final negativeEmotionTrades = trades
        .where((t) => t.mistakesMade != null && t.mistakesMade!.isNotEmpty)
        .length;
    if (negativeEmotionTrades > 0) {
      feedback.add('$negativeEmotionTrades trade(s) logged with recorded mistakes. '
          'Revisit the lessons learned section before repeating the setup.');
    }

    if (feedback.isEmpty) {
      feedback.add('You followed your rules today. Your discipline score improved.');
    }

    return feedback;
  }
}

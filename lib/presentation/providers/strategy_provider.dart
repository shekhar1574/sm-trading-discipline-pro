import 'package:flutter/foundation.dart';

import '../../data/models/strategy_model.dart';
import '../../data/models/trade_model.dart';
import '../../data/services/database_service.dart';
import '../../data/services/discipline_engine.dart';

/// Performance stats for a single strategy, computed by matching
/// TradeModel.strategy against StrategyModel.name.
class StrategyPerformance {
  final StrategyModel strategy;
  final int tradeCount;
  final double winRate;
  final double netPnl;

  const StrategyPerformance({
    required this.strategy,
    required this.tradeCount,
    required this.winRate,
    required this.netPnl,
  });
}

class StrategyProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;
  final DisciplineEngine _engine = DisciplineEngine();

  List<StrategyModel> strategies = [];
  bool loading = true;

  Future<void> loadStrategies() async {
    loading = true;
    notifyListeners();
    final rows = await _db.getAllStrategies();
    strategies = rows.map((r) => StrategyModel.fromMap(r)).toList();
    loading = false;
    notifyListeners();
  }

  Future<void> addStrategy(StrategyModel strategy) async {
    await _db.insertStrategy(strategy.toMap());
    await loadStrategies();
  }

  Future<void> deleteStrategy(int id) async {
    await _db.deleteStrategy(id);
    await loadStrategies();
  }

  /// Computes trade count / win rate / net P&L for each strategy by
  /// matching on strategy name against the full trade list.
  List<StrategyPerformance> computePerformance(List<TradeModel> allTrades) {
    return strategies.map((s) {
      final matched = allTrades.where((t) => t.strategy.trim().toLowerCase() == s.name.trim().toLowerCase()).toList();
      final summary = _engine.summarize(matched);
      return StrategyPerformance(
        strategy: s,
        tradeCount: matched.length,
        winRate: summary['winRate'] as double,
        netPnl: summary['totalPnl'] as double,
      );
    }).toList();
  }
}

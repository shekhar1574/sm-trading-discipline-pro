import 'package:flutter/foundation.dart';

import '../../data/models/discipline_settings.dart';
import '../../data/models/trade_model.dart';
import '../../data/services/database_service.dart';
import '../../data/services/discipline_engine.dart';

/// Holds everything the Dashboard screen displays, and refreshes itself
/// whenever a trade or emotion entry is added elsewhere in the app.
class DashboardProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;
  final DisciplineEngine _engine = DisciplineEngine();

  DisciplineSettings settings = const DisciplineSettings(accountBalance: 100000);
  List<TradeModel> todaysTrades = [];
  int disciplineScore = 70;
  double todaysPnl = 0;
  double winRate = 0;
  int tradesTakenToday = 0;
  String currentEmotion = 'Calm';
  bool loading = true;

  Future<void> load() async {
    loading = true;
    notifyListeners();

    final savedSettings = await _db.getDisciplineSettings();
    if (savedSettings != null) settings = savedSettings;

    todaysTrades = await _db.getTradesForToday();
    final summary = _engine.summarize(todaysTrades);
    todaysPnl = summary['totalPnl'] as double;
    winRate = summary['winRate'] as double;
    tradesTakenToday = todaysTrades.length;
    disciplineScore = await _engine.computeDisciplineScore();

    final emotions = await _db.getAllEmotionEntries();
    if (emotions.isNotEmpty) currentEmotion = emotions.first.emotion;

    loading = false;
    notifyListeners();
  }

  Future<void> updateSettings(DisciplineSettings newSettings) async {
    settings = newSettings;
    await _db.saveDisciplineSettings(newSettings);
    notifyListeners();
  }
}

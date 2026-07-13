/// A single trade journal entry.
/// This maps 1:1 to the `trades` SQLite table (see database_service.dart).
class TradeModel {
  final int? id;
  final String symbol;
  final double entryPrice;
  final double? exitPrice;
  final double stopLoss;
  final double target;
  final int quantity;
  final String strategy;
  final String? screenshotPath;
  final String emotionBeforeTrade;
  final String? mistakesMade;
  final String? lessonsLearned;
  final bool checklistCompleted;
  final DateTime createdAt;

  /// Market segment this trade belongs to: Equity, F&O, Forex, or Crypto.
  /// Defaults to 'Equity' for backward compatibility with trades logged
  /// before multi-segment tracking was added.
  final String segment;

  /// True if this trade's fill/exit came from a live broker sync
  /// (Fyers, Zerodha, etc.) rather than manual journal entry.
  final bool fromBroker;

  TradeModel({
    this.id,
    required this.symbol,
    required this.entryPrice,
    this.exitPrice,
    required this.stopLoss,
    required this.target,
    required this.quantity,
    required this.strategy,
    this.screenshotPath,
    required this.emotionBeforeTrade,
    this.mistakesMade,
    this.lessonsLearned,
    this.checklistCompleted = false,
    this.segment = 'Equity',
    this.fromBroker = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Realized P&L for this trade. Null while the position is still open
  /// (exitPrice not yet recorded).
  double? get pnl {
    if (exitPrice == null) return null;
    return (exitPrice! - entryPrice) * quantity;
  }

  /// Risk:Reward ratio computed from entry, stop loss and target.
  double get riskRewardRatio {
    final risk = (entryPrice - stopLoss).abs();
    final reward = (target - entryPrice).abs();
    if (risk == 0) return 0;
    return reward / risk;
  }

  bool get isWin => (pnl ?? 0) > 0;
  bool get isClosed => exitPrice != null;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'symbol': symbol,
      'entryPrice': entryPrice,
      'exitPrice': exitPrice,
      'stopLoss': stopLoss,
      'target': target,
      'quantity': quantity,
      'strategy': strategy,
      'screenshotPath': screenshotPath,
      'emotionBeforeTrade': emotionBeforeTrade,
      'mistakesMade': mistakesMade,
      'lessonsLearned': lessonsLearned,
      'checklistCompleted': checklistCompleted ? 1 : 0,
      'segment': segment,
      'fromBroker': fromBroker ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory TradeModel.fromMap(Map<String, dynamic> map) {
    return TradeModel(
      id: map['id'] as int?,
      symbol: map['symbol'] as String,
      entryPrice: (map['entryPrice'] as num).toDouble(),
      exitPrice: map['exitPrice'] == null ? null : (map['exitPrice'] as num).toDouble(),
      stopLoss: (map['stopLoss'] as num).toDouble(),
      target: (map['target'] as num).toDouble(),
      quantity: map['quantity'] as int,
      strategy: map['strategy'] as String,
      screenshotPath: map['screenshotPath'] as String?,
      emotionBeforeTrade: map['emotionBeforeTrade'] as String,
      mistakesMade: map['mistakesMade'] as String?,
      lessonsLearned: map['lessonsLearned'] as String?,
      checklistCompleted: (map['checklistCompleted'] as int) == 1,
      segment: (map['segment'] as String?) ?? 'Equity',
      fromBroker: ((map['fromBroker'] as int?) ?? 0) == 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  TradeModel copyWith({
    double? exitPrice,
    String? mistakesMade,
    String? lessonsLearned,
  }) {
    return TradeModel(
      id: id,
      symbol: symbol,
      entryPrice: entryPrice,
      exitPrice: exitPrice ?? this.exitPrice,
      stopLoss: stopLoss,
      target: target,
      quantity: quantity,
      strategy: strategy,
      screenshotPath: screenshotPath,
      emotionBeforeTrade: emotionBeforeTrade,
      mistakesMade: mistakesMade ?? this.mistakesMade,
      lessonsLearned: lessonsLearned ?? this.lessonsLearned,
      checklistCompleted: checklistCompleted,
      segment: segment,
      fromBroker: fromBroker,
      createdAt: createdAt,
    );
  }
}

/// A named trading strategy/setup (e.g. "VWAP Reclaim", "ICT", "4H Breakout").
/// Trades reference a strategy by name (TradeModel.strategy), and this
/// model lets the user maintain a description, target R:R, and status
/// for each one, with performance computed on the fly by joining against
/// the trades table (see StrategyProvider).
class StrategyModel {
  final int? id;
  final String name;
  final String description;
  final double targetRiskReward;
  final String segment; // Equity, F&O, Forex, Crypto
  final bool isActive; // false = Draft
  final DateTime createdAt;

  StrategyModel({
    this.id,
    required this.name,
    this.description = '',
    this.targetRiskReward = 2.0,
    this.segment = 'Equity',
    this.isActive = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'targetRiskReward': targetRiskReward,
      'segment': segment,
      'isActive': isActive ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory StrategyModel.fromMap(Map<String, dynamic> map) {
    return StrategyModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: (map['description'] as String?) ?? '',
      targetRiskReward: (map['targetRiskReward'] as num).toDouble(),
      segment: (map['segment'] as String?) ?? 'Equity',
      isActive: (map['isActive'] as int) == 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}

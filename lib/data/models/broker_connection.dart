/// Represents an active (or inactive) broker connection. Access tokens
/// are handled by [BrokerService] implementations, not stored on this
/// model directly, so this stays safe to pass around the UI layer.
class BrokerConnection {
  final String brokerName;
  final bool isConnected;
  final DateTime? connectedAt;

  const BrokerConnection({
    required this.brokerName,
    required this.isConnected,
    this.connectedAt,
  });

  static const disconnected =
      BrokerConnection(brokerName: '', isConnected: false);
}

/// A single live position/holding pulled from a connected broker.
class BrokerPosition {
  final String symbol;
  final int quantity;
  final double avgPrice;
  final double lastTradedPrice;
  final double pnl;
  final String segment; // Equity, F&O, Forex, Crypto

  const BrokerPosition({
    required this.symbol,
    required this.quantity,
    required this.avgPrice,
    required this.lastTradedPrice,
    required this.pnl,
    required this.segment,
  });

  factory BrokerPosition.fromJson(Map<String, dynamic> json) {
    return BrokerPosition(
      symbol: json['symbol'] as String,
      quantity: (json['quantity'] as num).toInt(),
      avgPrice: (json['avgPrice'] as num).toDouble(),
      lastTradedPrice: (json['lastTradedPrice'] as num).toDouble(),
      pnl: (json['pnl'] as num).toDouble(),
      segment: (json['segment'] as String?) ?? 'Equity',
    );
  }
}

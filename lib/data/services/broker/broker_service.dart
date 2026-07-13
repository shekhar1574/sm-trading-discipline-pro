import '../../models/broker_connection.dart';

/// Common contract every broker integration must satisfy. The UI and
/// providers only ever talk to this interface, never to a specific
/// broker's SDK/API directly — that's what makes adding Zerodha, Angel
/// One, Upstox, or Dhan later a matter of writing one new class rather
/// than touching any screen.
abstract class BrokerService {
  String get brokerName;

  /// Returns the URL the user should open (in a browser / webview) to
  /// log in to their broker account and grant access. The broker
  /// redirects back to our FastAPI backend's callback URL after login.
  String buildLoginUrl();

  /// Called after the user completes login and the backend has
  /// exchanged the auth code for an access token. [authCode] is
  /// whatever identifier the backend needs to look up that token
  /// (Phase 1 scaffolding: the backend hands back a session token here).
  Future<String> completeLogin(String authCode);

  /// True if we currently hold a usable access token for this broker.
  Future<bool> isConnected();

  /// Fetches live open positions with real-time P&L. Throws if not
  /// connected or if the broker session has expired.
  Future<List<BrokerPosition>> getLivePositions();

  /// Total live P&L across all open positions — the headline number
  /// the Dashboard shows when a broker is connected.
  Future<double> getLiveTotalPnl();

  Future<void> disconnect();
}

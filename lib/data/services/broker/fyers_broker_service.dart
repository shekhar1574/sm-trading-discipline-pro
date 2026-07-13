import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../core/constants/backend_config.dart';
import '../../models/broker_connection.dart';
import '../database_service.dart';
import 'broker_service.dart';

/// Fyers integration. All the sensitive work (OAuth token exchange,
/// storing the Fyers app secret, calling Fyers' actual REST API) happens
/// in the FastAPI backend — this class is a thin client that calls our
/// own backend's /broker/fyers/* endpoints, never Fyers directly, so the
/// Fyers client secret never has to touch the mobile app.
class FyersBrokerService implements BrokerService {
  final DatabaseService _db = DatabaseService.instance;

  @override
  String get brokerName => 'Fyers';

  @override
  String buildLoginUrl() {
    // The backend owns the actual Fyers app_id/redirect_uri and builds
    // the real Fyers login URL; we just point the user at our backend's
    // /broker/fyers/login endpoint, which 302-redirects to Fyers.
    return '${BackendConfig.baseUrl}/broker/fyers/login';
  }

  @override
  Future<String> completeLogin(String authCode) async {
    final resp = await http.post(
      Uri.parse('${BackendConfig.baseUrl}/broker/fyers/callback'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'auth_code': authCode}),
    );

    if (resp.statusCode != 200) {
      throw Exception('Fyers login failed: ${resp.body}');
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final sessionToken = data['session_token'] as String;
    await _db.saveBrokerConnection(brokerName, sessionToken);
    return sessionToken;
  }

  @override
  Future<bool> isConnected() async {
    final conn = await _db.getActiveBrokerConnection();
    return conn != null && conn['brokerName'] == brokerName;
  }

  Future<String> _requireToken() async {
    final conn = await _db.getActiveBrokerConnection();
    if (conn == null || conn['brokerName'] != brokerName) {
      throw Exception('Fyers is not connected. Connect it in Settings first.');
    }
    return conn['accessToken'] as String;
  }

  @override
  Future<List<BrokerPosition>> getLivePositions() async {
    final token = await _requireToken();
    final resp = await http.get(
      Uri.parse('${BackendConfig.baseUrl}/broker/fyers/positions'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (resp.statusCode != 200) {
      throw Exception('Could not fetch live positions: ${resp.body}');
    }

    final list = jsonDecode(resp.body) as List<dynamic>;
    return list
        .map((e) => BrokerPosition.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<double> getLiveTotalPnl() async {
    final positions = await getLivePositions();
    return positions.fold<double>(0, (sum, p) => sum + p.pnl);
  }

  @override
  Future<void> disconnect() async {
    await _db.disconnectBroker();
  }
}

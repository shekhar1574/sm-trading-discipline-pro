import 'package:flutter/foundation.dart';

import '../../core/constants/backend_config.dart';
import '../../data/models/broker_connection.dart';
import '../../data/services/broker/broker_service.dart';
import '../../data/services/broker/fyers_broker_service.dart';

class BrokerProvider extends ChangeNotifier {
  // Registry of available broker integrations. Adding Zerodha/Angel One
  // later is: write a XyzBrokerService implementing BrokerService, add
  // it here — no screen changes needed.
  final Map<String, BrokerService> _services = {
    'Fyers': FyersBrokerService(),
  };

  BrokerService? activeService;
  bool connected = false;
  bool loading = false;
  List<BrokerPosition> livePositions = [];
  double liveTotalPnl = 0;
  String? error;

  bool get backendConfigured => BackendConfig.isConfigured;

  Future<void> checkConnection(String brokerName) async {
    final service = _services[brokerName];
    if (service == null) return;
    activeService = service;
    connected = await service.isConnected();
    notifyListeners();
  }

  Future<void> connectBroker(String brokerName) async {
    activeService = _services[brokerName];
    notifyListeners();
    // Actual login happens via buildLoginUrl() opened in a browser/
    // webview by the UI layer; this provider just tracks resulting state.
  }

  Future<void> refreshLivePnl() async {
    if (activeService == null || !connected) return;
    loading = true;
    error = null;
    notifyListeners();

    try {
      livePositions = await activeService!.getLivePositions();
      liveTotalPnl = livePositions.fold<double>(0, (s, p) => s + p.pnl);
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> disconnect() async {
    if (activeService == null) return;
    await activeService!.disconnect();
    connected = false;
    livePositions = [];
    liveTotalPnl = 0;
    notifyListeners();
  }
}

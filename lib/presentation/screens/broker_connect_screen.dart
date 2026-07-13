import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/broker_connection.dart';
import '../providers/broker_provider.dart';

/// Broker connection hub. Phase 1 ships with Fyers; the layout is built
/// so additional brokers (Zerodha, Angel One, Upstox, Dhan) can be added
/// as more cards without restructuring this screen.
class BrokerConnectScreen extends StatefulWidget {
  const BrokerConnectScreen({super.key});

  @override
  State<BrokerConnectScreen> createState() => _BrokerConnectScreenState();
}

class _BrokerConnectScreenState extends State<BrokerConnectScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final broker = context.read<BrokerProvider>();
      await broker.checkConnection('Fyers');
      if (broker.connected) broker.refreshLivePnl();
    });
  }

  Future<void> _connectFyers(BrokerProvider broker) async {
    await broker.connectBroker('Fyers');
    final url = broker.activeService!.buildLoginUrl();
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    // After the user logs in on Fyers' site, the backend redirect
    // flow completes the connection server-side. Pull-to-refresh below
    // re-checks connection status once they return to the app.
  }

  @override
  Widget build(BuildContext context) {
    final broker = context.watch<BrokerProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Connect Broker')),
      body: RefreshIndicator(
        onRefresh: () async {
          await broker.checkConnection('Fyers');
          if (broker.connected) await broker.refreshLivePnl();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (!broker.backendConfigured) _backendNotConfiguredBanner(),
            const SizedBox(height: 12),
            _fyersCard(broker),
            const SizedBox(height: 16),
            if (broker.connected) _livePositionsCard(broker),
            const SizedBox(height: 16),
            _comingSoonRow(),
          ],
        ),
      ),
    );
  }

  Widget _backendNotConfiguredBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.warning, size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Backend not configured yet. Deploy /backend and set the URL '
              'in lib/core/constants/backend_config.dart to enable live broker sync.',
              style: TextStyle(color: AppColors.warning, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fyersCard(BrokerProvider broker) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: broker.connected ? AppColors.profit.withValues(alpha: 0.5) : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.account_balance_outlined, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Fyers', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  broker.connected ? 'Connected \u2022 Live P&L syncing' : 'Not connected',
                  style: TextStyle(
                    fontSize: 12,
                    color: broker.connected ? AppColors.profit : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          broker.connected
              ? OutlinedButton(
                  onPressed: () => broker.disconnect(),
                  child: const Text('Disconnect'),
                )
              : ElevatedButton(
                  onPressed: broker.backendConfigured ? () => _connectFyers(broker) : null,
                  child: const Text('Connect'),
                ),
        ],
      ),
    );
  }

  Widget _livePositionsCard(BrokerProvider broker) {
    if (broker.loading) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(20),
        child: CircularProgressIndicator(),
      ));
    }

    if (broker.error != null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.loss.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(broker.error!, style: const TextStyle(color: AppColors.loss, fontSize: 12)),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Live Positions', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              Text(
                '${broker.liveTotalPnl >= 0 ? '+' : ''}₹${broker.liveTotalPnl.toStringAsFixed(0)}',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: broker.liveTotalPnl >= 0 ? AppColors.profit : AppColors.loss,
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: AppColors.border),
          if (broker.livePositions.isEmpty)
            const Text('No open positions right now.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12))
          else
            ...broker.livePositions.map((p) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(p.symbol, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      Text(
                        '${p.pnl >= 0 ? '+' : ''}₹${p.pnl.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: p.pnl >= 0 ? AppColors.profit : AppColors.loss,
                        ),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  Widget _comingSoonRow() {
    const brokers = ['Zerodha', 'Angel One', 'Upstox', 'Dhan'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('More brokers', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: brokers
              .map((b) => Chip(
                    label: Text(b, style: const TextStyle(fontSize: 12)),
                    avatar: const Icon(Icons.hourglass_empty, size: 14),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

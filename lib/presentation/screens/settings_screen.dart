import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/discipline_settings.dart';
import '../providers/dashboard_provider.dart';

/// Lets the trader configure account balance and discipline rules:
/// max trades/day, daily loss limit, profit target, cooldown period.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _balanceCtrl;
  late TextEditingController _maxTradesCtrl;
  late TextEditingController _maxLossCtrl;
  late TextEditingController _profitTargetCtrl;
  late TextEditingController _cooldownCtrl;

  @override
  void initState() {
    super.initState();
    final settings = context.read<DashboardProvider>().settings;
    _balanceCtrl = TextEditingController(text: settings.accountBalance.toStringAsFixed(0));
    _maxTradesCtrl = TextEditingController(text: settings.maxTradesPerDay.toString());
    _maxLossCtrl = TextEditingController(text: settings.dailyMaxLossPercent.toString());
    _profitTargetCtrl = TextEditingController(text: settings.dailyProfitTargetPercent.toString());
    _cooldownCtrl = TextEditingController(text: settings.cooldownMinutes.toString());
  }

  @override
  void dispose() {
    _balanceCtrl.dispose();
    _maxTradesCtrl.dispose();
    _maxLossCtrl.dispose();
    _profitTargetCtrl.dispose();
    _cooldownCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final newSettings = DisciplineSettings(
      accountBalance: double.tryParse(_balanceCtrl.text) ?? 100000,
      maxTradesPerDay: int.tryParse(_maxTradesCtrl.text) ?? 2,
      dailyMaxLossPercent: double.tryParse(_maxLossCtrl.text) ?? 2.0,
      dailyProfitTargetPercent: double.tryParse(_profitTargetCtrl.text) ?? 3.0,
      cooldownMinutes: int.tryParse(_cooldownCtrl.text) ?? 15,
    );
    await context.read<DashboardProvider>().updateSettings(newSettings);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Discipline rules updated')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Discipline Rules')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _field(_balanceCtrl, 'Account Balance (₹)'),
          _field(_maxTradesCtrl, 'Max Trades Per Day'),
          _field(_maxLossCtrl, 'Daily Max Loss (%)'),
          _field(_profitTargetCtrl, 'Daily Profit Target (%)'),
          _field(_cooldownCtrl, 'Cooldown Between Trades (minutes)'),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(onPressed: _save, child: const Text('Save Rules')),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              AppConstants.appVersion,
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: ctrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}

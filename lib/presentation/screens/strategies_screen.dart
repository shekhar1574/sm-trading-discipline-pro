import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/strategy_model.dart';
import '../providers/journal_provider.dart';
import '../providers/strategy_provider.dart';

class StrategiesScreen extends StatefulWidget {
  const StrategiesScreen({super.key});

  @override
  State<StrategiesScreen> createState() => _StrategiesScreenState();
}

class _StrategiesScreenState extends State<StrategiesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StrategyProvider>().loadStrategies();
      context.read<JournalProvider>().loadTrades();
    });
  }

  void _openAddStrategySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _AddStrategySheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strategyProvider = context.watch<StrategyProvider>();
    final journal = context.watch<JournalProvider>();
    final performances = strategyProvider.computePerformance(journal.trades);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Strategies'),
        actions: [
          TextButton.icon(
            onPressed: _openAddStrategySheet,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add'),
          ),
        ],
      ),
      body: strategyProvider.loading
          ? const Center(child: CircularProgressIndicator())
          : performances.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('No strategies yet.', style: TextStyle(color: AppColors.textSecondary)),
                        const SizedBox(height: 12),
                        ElevatedButton(onPressed: _openAddStrategySheet, child: const Text('Add your first strategy')),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: performances.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => _strategyCard(performances[index]),
                ),
    );
  }

  Widget _strategyCard(dynamic perf) {
    final strategy = perf.strategy as StrategyModel;
    final winRate = perf.winRate as double;
    final netPnl = perf.netPnl as double;
    final tradeCount = perf.tradeCount as int;

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
            children: [
              Expanded(
                child: Text(strategy.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (strategy.isActive ? AppColors.profit : AppColors.textMuted).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  strategy.isActive ? 'Active' : 'Draft',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: strategy.isActive ? AppColors.profit : AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
          if (strategy.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(strategy.description, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              _tag('${strategy.segment}', AppColors.primary),
              const SizedBox(width: 6),
              _tag('R:R ${strategy.targetRiskReward.toStringAsFixed(1)}', AppColors.accentGold),
            ],
          ),
          const Divider(height: 24, color: AppColors.border),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _miniStat('Trades', tradeCount == 0 ? 'No trades' : '$tradeCount'),
              _miniStat('Win rate', tradeCount == 0 ? '—' : '${winRate.toStringAsFixed(0)}%'),
              _miniStat(
                'Net P&L',
                tradeCount == 0 ? '—' : '${netPnl >= 0 ? '+' : ''}₹${netPnl.toStringAsFixed(0)}',
                color: tradeCount == 0 ? null : (netPnl >= 0 ? AppColors.profit : AppColors.loss),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }

  Widget _tag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

class _AddStrategySheet extends StatefulWidget {
  const _AddStrategySheet();

  @override
  State<_AddStrategySheet> createState() => _AddStrategySheetState();
}

class _AddStrategySheetState extends State<_AddStrategySheet> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _rrCtrl = TextEditingController(text: '2.0');
  String _segment = AppConstants.marketSegments.first;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _rrCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    final strategy = StrategyModel(
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      targetRiskReward: double.tryParse(_rrCtrl.text) ?? 2.0,
      segment: _segment,
    );
    await context.read<StrategyProvider>().addStrategy(strategy);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('New Strategy', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Strategy name (e.g. VWAP Reclaim)'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descCtrl,
            decoration: const InputDecoration(labelText: 'Description / entry rule (optional)'),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _rrCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Target Risk:Reward (e.g. 2.0)'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _segment,
            decoration: const InputDecoration(labelText: 'Market segment'),
            dropdownColor: AppColors.surfaceElevated,
            items: AppConstants.marketSegments
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (v) => setState(() => _segment = v ?? _segment),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(onPressed: _save, child: const Text('Save Strategy')),
          ),
        ],
      ),
    );
  }
}

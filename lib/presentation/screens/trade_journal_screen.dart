import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/trade_model.dart';
import '../providers/journal_provider.dart';

class TradeJournalScreen extends StatefulWidget {
  const TradeJournalScreen({super.key});

  @override
  State<TradeJournalScreen> createState() => _TradeJournalScreenState();
}

class _TradeJournalScreenState extends State<TradeJournalScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JournalProvider>().loadTrades();
    });
  }

  @override
  Widget build(BuildContext context) {
    final journal = context.watch<JournalProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Trading Journal')),
      body: journal.loading
          ? const Center(child: CircularProgressIndicator())
          : journal.trades.isEmpty
              ? const Center(
                  child: Text('No trades logged yet.',
                      style: TextStyle(color: AppColors.textSecondary)))
              : RefreshIndicator(
                  onRefresh: journal.loadTrades,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _coachCard(journal),
                      const SizedBox(height: 16),
                      ...journal.trades.map(_tradeCard),
                    ],
                  ),
                ),
    );
  }

  Widget _coachCard(JournalProvider journal) {
    final feedback = journal.generateCoachFeedback();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.smart_toy_outlined, color: AppColors.primary, size: 18),
              SizedBox(width: 8),
              Text('AI Trading Coach',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 10),
          ...feedback.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('• $f', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              )),
        ],
      ),
    );
  }

  Widget _tradeCard(TradeModel trade) {
    final pnl = trade.pnl;
    final pnlColor = pnl == null
        ? AppColors.textMuted
        : (pnl >= 0 ? AppColors.profit : AppColors.loss);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(trade.symbol,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
              Text(
                pnl == null ? 'OPEN' : '${pnl >= 0 ? '+' : ''}₹${pnl.toStringAsFixed(0)}',
                style: TextStyle(color: pnlColor, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(DateFormat('dd MMM yyyy, hh:mm a').format(trade.createdAt),
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              _miniStat('Entry', trade.entryPrice.toStringAsFixed(2)),
              _miniStat('SL', trade.stopLoss.toStringAsFixed(2)),
              _miniStat('Target', trade.target.toStringAsFixed(2)),
              _miniStat('Qty', trade.quantity.toString()),
              _miniStat('R:R', '1:${trade.riskRewardRatio.toStringAsFixed(1)}'),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _tag(trade.strategy, AppColors.primary),
              const SizedBox(width: 6),
              _tag(trade.emotionBeforeTrade,
                  trade.emotionBeforeTrade == 'Calm' || trade.emotionBeforeTrade == 'Confident'
                      ? AppColors.profit
                      : AppColors.loss),
              const SizedBox(width: 6),
              if (!trade.checklistCompleted)
                _tag('Checklist skipped', AppColors.warning),
            ],
          ),
          if (trade.screenshotPath != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(File(trade.screenshotPath!), height: 120, fit: BoxFit.cover),
            ),
          ],
          if (trade.mistakesMade != null) ...[
            const SizedBox(height: 8),
            Text('Mistake: ${trade.mistakesMade}',
                style: const TextStyle(fontSize: 12, color: AppColors.loss)),
          ],
          if (trade.lessonsLearned != null) ...[
            const SizedBox(height: 4),
            Text('Lesson: ${trade.lessonsLearned}',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _tag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

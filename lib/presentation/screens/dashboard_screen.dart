import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/discipline_gauge.dart';
import '../widgets/stat_card.dart';
import 'emotion_check_screen.dart';
import 'settings_screen.dart';
import 'trade_journal_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashboardProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppConstants.appName,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            Text(AppConstants.appTagline,
                style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.accentGold,
                    fontWeight: FontWeight.w500)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: provider.loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: provider.load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _disciplineSection(provider),
                  const SizedBox(height: 20),
                  _statsGrid(provider),
                  const SizedBox(height: 20),
                  _tradeLimitBanner(provider),
                  const SizedBox(height: 24),
                  _actionButtons(context),
                ],
              ),
            ),
    );
  }

  Widget _disciplineSection(DashboardProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          DisciplineGauge(score: provider.disciplineScore),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Current Emotional Status',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text(provider.currentEmotion,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Text(
                  provider.disciplineScore >= 75
                      ? 'Excellent control today. Keep following your plan.'
                      : provider.disciplineScore >= 45
                          ? 'Some rule breaks detected. Stay sharp.'
                          : 'Discipline is slipping. Review your rules before your next trade.',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statsGrid(DashboardProvider provider) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        StatCard(
          label: 'Account Balance',
          value: '₹${provider.settings.accountBalance.toStringAsFixed(0)}',
          icon: Icons.account_balance_wallet_outlined,
        ),
        StatCard(
          label: "Today's P&L",
          value:
              '${provider.todaysPnl >= 0 ? '+' : ''}₹${provider.todaysPnl.toStringAsFixed(0)}',
          icon: Icons.show_chart,
          valueColor: provider.todaysPnl >= 0 ? AppColors.profit : AppColors.loss,
        ),
        StatCard(
          label: 'Win Rate',
          value: '${provider.winRate.toStringAsFixed(0)}%',
          icon: Icons.emoji_events_outlined,
        ),
        StatCard(
          label: 'Trades Today',
          value: '${provider.tradesTakenToday} / ${provider.settings.maxTradesPerDay}',
          icon: Icons.receipt_long_outlined,
        ),
      ],
    );
  }

  Widget _tradeLimitBanner(DashboardProvider provider) {
    final reached = provider.tradesTakenToday >= provider.settings.maxTradesPerDay;
    if (!reached) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.loss.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.loss.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: const [
          Icon(Icons.block, color: AppColors.loss, size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Daily trade limit reached. Trading is locked for today.',
              style: TextStyle(color: AppColors.loss, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.psychology_outlined),
            label: const Text('Start New Trade (Emotion Check)'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const EmotionCheckScreen()),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.menu_book_outlined),
            label: const Text('View Trading Journal'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TradeJournalScreen()),
            ),
          ),
        ),
      ],
    );
  }
}

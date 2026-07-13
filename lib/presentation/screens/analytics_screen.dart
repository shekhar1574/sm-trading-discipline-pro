import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../data/services/analytics_service.dart';
import '../providers/journal_provider.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  final _analytics = AnalyticsService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JournalProvider>().loadTrades();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final journal = context.watch<JournalProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Analytics'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.textPrimary,
          unselectedLabelColor: AppColors.textMuted,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Your Mistakes'),
            Tab(text: 'AI Tips'),
          ],
        ),
      ),
      body: journal.loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _overviewTab(journal),
                _mistakesTab(journal),
                _tipsTab(journal),
              ],
            ),
    );
  }

  // ---------------- Overview tab: weekday P&L + win/loss gauge ----------------

  Widget _overviewTab(JournalProvider journal) {
    final summary = journal.engine.summarize(journal.trades);
    final weekdayTotals = List<double>.filled(7, 0); // Mon..Sun
    for (final t in journal.trades.where((t) => t.isClosed)) {
      final idx = t.createdAt.weekday - 1; // Monday=0
      weekdayTotals[idx] += t.pnl ?? 0;
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _statsRow(summary),
        const SizedBox(height: 20),
        _card(
          title: 'Weekday P&L',
          child: SizedBox(
            height: 180,
            child: journal.trades.isEmpty
                ? const Center(child: Text('No trades yet', style: TextStyle(color: AppColors.textMuted)))
                : _weekdayBarChart(weekdayTotals),
          ),
        ),
        const SizedBox(height: 16),
        _card(
          title: 'Most Traded Symbols',
          child: _mostTradedList(journal),
        ),
      ],
    );
  }

  Widget _statsRow(Map<String, dynamic> summary) {
    final winRate = summary['winRate'] as double;
    final totalPnl = summary['totalPnl'] as double;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem('Trades', '${summary['totalTrades']}'),
          _statItem('Win Rate', '${winRate.toStringAsFixed(0)}%'),
          _statItem(
            'Net P&L',
            '${totalPnl >= 0 ? '+' : ''}₹${totalPnl.toStringAsFixed(0)}',
            color: totalPnl >= 0 ? AppColors.profit : AppColors.loss,
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color ?? AppColors.textPrimary)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _weekdayBarChart(List<double> totals) {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final maxVal = totals.fold<double>(1, (m, v) => v.abs() > m ? v.abs() : m);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxVal * 1.2,
        minY: -maxVal * 1.2,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) => Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(labels[value.toInt() % 7],
                    style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
              ),
            ),
          ),
        ),
        barGroups: List.generate(7, (i) {
          final v = totals[i];
          return BarChartGroupData(x: i, barRods: [
            BarChartRodData(
              toY: v,
              color: v >= 0 ? AppColors.profit : AppColors.loss,
              width: 18,
              borderRadius: BorderRadius.circular(4),
            ),
          ]);
        }),
      ),
    );
  }

  Widget _mostTradedList(JournalProvider journal) {
    final counts = <String, int>{};
    for (final t in journal.trades) {
      counts[t.symbol] = (counts[t.symbol] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(5).toList();

    if (top.isEmpty) {
      return const Text('No trades yet', style: TextStyle(color: AppColors.textMuted));
    }

    return Column(
      children: top
          .map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(e.key, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text('${e.value} trades', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ))
          .toList(),
    );
  }

  // ---------------- Mistakes tab ----------------

  Widget _mistakesTab(JournalProvider journal) {
    final mistakes = _analytics.categorizeMistakes(journal.trades);

    if (mistakes.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No recurring mistake patterns detected yet. Keep logging trades honestly — this improves as your journal grows.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: mistakes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _mistakeCard(mistakes[index]),
    );
  }

  Widget _mistakeCard(MistakePattern m) {
    final (color, label) = switch (m.severity) {
      MistakeSeverity.high => (AppColors.loss, 'HIGH'),
      MistakeSeverity.medium => (AppColors.warning, 'MEDIUM'),
      MistakeSeverity.low => (AppColors.textMuted, 'LOW'),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
                child: Text('${m.occurrences}', style: TextStyle(color: color, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(m.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                child: Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(m.description, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
            child: Row(
              children: [
                Icon(Icons.auto_fix_high, size: 14, color: color),
                const SizedBox(width: 8),
                Expanded(child: Text(m.suggestedFix, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- AI Tips tab ----------------

  Widget _tipsTab(JournalProvider journal) {
    final tips = _analytics.generateTips(journal.trades);

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: tips.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final tip = tips[index];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.lightbulb_outline, size: 18, color: AppColors.accentGold),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tip.category,
                        style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(tip.message, style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _card({required String title, required Widget child}) {
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
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../providers/journal_provider.dart';

/// Day-by-day P&L calendar, matching the "Monthly P&L Calendar" pattern
/// traders expect from tools like TradeFix. Green/red intensity reflects
/// the size of that day's realized P&L.
class PnlCalendarScreen extends StatefulWidget {
  const PnlCalendarScreen({super.key});

  @override
  State<PnlCalendarScreen> createState() => _PnlCalendarScreenState();
}

class _PnlCalendarScreenState extends State<PnlCalendarScreen> {
  DateTime _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JournalProvider>().loadTrades();
    });
  }

  void _changeMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    });
  }

  @override
  Widget build(BuildContext context) {
    final journal = context.watch<JournalProvider>();
    final dailyPnl = journal.engine.dailyPnlMap(journal.trades);

    final firstDayOfMonth = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    final daysInMonth =
        DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;
    // Monday = 0 ... Sunday = 6, for grid alignment.
    final leadingBlanks = (firstDayOfMonth.weekday - 1) % 7;

    double monthTotal = 0;
    for (var d = 1; d <= daysInMonth; d++) {
      final key =
          '${_visibleMonth.year}-${_visibleMonth.month.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
      monthTotal += dailyPnl[key] ?? 0;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('P&L Calendar')),
      body: journal.loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _monthHeader(monthTotal),
                  const SizedBox(height: 16),
                  _weekdayLabels(),
                  const SizedBox(height: 8),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        mainAxisSpacing: 6,
                        crossAxisSpacing: 6,
                      ),
                      itemCount: leadingBlanks + daysInMonth,
                      itemBuilder: (context, index) {
                        if (index < leadingBlanks) return const SizedBox.shrink();
                        final day = index - leadingBlanks + 1;
                        final key =
                            '${_visibleMonth.year}-${_visibleMonth.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
                        final pnl = dailyPnl[key];
                        return _dayCell(day, pnl);
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _monthHeader(double monthTotal) {
    const monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => _changeMonth(-1),
        ),
        Expanded(
          child: Column(
            children: [
              Text(
                '${monthNames[_visibleMonth.month - 1]} ${_visibleMonth.year}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              Text(
                '${monthTotal >= 0 ? '+' : ''}₹${monthTotal.toStringAsFixed(0)} this month',
                style: TextStyle(
                  fontSize: 12,
                  color: monthTotal >= 0 ? AppColors.profit : AppColors.loss,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () => _changeMonth(1),
        ),
      ],
    );
  }

  Widget _weekdayLabels() {
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Row(
      children: labels
          .map((l) => Expanded(
                child: Center(
                  child: Text(l,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                ),
              ))
          .toList(),
    );
  }

  Widget _dayCell(int day, double? pnl) {
    Color bg = AppColors.surfaceElevated;
    Color textColor = AppColors.textSecondary;

    if (pnl != null && pnl != 0) {
      final isProfit = pnl > 0;
      final magnitude = (pnl.abs() / 2000).clamp(0.15, 0.9); // visual intensity
      bg = (isProfit ? AppColors.profit : AppColors.loss).withValues(alpha: magnitude);
      textColor = Colors.white;
    }

    final isToday = DateTime.now().year == _visibleMonth.year &&
        DateTime.now().month == _visibleMonth.month &&
        DateTime.now().day == day;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: isToday ? Border.all(color: AppColors.accentGold, width: 1.5) : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('$day', style: TextStyle(fontSize: 12, color: textColor, fontWeight: FontWeight.w600)),
          if (pnl != null && pnl != 0)
            Text(
              '${pnl >= 0 ? '+' : ''}${(pnl / 1000).toStringAsFixed(1)}k',
              style: TextStyle(fontSize: 9, color: textColor),
            ),
        ],
      ),
    );
  }
}

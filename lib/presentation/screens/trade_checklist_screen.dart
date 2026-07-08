import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/emotion_entry.dart';
import 'add_trade_screen.dart';

/// Step before logging a trade: forces the user to confirm every item
/// on the strategy checklist. Skipping items is allowed (traders can
/// still proceed) but is recorded and penalized by the Discipline Engine.
class TradeChecklistScreen extends StatefulWidget {
  final String emotion;
  final EmotionEntry? emotionEntry;

  const TradeChecklistScreen({
    super.key,
    required this.emotion,
    this.emotionEntry,
  });

  @override
  State<TradeChecklistScreen> createState() => _TradeChecklistScreenState();
}

class _TradeChecklistScreenState extends State<TradeChecklistScreen> {
  late final Map<String, bool> _checkedItems;

  @override
  void initState() {
    super.initState();
    _checkedItems = {
      for (final item in AppConstants.tradeChecklistItems) item: false
    };
  }

  bool get _allChecked => _checkedItems.values.every((v) => v);
  int get _checkedCount => _checkedItems.values.where((v) => v).length;

  void _proceed() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => AddTradeScreen(
          emotion: widget.emotion,
          checklistCompleted: _allChecked,
          emotionEntry: widget.emotionEntry,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trade Checklist')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$_checkedCount / ${AppConstants.tradeChecklistItems.length} confirmed',
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: AppConstants.tradeChecklistItems.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = AppConstants.tradeChecklistItems[index];
                  final checked = _checkedItems[item]!;
                  return InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => setState(() => _checkedItems[item] = !checked),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: checked
                            ? AppColors.profit.withValues(alpha: 0.1)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: checked ? AppColors.profit : AppColors.border,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            checked ? Icons.check_circle : Icons.radio_button_unchecked,
                            color: checked ? AppColors.profit : AppColors.textMuted,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(item,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            if (!_allChecked)
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Text(
                  'Proceeding without full confirmation will lower your discipline score.',
                  style: TextStyle(fontSize: 12, color: AppColors.warning),
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _proceed,
                child: Text(_allChecked ? 'Proceed to Log Trade' : 'Proceed Anyway'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

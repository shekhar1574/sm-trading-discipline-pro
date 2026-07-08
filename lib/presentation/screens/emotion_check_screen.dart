import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/discipline_settings.dart';
import '../../data/services/discipline_engine.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/emotion_selector.dart';
import 'cooldown_screen.dart';
import 'trade_checklist_screen.dart';

/// Step 1 of every trade: "How are you feeling right now?"
/// This is the entry gate the whole Emotion Control Module hangs off.
class EmotionCheckScreen extends StatefulWidget {
  const EmotionCheckScreen({super.key});

  @override
  State<EmotionCheckScreen> createState() => _EmotionCheckScreenState();
}

class _EmotionCheckScreenState extends State<EmotionCheckScreen> {
  String? _selectedEmotion;
  final _engine = DisciplineEngine();
  String? _blockedReason;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _runDisciplineCheck();
  }

  Future<void> _runDisciplineCheck() async {
    final dashboard = context.read<DashboardProvider>();
    await dashboard.load();
    final DisciplineSettings settings = dashboard.settings;
    final result = await _engine.canTakeTrade(settings);
    setState(() {
      _blockedReason = result.allowed ? null : result.reason;
      _checking = false;
    });
  }

  void _continue() {
    if (_selectedEmotion == null) return;
    final isNegative = AppConstants.negativeEmotions.contains(_selectedEmotion);

    if (isNegative) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => CooldownScreen(emotion: _selectedEmotion!),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => TradeChecklistScreen(emotion: _selectedEmotion!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emotion Check')),
      body: _checking
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: _blockedReason != null
                  ? _blockedView(_blockedReason!)
                  : _emotionSelectionView(),
            ),
    );
  }

  Widget _blockedView(String reason) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.block, color: AppColors.loss, size: 56),
        const SizedBox(height: 20),
        const Text(
          'Trading Locked',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(reason,
            style: const TextStyle(color: AppColors.textSecondary),
            textAlign: TextAlign.center),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Back to Dashboard'),
          ),
        ),
      ],
    );
  }

  Widget _emotionSelectionView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'How are you feeling right now?',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        const Text(
          'Be honest — your discipline engine adapts based on your answer.',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24),
        EmotionSelector(
          selected: _selectedEmotion,
          onSelect: (e) => setState(() => _selectedEmotion = e),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _selectedEmotion == null ? null : _continue,
            child: const Text('Continue'),
          ),
        ),
      ],
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/emotion_entry.dart';
import 'trade_checklist_screen.dart';

/// Shown when the user selects a negative emotion (Fear, Greed, Revenge,
/// FOMO, Frustration). Forces a 10-minute cooling period with a guided
/// breathing exercise before the trade checklist can be accessed.
class CooldownScreen extends StatefulWidget {
  final String emotion;
  const CooldownScreen({super.key, required this.emotion});

  @override
  State<CooldownScreen> createState() => _CooldownScreenState();
}

class _CooldownScreenState extends State<CooldownScreen>
    with SingleTickerProviderStateMixin {
  late int _secondsRemaining;
  Timer? _timer;
  late AnimationController _breathController;

  @override
  void initState() {
    super.initState();
    _secondsRemaining = AppConstants.negativeEmotionCooldownMinutes * 60;

    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8), // 4s inhale, 4s exhale
    )..repeat(reverse: true);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining <= 0) {
        timer.cancel();
        return;
      }
      setState(() => _secondsRemaining--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _breathController.dispose();
    super.dispose();
  }

  String get _formattedTime {
    final m = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsRemaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  bool get _isComplete => _secondsRemaining <= 0;

  void _proceedToChecklist() {
    final entry = EmotionEntry(
      emotion: widget.emotion,
      triggeredCooldown: true,
      cooldownCompleted: _isComplete,
    );
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => TradeChecklistScreen(
          emotion: widget.emotion,
          emotionEntry: entry,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cooling Period')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.loss.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.loss.withValues(alpha: 0.4)),
              ),
              child: Text(
                'You flagged "${widget.emotion}" — take a moment before trading.',
                style: const TextStyle(color: AppColors.loss, fontSize: 12, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 40),
            AnimatedBuilder(
              animation: _breathController,
              builder: (context, child) {
                final scale = 0.8 + (_breathController.value * 0.4);
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(alpha: 0.15),
                      border: Border.all(color: AppColors.primary, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        _breathController.value < 0.5 ? 'Inhale' : 'Exhale',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 40),
            Text(_formattedTime,
                style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            const Text('Focus on your breath, not the market.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 32),
            _focusExercise(
              '1. Breathe in for 4 seconds, out for 4 seconds.',
            ),
            _focusExercise(
              '2. Ask yourself: "Am I trading my plan, or my emotion?"',
            ),
            _focusExercise(
              '3. Re-read your last 3 journal entries before re-entering.',
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isComplete ? _proceedToChecklist : null,
                child: Text(_isComplete
                    ? 'Proceed to Trade Checklist'
                    : 'Please wait — $_formattedTime remaining'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _focusExercise(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
      ),
    );
  }
}

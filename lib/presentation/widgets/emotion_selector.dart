import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';

/// Grid of selectable emotion chips used by the Emotion Control Module.
class EmotionSelector extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onSelect;

  const EmotionSelector({super.key, required this.selected, required this.onSelect});

  IconData _iconFor(String emotion) {
    switch (emotion) {
      case 'Calm':
        return Icons.self_improvement;
      case 'Confident':
        return Icons.trending_up;
      case 'Fear':
        return Icons.warning_amber_rounded;
      case 'Greed':
        return Icons.attach_money;
      case 'Revenge':
        return Icons.flash_on;
      case 'FOMO':
        return Icons.bolt;
      case 'Frustration':
        return Icons.mood_bad;
      default:
        return Icons.psychology;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: AppConstants.emotions.map((emotion) {
        final isSelected = selected == emotion;
        final isNegative = AppConstants.negativeEmotions.contains(emotion);
        final color = isSelected
            ? (isNegative ? AppColors.loss : AppColors.profit)
            : AppColors.textSecondary;

        return GestureDetector(
          onTap: () => onSelect(emotion),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? color.withValues(alpha: 0.15)
                  : AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? color : AppColors.border,
                width: isSelected ? 1.4 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_iconFor(emotion), size: 16, color: color),
                const SizedBox(width: 6),
                Text(emotion,
                    style: TextStyle(
                        color: isSelected ? color : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

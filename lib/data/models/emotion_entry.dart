import '../../core/constants/app_constants.dart';

/// Records the emotional state a trader declared right before taking
/// (or attempting to take) a trade. Used both by the Emotion Control
/// Module and by the Analytics Dashboard's "emotional trading analysis".
class EmotionEntry {
  final int? id;
  final String emotion;
  final bool triggeredCooldown;
  final bool cooldownCompleted;
  final DateTime createdAt;

  EmotionEntry({
    this.id,
    required this.emotion,
    this.triggeredCooldown = false,
    this.cooldownCompleted = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isNegative => AppConstants.negativeEmotions.contains(emotion);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'emotion': emotion,
      'triggeredCooldown': triggeredCooldown ? 1 : 0,
      'cooldownCompleted': cooldownCompleted ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory EmotionEntry.fromMap(Map<String, dynamic> map) {
    return EmotionEntry(
      id: map['id'] as int?,
      emotion: map['emotion'] as String,
      triggeredCooldown: (map['triggeredCooldown'] as int) == 1,
      cooldownCompleted: (map['cooldownCompleted'] as int) == 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}

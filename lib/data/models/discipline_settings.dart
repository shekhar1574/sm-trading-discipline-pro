import '../../core/constants/app_constants.dart';

/// User-configurable trading discipline rules. Persisted as a single-row
/// table so the Discipline Engine always has one active rule set.
class DisciplineSettings {
  final double accountBalance;
  final int maxTradesPerDay;
  final double dailyMaxLossPercent;
  final double dailyProfitTargetPercent;
  final int cooldownMinutes;

  const DisciplineSettings({
    required this.accountBalance,
    this.maxTradesPerDay = AppConstants.defaultMaxTradesPerDay,
    this.dailyMaxLossPercent = AppConstants.defaultDailyMaxLossPercent,
    this.dailyProfitTargetPercent = AppConstants.defaultDailyProfitTargetPercent,
    this.cooldownMinutes = AppConstants.defaultCooldownMinutes,
  });

  double get dailyMaxLossAmount => accountBalance * dailyMaxLossPercent / 100;
  double get dailyProfitTargetAmount =>
      accountBalance * dailyProfitTargetPercent / 100;

  Map<String, dynamic> toMap() {
    return {
      'accountBalance': accountBalance,
      'maxTradesPerDay': maxTradesPerDay,
      'dailyMaxLossPercent': dailyMaxLossPercent,
      'dailyProfitTargetPercent': dailyProfitTargetPercent,
      'cooldownMinutes': cooldownMinutes,
    };
  }

  factory DisciplineSettings.fromMap(Map<String, dynamic> map) {
    return DisciplineSettings(
      accountBalance: (map['accountBalance'] as num).toDouble(),
      maxTradesPerDay: map['maxTradesPerDay'] as int,
      dailyMaxLossPercent: (map['dailyMaxLossPercent'] as num).toDouble(),
      dailyProfitTargetPercent:
          (map['dailyProfitTargetPercent'] as num).toDouble(),
      cooldownMinutes: map['cooldownMinutes'] as int,
    );
  }

  DisciplineSettings copyWith({
    double? accountBalance,
    int? maxTradesPerDay,
    double? dailyMaxLossPercent,
    double? dailyProfitTargetPercent,
    int? cooldownMinutes,
  }) {
    return DisciplineSettings(
      accountBalance: accountBalance ?? this.accountBalance,
      maxTradesPerDay: maxTradesPerDay ?? this.maxTradesPerDay,
      dailyMaxLossPercent: dailyMaxLossPercent ?? this.dailyMaxLossPercent,
      dailyProfitTargetPercent:
          dailyProfitTargetPercent ?? this.dailyProfitTargetPercent,
      cooldownMinutes: cooldownMinutes ?? this.cooldownMinutes,
    );
  }
}

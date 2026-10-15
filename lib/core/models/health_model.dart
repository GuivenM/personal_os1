/// GET /health — today's log (or a given ?date=)
class HealthLog {
  const HealthLog({
    required this.logDate,
    required this.sleepOk,
    required this.exerciseOk,
    required this.foodOk,
    required this.exists,
  });

  final String logDate;
  final bool sleepOk;
  final bool exerciseOk;
  final bool foodOk;
  final bool exists;

  factory HealthLog.fromJson(Map<String, dynamic> json) {
    return HealthLog(
      logDate: json['log_date'] as String? ?? '',
      sleepOk: json['sleep_ok'] as bool? ?? false,
      exerciseOk: json['exercise_ok'] as bool? ?? false,
      foodOk: json['food_ok'] as bool? ?? false,
      exists: json['exists'] as bool? ?? false,
    );
  }

  HealthLog copyWith({bool? sleepOk, bool? exerciseOk, bool? foodOk, bool? exists}) {
    return HealthLog(
      logDate: logDate,
      sleepOk: sleepOk ?? this.sleepOk,
      exerciseOk: exerciseOk ?? this.exerciseOk,
      foodOk: foodOk ?? this.foodOk,
      exists: exists ?? this.exists,
    );
  }
}

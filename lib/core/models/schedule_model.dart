import 'schedule_block_model.dart';
import '../utils/json_parsing.dart';

/// GET /schedule (today or a given ?date=)
class ScheduleDayResponse {
  const ScheduleDayResponse({
    required this.date,
    required this.dayOfWeek,
    required this.blocks,
  });

  final String date;
  final int dayOfWeek; // 0 = Monday ... 6 = Sunday
  final List<ScheduleBlock> blocks;

  factory ScheduleDayResponse.fromJson(Map<String, dynamic> json) {
    return ScheduleDayResponse(
      date: json['date'] as String? ?? '',
      dayOfWeek: json['day_of_week'] as int? ?? 0,
      blocks: (json['blocks'] as List<dynamic>? ?? [])
          .map((e) => ScheduleBlock.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex)),
    );
  }

  ScheduleDayResponse copyWith({String? date, int? dayOfWeek, List<ScheduleBlock>? blocks}) {
    return ScheduleDayResponse(
      date: date ?? this.date,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      blocks: blocks ?? this.blocks,
    );
  }
}

/// One day inside GET /schedule/week (template blocks, no log_id).
class WeekDay {
  const WeekDay({
    required this.dayOfWeek,
    required this.dayName,
    required this.blocks,
  });

  final int dayOfWeek;
  final String dayName;
  final List<ScheduleBlock> blocks;

  factory WeekDay.fromJson(Map<String, dynamic> json) {
    return WeekDay(
      dayOfWeek: json['day_of_week'] as int? ?? 0,
      dayName: json['day_name'] as String? ?? '',
      blocks: (json['blocks'] as List<dynamic>? ?? [])
          .map((e) => ScheduleBlock.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex)),
    );
  }
}

/// GET /schedule/week
class WeekScheduleResponse {
  const WeekScheduleResponse({required this.templateId, required this.days});

  final int templateId;
  final List<WeekDay> days;

  factory WeekScheduleResponse.fromJson(Map<String, dynamic> json) {
    final days = (json['days'] as List<dynamic>? ?? [])
        .map((e) => WeekDay.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.dayOfWeek.compareTo(b.dayOfWeek));
    return WeekScheduleResponse(
      templateId: json['template_id'] as int? ?? 0,
      days: days,
    );
  }
}

/// One day inside GET /schedule/history
class HistoryDay {
  const HistoryDay({
    required this.logDate,
    required this.total,
    required this.done,
    required this.partial,
    required this.skipped,
    required this.pending,
  });

  final String logDate;
  final int total;
  final int done;
  final int partial;
  final int skipped;
  final int pending;

  double get doneRatio => total == 0 ? 0 : done / total;

  factory HistoryDay.fromJson(Map<String, dynamic> json) {
    return HistoryDay(
      logDate: json['log_date'] as String? ?? '',
      total: asInt(json['total']),
      done: asInt(json['done']),
      partial: asInt(json['partial']),
      skipped: asInt(json['skipped']),
      pending: asInt(json['pending']),
    );
  }
}

/// GET /schedule/history
class ScheduleHistoryResponse {
  const ScheduleHistoryResponse({required this.streak, required this.days});

  final int streak;
  final List<HistoryDay> days;

  factory ScheduleHistoryResponse.fromJson(Map<String, dynamic> json) {
    return ScheduleHistoryResponse(
      streak: asInt(json['streak']),
      days: (json['days'] as List<dynamic>? ?? [])
          .map((e) => HistoryDay.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

import '../utils/json_parsing.dart';

/// A single schedule block, either as a template entry (`log_id == null`)
/// or as today's log entry (`log_id` set, `status` reflects the day).
class ScheduleBlock {
  const ScheduleBlock({
    required this.blockId,
    required this.name,
    required this.description,
    required this.timeStart,
    required this.timeEnd,
    required this.orderIndex,
    required this.logId,
    required this.status,
    required this.isCurrent,
  });

  final int blockId;
  final String name;
  final String description;
  final String timeStart;
  final String timeEnd;
  final int orderIndex;
  final int? logId;
  final String status; // done | partial | skipped | pending
  final bool isCurrent;

  factory ScheduleBlock.fromJson(Map<String, dynamic> json) {
    return ScheduleBlock(
      blockId: asInt(json['block_id']),
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      timeStart: json['time_start'] as String? ?? '',
      timeEnd: json['time_end'] as String? ?? '',
      orderIndex: asInt(json['order_index']),
      logId: asIntOrNull(json['log_id']),
      status: json['status'] as String? ?? 'pending',
      isCurrent: json['is_current'] as bool? ?? false,
    );
  }

  ScheduleBlock copyWith({
    int? blockId,
    String? name,
    String? description,
    String? timeStart,
    String? timeEnd,
    int? orderIndex,
    int? logId,
    String? status,
    bool? isCurrent,
  }) {
    return ScheduleBlock(
      blockId: blockId ?? this.blockId,
      name: name ?? this.name,
      description: description ?? this.description,
      timeStart: timeStart ?? this.timeStart,
      timeEnd: timeEnd ?? this.timeEnd,
      orderIndex: orderIndex ?? this.orderIndex,
      logId: logId ?? this.logId,
      status: status ?? this.status,
      isCurrent: isCurrent ?? this.isCurrent,
    );
  }
}

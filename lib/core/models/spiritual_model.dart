import '../utils/json_parsing.dart';

/// A user-defined spiritual practice (`m_w_spiritual_practices`).
/// Comes from `GET /spiritual/practices` — the full list, active and
/// inactive, so the Practices tab can manage everything.
class SpiritualPractice {
  const SpiritualPractice({required this.id, required this.name, required this.active});

  final int id;
  final String name;
  final bool active;

  factory SpiritualPractice.fromJson(Map<String, dynamic> json) {
    return SpiritualPractice(
      id: asInt(json['id']),
      name: json['name'] as String? ?? '',
      active: json['active'] as bool? ?? true,
    );
  }

  SpiritualPractice copyWith({String? name, bool? active}) {
    return SpiritualPractice(id: id, name: name ?? this.name, active: active ?? this.active);
  }
}

/// One active practice's state for a given day, as returned inline by
/// `GET /spiritual` and `POST /spiritual` (`m_w_spiritual_logs` joined
/// with `m_w_spiritual_practices`).
class SpiritualPracticeLog {
  const SpiritualPracticeLog({
    required this.practiceId,
    required this.name,
    required this.done,
    required this.notes,
    required this.logId,
  });

  final int practiceId;
  final String name;
  final bool done;
  final String? notes;

  /// Null until the first log for this practice/day exists. Not needed
  /// to decide POST-vs-PUT (the backend upserts on one POST), just
  /// useful for e.g. showing "not logged yet" if ever wanted.
  final int? logId;

  factory SpiritualPracticeLog.fromJson(Map<String, dynamic> json) {
    return SpiritualPracticeLog(
      practiceId: asInt(json['practice_id']),
      name: json['name'] as String? ?? '',
      done: json['done'] as bool? ?? false,
      notes: json['notes'] as String?,
      logId: asIntOrNull(json['log_id']),
    );
  }
}

/// GET/POST /spiritual — today's (or a given date's) log across all
/// active practices.
class SpiritualToday {
  const SpiritualToday({required this.date, required this.practices});

  final String date;
  final List<SpiritualPracticeLog> practices;

  factory SpiritualToday.fromJson(Map<String, dynamic> json) {
    final rawPractices = json['practices'] as List<dynamic>? ?? const [];
    return SpiritualToday(
      date: json['date'] as String? ?? '',
      practices: rawPractices.map((e) => SpiritualPracticeLog.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

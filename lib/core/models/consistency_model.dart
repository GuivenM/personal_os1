import '../utils/json_parsing.dart';

class StreakSummary {
  const StreakSummary({required this.currentStreak, required this.bestStreak});

  final int currentStreak;
  final int bestStreak;

  factory StreakSummary.fromJson(Map<String, dynamic> json) {
    return StreakSummary(currentStreak: asInt(json['current_streak']), bestStreak: asInt(json['best_streak']));
  }
}

/// The merged track: everything a [StreakSummary] has (an AND-streak —
/// consecutive days blocks + reading + spiritual were ALL hit), plus a
/// softer blended score so one off day on a single track doesn't zero
/// out the whole picture.
class MergedStreak extends StreakSummary {
  const MergedStreak({required super.currentStreak, required super.bestStreak, required this.consistencyScore});

  /// 0–100. Average fraction of the 3 tracks hit per day over the window.
  final double consistencyScore;

  factory MergedStreak.fromJson(Map<String, dynamic> json) {
    return MergedStreak(
      currentStreak: asInt(json['current_streak']),
      bestStreak: asInt(json['best_streak']),
      consistencyScore: (json['consistency_score'] as num?)?.toDouble() ?? 0,
    );
  }
}

class ConsistencyDay {
  const ConsistencyDay({
    required this.date,
    required this.blocksDone,
    required this.readingDone,
    required this.spiritualDone,
    required this.score,
  });

  final String date;
  final bool blocksDone;
  final bool readingDone;
  final bool spiritualDone;

  /// 0–3, how many of the 3 tracks were hit that day.
  final int score;

  factory ConsistencyDay.fromJson(Map<String, dynamic> json) {
    return ConsistencyDay(
      date: json['date'] as String? ?? '',
      blocksDone: json['blocks_done'] as bool? ?? false,
      readingDone: json['reading_done'] as bool? ?? false,
      spiritualDone: json['spiritual_done'] as bool? ?? false,
      score: asInt(json['score']),
    );
  }
}

/// GET /consistency?days=N
class ConsistencySummary {
  const ConsistencySummary({
    required this.windowDays,
    required this.blocks,
    required this.reading,
    required this.spiritual,
    required this.merged,
    required this.days,
  });

  final int windowDays;
  final StreakSummary blocks;
  final StreakSummary reading;
  final StreakSummary spiritual;
  final MergedStreak merged;
  final List<ConsistencyDay> days;

  factory ConsistencySummary.fromJson(Map<String, dynamic> json) {
    final rawDays = json['days'] as List<dynamic>? ?? const [];
    return ConsistencySummary(
      windowDays: asInt(json['window_days']),
      blocks: StreakSummary.fromJson(json['blocks'] as Map<String, dynamic>? ?? const {}),
      reading: StreakSummary.fromJson(json['reading'] as Map<String, dynamic>? ?? const {}),
      spiritual: StreakSummary.fromJson(json['spiritual'] as Map<String, dynamic>? ?? const {}),
      merged: MergedStreak.fromJson(json['merged'] as Map<String, dynamic>? ?? const {}),
      days: rawDays.map((e) => ConsistencyDay.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

import '../utils/json_parsing.dart';

class RecapBlocks {
  const RecapBlocks({required this.total, required this.done, required this.partial, required this.skipped});

  final int total;
  final int done;
  final int partial;
  final int skipped;

  double? get donePercent => total > 0 ? (done / total) * 100 : null;

  factory RecapBlocks.fromJson(Map<String, dynamic> json) {
    return RecapBlocks(
      total: asInt(json['total']),
      done: asInt(json['done']),
      partial: asInt(json['partial']),
      skipped: asInt(json['skipped']),
    );
  }
}

class RecapBook {
  const RecapBook({required this.title, required this.author, this.phase});

  final String title;
  final String author;
  final String? phase;

  factory RecapBook.fromJson(Map<String, dynamic> json) {
    return RecapBook(
      title: json['title'] as String? ?? '',
      author: json['author'] as String? ?? '',
      phase: json['phase'] as String?,
    );
  }
}

class RecapLearning {
  const RecapLearning({required this.domain, required this.totalMin, required this.sessions});

  final String domain;
  final int totalMin;
  final int sessions;

  factory RecapLearning.fromJson(Map<String, dynamic> json) {
    return RecapLearning(
      domain: json['domain'] as String? ?? '',
      totalMin: asInt(json['total_min']),
      sessions: asInt(json['sessions']),
    );
  }
}

class RecapMusic {
  const RecapMusic({required this.sessionType, required this.totalMin, required this.sessions});

  final String sessionType;
  final int totalMin;
  final int sessions;

  factory RecapMusic.fromJson(Map<String, dynamic> json) {
    return RecapMusic(
      sessionType: json['session_type'] as String? ?? '',
      totalMin: asInt(json['total_min']),
      sessions: asInt(json['sessions']),
    );
  }
}

class RecapProject {
  const RecapProject({required this.name, required this.domain, required this.status});

  final String name;
  final String domain;
  final String status;

  factory RecapProject.fromJson(Map<String, dynamic> json) {
    return RecapProject(
      name: json['name'] as String? ?? '',
      domain: json['domain'] as String? ?? '',
      status: json['status'] as String? ?? '',
    );
  }
}

class RecapHealth {
  const RecapHealth({required this.daysLogged, required this.sleepOk, required this.exerciseOk, required this.foodOk});

  final int daysLogged;
  final int sleepOk;
  final int exerciseOk;
  final int foodOk;

  factory RecapHealth.fromJson(Map<String, dynamic> json) {
    return RecapHealth(
      daysLogged: asInt(json['days_logged']),
      sleepOk: asInt(json['sleep_ok']),
      exerciseOk: asInt(json['exercise_ok']),
      foodOk: asInt(json['food_ok']),
    );
  }
}

class RecapSpiritual {
  const RecapSpiritual({required this.name, required this.daysDone});

  final String name;
  final int daysDone;

  factory RecapSpiritual.fromJson(Map<String, dynamic> json) {
    return RecapSpiritual(name: json['name'] as String? ?? '', daysDone: asInt(json['days_done']));
  }
}

/// The raw numbers behind the narrative — `data` in the API response,
/// there "pour debug/affichage des chiffres" per the controller's own
/// comment, so it's meant to be shown, not just logged.
class RecapData {
  const RecapData({
    required this.blocks,
    required this.maxStreak,
    required this.booksFinished,
    required this.booksReading,
    required this.learning,
    required this.music,
    required this.projects,
    required this.health,
    required this.spiritual,
    required this.vision,
  });

  final RecapBlocks blocks;
  final int maxStreak;
  final List<RecapBook> booksFinished;
  final List<RecapBook> booksReading;
  final List<RecapLearning> learning;
  final List<RecapMusic> music;
  final List<RecapProject> projects;
  final RecapHealth health;
  final List<RecapSpiritual> spiritual;
  final String? vision;

  factory RecapData.fromJson(Map<String, dynamic> json) {
    List<T> list<T>(String key, T Function(Map<String, dynamic>) fromJson) {
      final raw = json[key] as List<dynamic>? ?? const [];
      return raw.map((e) => fromJson(e as Map<String, dynamic>)).toList();
    }

    return RecapData(
      blocks: RecapBlocks.fromJson(json['blocks'] as Map<String, dynamic>? ?? const {}),
      maxStreak: asInt(json['maxStreak']),
      booksFinished: list('booksFinished', RecapBook.fromJson),
      booksReading: list('booksReading', RecapBook.fromJson),
      learning: list('learning', RecapLearning.fromJson),
      music: list('music', RecapMusic.fromJson),
      projects: list('projects', RecapProject.fromJson),
      health: RecapHealth.fromJson(json['health'] as Map<String, dynamic>? ?? const {}),
      spiritual: list('spiritual', RecapSpiritual.fromJson),
      vision: json['vision'] as String?,
    );
  }
}

/// GET /recap?month=YYYY-MM
class MonthlyRecap {
  const MonthlyRecap({required this.month, required this.recapText, required this.data});

  final String month;
  final String recapText;
  final RecapData data;

  factory MonthlyRecap.fromJson(Map<String, dynamic> json) {
    return MonthlyRecap(
      month: json['month'] as String? ?? '',
      recapText: json['recap'] as String? ?? '',
      data: RecapData.fromJson(json['data'] as Map<String, dynamic>? ?? const {}),
    );
  }
}

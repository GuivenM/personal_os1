import 'schedule_block_model.dart';
import '../utils/json_parsing.dart';

export 'schedule_block_model.dart' show ScheduleBlock;

class DashboardProject {
  const DashboardProject({
    required this.id,
    required this.name,
    required this.domain,
    required this.status,
    required this.progress,
    required this.tasksTotal,
    required this.tasksDone,
  });

  final int id;
  final String name;
  final String domain;
  final String status;
  final int progress;
  final int tasksTotal;
  final int tasksDone;

  factory DashboardProject.fromJson(Map<String, dynamic> json) {
    return DashboardProject(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      domain: json['domain'] as String? ?? '',
      status: json['status'] as String? ?? '',
      progress: asInt(json['progress']),
      tasksTotal: asInt(json['tasks_total']),
      tasksDone: asInt(json['tasks_done']),
    );
  }
}

class DashboardHealth {
  const DashboardHealth({
    required this.sleepOk,
    required this.exerciseOk,
    required this.foodOk,
  });

  final bool sleepOk;
  final bool exerciseOk;
  final bool foodOk;

  factory DashboardHealth.fromJson(Map<String, dynamic> json) {
    return DashboardHealth(
      sleepOk: json['sleep_ok'] as bool? ?? false,
      exerciseOk: json['exercise_ok'] as bool? ?? false,
      foodOk: json['food_ok'] as bool? ?? false,
    );
  }
}

class DashboardQuote {
  const DashboardQuote({required this.text, required this.source});

  final String text;
  final String source;

  factory DashboardQuote.fromJson(Map<String, dynamic> json) {
    return DashboardQuote(
      text: json['text'] as String? ?? '',
      source: json['source'] as String? ?? '',
    );
  }
}

class DashboardResponse {
  const DashboardResponse({
    required this.date,
    required this.greeting,
    required this.vision,
    required this.streak,
    required this.blocksDone,
    required this.blocksTotal,
    required this.blocks,
    required this.activeBlock,
    required this.projectsCount,
    required this.projects,
    required this.booksCount,
    required this.health,
    required this.quote,
  });

  final String date;
  final String greeting;
  final String vision;
  final int streak;
  final int blocksDone;
  final int blocksTotal;
  final List<ScheduleBlock> blocks;
  final ScheduleBlock? activeBlock;
  final int projectsCount;
  final List<DashboardProject> projects;
  final int booksCount;
  final DashboardHealth health;
  final DashboardQuote? quote;

  factory DashboardResponse.fromJson(Map<String, dynamic> json) {
    return DashboardResponse(
      date: json['date'] as String? ?? '',
      greeting: json['greeting'] as String? ?? '',
      vision: json['vision'] as String? ?? '',
      streak: asInt(json['streak']),
      blocksDone: asInt(json['blocks_done']),
      blocksTotal: asInt(json['blocks_total']),
      blocks: (json['blocks'] as List<dynamic>? ?? [])
          .map((e) => ScheduleBlock.fromJson(e as Map<String, dynamic>))
          .toList(),
      activeBlock: json['active_block'] != null
          ? ScheduleBlock.fromJson(json['active_block'] as Map<String, dynamic>)
          : null,
      projectsCount: asInt(json['projects_count']),
      projects: (json['projects'] as List<dynamic>? ?? [])
          .map((e) => DashboardProject.fromJson(e as Map<String, dynamic>))
          .toList(),
      booksCount: asInt(json['books_count']),
      health: DashboardHealth.fromJson(json['health'] as Map<String, dynamic>? ?? const {}),
      quote: json['quote'] != null ? DashboardQuote.fromJson(json['quote'] as Map<String, dynamic>) : null,
    );
  }
}

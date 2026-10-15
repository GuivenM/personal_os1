import '../utils/json_parsing.dart';

/// Possible horizons for a goal.
const goalHorizons = ['3months', '1year', '3years', '5years'];

String goalHorizonLabel(String horizon) {
  switch (horizon) {
    case '3months':
      return '3 months';
    case '1year':
      return '1 year';
    case '3years':
      return '3 years';
    case '5years':
      return '5 years';
    default:
      return horizon;
  }
}

/// A single goal, scoped to one horizon.
class Goal {
  const Goal({
    required this.id,
    required this.horizon,
    required this.title,
    required this.status,
  });

  final int id;
  final String horizon;
  final String title;
  final String status; // active | done

  bool get isDone => status == 'done';

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: asInt(json['id']),
      horizon: json['horizon'] as String? ?? '3months',
      title: json['title'] as String? ?? '',
      status: json['status'] as String? ?? 'active',
    );
  }

  Goal copyWith({String? title, String? status}) {
    return Goal(
      id: id,
      horizon: horizon,
      title: title ?? this.title,
      status: status ?? this.status,
    );
  }
}

/// GET /vision
class VisionResponse {
  const VisionResponse({required this.visionText, required this.goals});

  final String visionText;
  final Map<String, List<Goal>> goals;

  factory VisionResponse.fromJson(Map<String, dynamic> json) {
    final rawGoals = json['goals'] as Map<String, dynamic>? ?? {};
    final goals = <String, List<Goal>>{};
    for (final horizon in goalHorizons) {
      goals[horizon] = ((rawGoals[horizon] as List<dynamic>?) ?? [])
          .map((e) => Goal.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return VisionResponse(
      visionText: json['vision_text'] as String? ?? '',
      goals: goals,
    );
  }

  VisionResponse copyWith({String? visionText, Map<String, List<Goal>>? goals}) {
    return VisionResponse(
      visionText: visionText ?? this.visionText,
      goals: goals ?? this.goals,
    );
  }
}

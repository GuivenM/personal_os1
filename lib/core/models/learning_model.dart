import '../utils/json_parsing.dart';

/// The backend expects these exact (French) values — only the display
/// labels are translated to English in the UI.
const learningDomains = ['Programmation', 'Réseau', 'IA', 'Autre'];

String learningDomainLabel(String domain) {
  switch (domain) {
    case 'Programmation':
      return 'Programming';
    case 'Réseau':
      return 'Network';
    case 'IA':
      return 'AI';
    case 'Autre':
      return 'Other';
    default:
      return domain;
  }
}

const learningLevels = [1, 2, 3, 4, 5];

String learningLevelLabel(int level) {
  switch (level) {
    case 1:
      return 'Confused';
    case 2:
      return 'Unclear';
    case 3:
      return 'Ok';
    case 4:
      return 'Good';
    case 5:
      return 'Mastered';
    default:
      return 'Level $level';
  }
}

String learningLevelEmoji(int level) {
  switch (level) {
    case 1:
      return '😵';
    case 2:
      return '🤔';
    case 3:
      return '🙂';
    case 4:
      return '😎';
    case 5:
      return '🔥';
    default:
      return '•';
  }
}

class LearningSession {
  const LearningSession({
    required this.id,
    required this.domain,
    required this.subdomain,
    required this.durationMin,
    required this.content,
    required this.resource,
    required this.level,
    required this.sessionDate,
  });

  final int id;
  final String domain;
  final String? subdomain;
  final int durationMin;
  final String? content;
  final String? resource;
  final int level;
  final String sessionDate;

  factory LearningSession.fromJson(Map<String, dynamic> json) {
    return LearningSession(
      id: asInt(json['id']),
      domain: json['domain'] as String? ?? 'Autre',
      subdomain: json['subdomain'] as String?,
      durationMin: asInt(json['duration_min']),
      content: json['content'] as String?,
      resource: json['resource'] as String?,
      level: asInt(json['level'], 3),
      sessionDate: json['session_date'] as String? ?? '',
    );
  }
}

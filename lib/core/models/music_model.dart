import '../utils/json_parsing.dart';

const musicSessionTypes = ['writing', 'production', 'listening', 'recording', 'other'];

String musicSessionTypeLabel(String type) {
  switch (type) {
    case 'writing':
      return 'Writing';
    case 'production':
      return 'Production';
    case 'listening':
      return 'Listening';
    case 'recording':
      return 'Recording';
    case 'other':
      return 'Other';
    default:
      return type;
  }
}

class MusicSession {
  const MusicSession({
    required this.id,
    required this.sessionType,
    required this.durationMin,
    required this.notes,
    required this.projectName,
    required this.sessionDate,
  });

  final int id;
  final String sessionType;
  final int durationMin;
  final String? notes;
  final String? projectName;
  final String sessionDate;

  factory MusicSession.fromJson(Map<String, dynamic> json) {
    return MusicSession(
      id: asInt(json['id']),
      sessionType: json['session_type'] as String? ?? 'other',
      durationMin: asInt(json['duration_min']),
      notes: json['notes'] as String?,
      projectName: json['project_name'] as String?,
      sessionDate: json['session_date'] as String? ?? '',
    );
  }
}

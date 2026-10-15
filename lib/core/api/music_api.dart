import '../api/api_client.dart';
import '../models/music_model.dart';

class MusicApi {
  MusicApi(this._client);

  final ApiClient _client;

  Future<List<MusicSession>> getSessions({String? type, String? from, String? to, String? project}) async {
    final json = await _client.get('/music', query: {
      if (type != null) 'type': type,
      if (from != null) 'from': from,
      if (to != null) 'to': to,
      if (project != null) 'project': project,
    });
    return (json as List<dynamic>).map((e) => MusicSession.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<MusicSession> createSession({
    required String sessionType,
    required int durationMin,
    String? notes,
    String? projectName,
    required String sessionDate,
  }) async {
    final json = await _client.post('/music', body: {
      'session_type': sessionType,
      'duration_min': durationMin,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      if (projectName != null && projectName.isNotEmpty) 'project_name': projectName,
      'session_date': sessionDate,
    });
    return MusicSession.fromJson(json as Map<String, dynamic>);
  }

  Future<void> updateSession(int id, Map<String, dynamic> fields) async {
    await _client.put('/music/$id', body: fields);
  }

  Future<void> deleteSession(int id) async {
    await _client.delete('/music/$id');
  }
}

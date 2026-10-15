import '../api/api_client.dart';
import '../models/learning_model.dart';

class LearningApi {
  LearningApi(this._client);

  final ApiClient _client;

  Future<List<LearningSession>> getSessions({String? domain, String? from, String? to}) async {
    final json = await _client.get('/learning', query: {
      if (domain != null) 'domain': domain,
      if (from != null) 'from': from,
      if (to != null) 'to': to,
    });
    return (json as List<dynamic>).map((e) => LearningSession.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<LearningSession> createSession({
    required String domain,
    String? subdomain,
    required int durationMin,
    String? content,
    String? resource,
    required int level,
    required String sessionDate,
  }) async {
    final json = await _client.post('/learning', body: {
      'domain': domain,
      if (subdomain != null && subdomain.isNotEmpty) 'subdomain': subdomain,
      'duration_min': durationMin,
      if (content != null && content.isNotEmpty) 'content': content,
      if (resource != null && resource.isNotEmpty) 'resource': resource,
      'level': level,
      'session_date': sessionDate,
    });
    return LearningSession.fromJson(json as Map<String, dynamic>);
  }

  Future<void> updateSession(int id, Map<String, dynamic> fields) async {
    await _client.put('/learning/$id', body: fields);
  }

  Future<void> deleteSession(int id) async {
    await _client.delete('/learning/$id');
  }
}

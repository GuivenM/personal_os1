import '../api/api_client.dart';
import '../models/health_model.dart';

class HealthApi {
  HealthApi(this._client);

  final ApiClient _client;

  /// GET /health — today's log.
  Future<HealthLog> getHealth() async {
    final json = await _client.get('/health');
    return HealthLog.fromJson(json as Map<String, dynamic>);
  }

  /// POST /health — first log of the day.
  Future<HealthLog> createHealth({required bool sleepOk, required bool exerciseOk, required bool foodOk}) async {
    final json = await _client.post('/health', body: {
      'sleep_ok': sleepOk,
      'exercise_ok': exerciseOk,
      'food_ok': foodOk,
    });
    return HealthLog.fromJson(json as Map<String, dynamic>);
  }

  /// PUT /health — update today's existing log.
  Future<HealthLog> updateHealth({bool? sleepOk, bool? exerciseOk, bool? foodOk}) async {
    final json = await _client.put('/health', body: {
      if (sleepOk != null) 'sleep_ok': sleepOk,
      if (exerciseOk != null) 'exercise_ok': exerciseOk,
      if (foodOk != null) 'food_ok': foodOk,
    });
    return HealthLog.fromJson(json as Map<String, dynamic>);
  }
}

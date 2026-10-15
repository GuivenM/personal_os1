import '../api/api_client.dart';
import '../models/consistency_model.dart';

/// Matches the proposed `Controllers\ConsistencyController`
/// (see backend_suggestions/ — not deployed yet, needs the
/// `'consistency'` route added to router.php first).
class ConsistencyApi {
  ConsistencyApi(this._client);

  final ApiClient _client;

  /// GET /consistency?days=N — window size for the heatmap (default 30
  /// server-side); streaks themselves aren't limited by this.
  Future<ConsistencySummary> getConsistency({int? days}) async {
    final json = await _client.get('/consistency', query: {if (days != null) 'days': days});
    return ConsistencySummary.fromJson(json as Map<String, dynamic>);
  }
}

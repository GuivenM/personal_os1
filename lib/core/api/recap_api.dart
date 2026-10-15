import '../api/api_client.dart';
import '../models/recap_model.dart';

/// Matches `Controllers\RecapController`: a single read endpoint that
/// generates (server-side, via an LLM call) a monthly narrative recap
/// plus the raw numbers it was built from.
///
/// Note this call can be slow — the backend does several DB aggregate
/// queries AND a synchronous LLM API call before responding — so the UI
/// should show a real loading state, not assume this is snappy like
/// other GETs.
class RecapApi {
  RecapApi(this._client);

  final ApiClient _client;

  /// GET /recap?month=YYYY-MM (omit for the current month).
  Future<MonthlyRecap> getRecap({String? month}) async {
    final json = await _client.get('/recap', query: {if (month != null) 'month': month});
    return MonthlyRecap.fromJson(json as Map<String, dynamic>);
  }
}

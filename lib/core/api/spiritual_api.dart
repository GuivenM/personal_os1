import '../api/api_client.dart';
import '../models/spiritual_model.dart';

/// Matches `Controllers\SpiritualController`:
/// - `GET  /spiritual`            → today's log (all active practices)
/// - `POST /spiritual`            → upsert one practice's done/notes for a date
/// - `GET  /spiritual/practices`  → full practice list (active + inactive)
/// - `POST /spiritual/practices`  → create a practice
/// - `PUT  /spiritual/practices/{id}` → rename / activate / deactivate
///
/// No delete endpoint exists — practices are archived via `active: false`,
/// never removed.
class SpiritualApi {
  SpiritualApi(this._client);

  final ApiClient _client;

  /// GET /spiritual?date=YYYY-MM-DD (omit for today).
  Future<SpiritualToday> getToday({String? date}) async {
    final json = await _client.get('/spiritual', query: {if (date != null) 'date': date});
    return SpiritualToday.fromJson(json as Map<String, dynamic>);
  }

  /// POST /spiritual — upserts done/notes for one practice/date and
  /// returns the refreshed day (the backend re-runs the today() query).
  Future<SpiritualToday> toggle({
    required int practiceId,
    required bool done,
    String? notes,
    String? date,
  }) async {
    final json = await _client.post('/spiritual', body: {
      'practice_id': practiceId,
      'done': done,
      if (notes != null) 'notes': notes,
      if (date != null) 'date': date,
    });
    return SpiritualToday.fromJson(json as Map<String, dynamic>);
  }

  /// GET /spiritual/practices — full list, active and inactive.
  Future<List<SpiritualPractice>> getPractices() async {
    final json = await _client.get('/spiritual/practices');
    final list = json as List<dynamic>? ?? const [];
    return list.map((e) => SpiritualPractice.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// POST /spiritual/practices
  Future<SpiritualPractice> addPractice(String name) async {
    final json = await _client.post('/spiritual/practices', body: {'name': name});
    return SpiritualPractice.fromJson(json as Map<String, dynamic>);
  }

  /// PUT /spiritual/practices/{id}
  Future<SpiritualPractice> updatePractice(int id, {String? name, bool? active}) async {
    final json = await _client.put('/spiritual/practices/$id', body: {
      if (name != null) 'name': name,
      if (active != null) 'active': active,
    });
    return SpiritualPractice.fromJson(json as Map<String, dynamic>);
  }
}

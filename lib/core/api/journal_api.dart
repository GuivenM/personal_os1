import '../api/api_client.dart';
import '../models/journal_model.dart';

class JournalApi {
  JournalApi(this._client);

  final ApiClient _client;

  /// GET /journal (?date=YYYY-MM-DD optional, defaults to today server-side)
  Future<JournalEntry> getEntry({String? date}) async {
    final json = await _client.get('/journal', query: {if (date != null) 'date': date});
    return JournalEntry.fromJson(json as Map<String, dynamic>);
  }

  /// POST /journal — upsert for the given date.
  Future<void> saveEntry({required String date, required String content}) async {
    await _client.post('/journal', body: {'date': date, 'content': content});
  }

  /// GET /journal/history (?limit=30)
  Future<List<JournalHistoryItem>> getHistory({int limit = 30}) async {
    final json = await _client.get('/journal/history', query: {'limit': limit});
    final entries = (json as Map<String, dynamic>)['entries'] as List<dynamic>? ?? [];
    return entries.map((e) => JournalHistoryItem.fromJson(e as Map<String, dynamic>)).toList();
  }
}

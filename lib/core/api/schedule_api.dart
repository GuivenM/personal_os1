import '../api/api_client.dart';
import '../models/schedule_model.dart';

class ScheduleApi {
  ScheduleApi(this._client);

  final ApiClient _client;

  /// GET /schedule (?date=YYYY-MM-DD optional, defaults to today server-side)
  Future<ScheduleDayResponse> getSchedule({String? date}) async {
    final json = await _client.get('/schedule', query: {if (date != null) 'date': date});
    return ScheduleDayResponse.fromJson(json as Map<String, dynamic>);
  }

  /// GET /schedule/week — the 7-day template
  Future<WeekScheduleResponse> getWeek() async {
    final json = await _client.get('/schedule/week');
    return WeekScheduleResponse.fromJson(json as Map<String, dynamic>);
  }

  /// GET /schedule/history — 30-day history + current streak
  Future<ScheduleHistoryResponse> getHistory() async {
    final json = await _client.get('/schedule/history');
    return ScheduleHistoryResponse.fromJson(json as Map<String, dynamic>);
  }

  /// PUT /schedule/{id} — edit a template block (name/description/times)
  Future<void> updateBlockTemplate({
    required int blockId,
    required String name,
    required String description,
    required String timeStart,
    required String timeEnd,
  }) async {
    await _client.put('/schedule/$blockId', body: {
      'name': name,
      'description': description,
      'time_start': timeStart,
      'time_end': timeEnd,
    });
  }

  /// POST /schedule/reorder — body: { order: [id1, id2, ...] }
  Future<void> reorder(List<int> orderedBlockIds) async {
    await _client.post('/schedule/reorder', body: {'order': orderedBlockIds});
  }

  /// POST /schedule — create a template block at the end of [dayOfWeek]
  /// (0 = Monday … 6 = Sunday).
  Future<void> createBlock({
    required int dayOfWeek,
    required String name,
    required String description,
    required String timeStart,
    required String timeEnd,
  }) async {
    await _client.post('/schedule', body: {
      'day_of_week': dayOfWeek,
      'name': name,
      'description': description,
      'time_start': timeStart,
      'time_end': timeEnd,
    });
  }

  /// DELETE /schedule/{id} — removes the block AND its history logs.
  Future<void> deleteBlock(int blockId) async {
    await _client.delete('/schedule/$blockId');
  }

  /// POST /schedule/copy-day — copies [fromDay]'s blocks onto [toDays].
  /// [replace] = false appends after the existing blocks; true wipes the
  /// target days' blocks (and their logs) first.
  Future<void> copyDay({
    required int fromDay,
    required List<int> toDays,
    bool replace = false,
  }) async {
    await _client.post('/schedule/copy-day', body: {
      'from_day': fromDay,
      'to_days': toDays,
      'mode': replace ? 'replace' : 'append',
    });
  }

  /// POST /schedule/import — spreadsheet rows (see the sheet format in the
  /// import sheet). [dryRun] validates and summarises without writing.
  Future<ScheduleImportSummary> importSchedule({
    required List<List<String>> rows,
    bool replace = false,
    bool dryRun = false,
  }) async {
    final json = await _client.post('/schedule/import', body: {
      'rows': rows,
      'mode': replace ? 'replace' : 'append',
      'dry_run': dryRun,
    });
    return ScheduleImportSummary.fromJson(json as Map<String, dynamic>);
  }

  /// POST /blocks — initialize today's (or a given date's) logs.
  /// Response shape isn't guaranteed by the spec, so callers should
  /// reload via [getSchedule] right after calling this to get canonical
  /// log_ids rather than relying on this method's return value.
  Future<void> initDay({String? date}) async {
    await _client.post('/blocks', body: {if (date != null) 'date': date});
  }

  /// PUT /blocks/{log_id} — body: { status }
  Future<void> updateBlockStatus({required int logId, required String status}) async {
    await _client.put('/blocks/$logId', body: {'status': status});
  }
}

/// Result of POST /schedule/import (also returned by a dry run).
class ScheduleImportSummary {
  const ScheduleImportSummary({
    required this.blocksToCreate,
    required this.blocksToDelete,
    required this.perDay,
  });

  final int blocksToCreate;
  final int blocksToDelete;

  /// Day of week (0 = Monday) → number of blocks created that day.
  final Map<int, int> perDay;

  factory ScheduleImportSummary.fromJson(Map<String, dynamic> json) {
    final raw = json['days'];
    final perDay = <int, int>{};
    if (raw is Map) {
      raw.forEach((k, v) => perDay[int.parse(k.toString())] = (v as num).toInt());
    } else if (raw is List) {
      for (var i = 0; i < raw.length; i++) {
        perDay[i] = (raw[i] as num).toInt();
      }
    }
    return ScheduleImportSummary(
      blocksToCreate: (json['blocks_to_create'] as num?)?.toInt() ?? 0,
      blocksToDelete: (json['blocks_to_delete'] as num?)?.toInt() ?? 0,
      perDay: perDay,
    );
  }
}

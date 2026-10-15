import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/schedule_block_model.dart';
import '../../../core/models/schedule_model.dart';
import '../../../core/services/auth_service.dart';

/// Today's blocks, with status-update logic per the spec:
/// - if a block has no `log_id` yet, the day hasn't been initialized —
///   call `POST /blocks` then reload to get canonical log_ids.
/// - otherwise just `PUT /blocks/{log_id}`.
class TodayScheduleNotifier extends StateNotifier<AsyncValue<ScheduleDayResponse>> {
  TodayScheduleNotifier(this._ref) : super(const AsyncValue.loading()) {
    load();
  }

  final Ref _ref;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final api = _ref.read(scheduleApiProvider);
      final data = await api.getSchedule();
      state = AsyncValue.data(data);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> setStatus(ScheduleBlock block, String status) async {
    final current = state.value;
    if (current == null) return;

    final api = _ref.read(scheduleApiProvider);
    var workingBlocks = current.blocks;
    int logId;

    if (block.logId == null) {
      await api.initDay(date: current.date);
      final refreshed = await api.getSchedule(date: current.date);
      workingBlocks = refreshed.blocks;
      final match = workingBlocks.where((b) => b.blockId == block.blockId).toList();
      if (match.isEmpty || match.first.logId == null) {
        throw StateError("Could not initialize today's blocks.");
      }
      logId = match.first.logId!;
    } else {
      logId = block.logId!;
    }

    await api.updateBlockStatus(logId: logId, status: status);

    final newBlocks = workingBlocks
        .map((b) => b.blockId == block.blockId ? b.copyWith(logId: logId, status: status) : b)
        .toList();

    state = AsyncValue.data(current.copyWith(blocks: newBlocks));
  }
}

final todayScheduleProvider =
    StateNotifierProvider.autoDispose<TodayScheduleNotifier, AsyncValue<ScheduleDayResponse>>((ref) {
  return TodayScheduleNotifier(ref);
});

final weekScheduleProvider = FutureProvider.autoDispose<WeekScheduleResponse>((ref) async {
  final api = ref.watch(scheduleApiProvider);
  return api.getWeek();
});

final scheduleHistoryProvider = FutureProvider.autoDispose<ScheduleHistoryResponse>((ref) async {
  final api = ref.watch(scheduleApiProvider);
  return api.getHistory();
});

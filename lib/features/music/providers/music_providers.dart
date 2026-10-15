import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/music_model.dart';
import '../../../core/services/auth_service.dart';

/// null = all session types
final musicTypeFilterProvider = StateProvider.autoDispose<String?>((ref) => null);

class MusicNotifier extends StateNotifier<AsyncValue<List<MusicSession>>> {
  MusicNotifier(this._ref) : super(const AsyncValue.loading()) {
    load();
  }

  final Ref _ref;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final sessions = await _ref.read(musicApiProvider).getSessions();
      state = AsyncValue.data(sessions);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addSession({
    required String sessionType,
    required int durationMin,
    String? notes,
    String? projectName,
    required String sessionDate,
  }) async {
    final current = state.value ?? [];
    final tempId = -DateTime.now().millisecondsSinceEpoch;
    final optimistic = MusicSession(
      id: tempId,
      sessionType: sessionType,
      durationMin: durationMin,
      notes: notes,
      projectName: projectName,
      sessionDate: sessionDate,
    );
    state = AsyncValue.data([optimistic, ...current]);

    try {
      final created = await _ref.read(musicApiProvider).createSession(
            sessionType: sessionType,
            durationMin: durationMin,
            notes: notes,
            projectName: projectName,
            sessionDate: sessionDate,
          );
      final latest = state.value ?? [];
      state = AsyncValue.data(latest.map((s) => s.id == tempId ? created : s).toList());
    } catch (e) {
      final latest = state.value ?? [];
      state = AsyncValue.data(latest.where((s) => s.id != tempId).toList());
      rethrow;
    }
  }

  Future<void> deleteSession(int id) async {
    final current = state.value ?? [];
    state = AsyncValue.data(current.where((s) => s.id != id).toList());
    try {
      await _ref.read(musicApiProvider).deleteSession(id);
    } catch (e) {
      state = AsyncValue.data(current);
      rethrow;
    }
  }
}

final musicProvider = StateNotifierProvider.autoDispose<MusicNotifier, AsyncValue<List<MusicSession>>>((ref) {
  return MusicNotifier(ref);
});

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/learning_model.dart';
import '../../../core/services/auth_service.dart';

/// null = all domains
final learningDomainFilterProvider = StateProvider.autoDispose<String?>((ref) => null);

class LearningNotifier extends StateNotifier<AsyncValue<List<LearningSession>>> {
  LearningNotifier(this._ref) : super(const AsyncValue.loading()) {
    load();
  }

  final Ref _ref;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final sessions = await _ref.read(learningApiProvider).getSessions();
      state = AsyncValue.data(sessions);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Inserts a temporary session immediately (so it shows up in the list
  /// with no visible delay), then reconciles it with the server-assigned
  /// id once the request completes — rolling back cleanly on failure.
  Future<void> addSession({
    required String domain,
    String? subdomain,
    required int durationMin,
    String? content,
    String? resource,
    required int level,
    required String sessionDate,
  }) async {
    final current = state.value ?? [];
    final tempId = -DateTime.now().millisecondsSinceEpoch;
    final optimistic = LearningSession(
      id: tempId,
      domain: domain,
      subdomain: subdomain,
      durationMin: durationMin,
      content: content,
      resource: resource,
      level: level,
      sessionDate: sessionDate,
    );
    state = AsyncValue.data([optimistic, ...current]);

    try {
      final created = await _ref.read(learningApiProvider).createSession(
            domain: domain,
            subdomain: subdomain,
            durationMin: durationMin,
            content: content,
            resource: resource,
            level: level,
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
      await _ref.read(learningApiProvider).deleteSession(id);
    } catch (e) {
      state = AsyncValue.data(current);
      rethrow;
    }
  }
}

final learningProvider = StateNotifierProvider.autoDispose<LearningNotifier, AsyncValue<List<LearningSession>>>((ref) {
  return LearningNotifier(ref);
});

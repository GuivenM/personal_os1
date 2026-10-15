import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/spiritual_model.dart';
import '../../../core/services/auth_service.dart';
import '../../dashboard/dashboard_screen.dart' show dashboardProvider;

/// Today's log across active practices. Backed by `GET /spiritual`;
/// `toggle` posts and simply adopts the fresh day the backend returns.
class SpiritualTodayNotifier extends StateNotifier<AsyncValue<SpiritualToday>> {
  SpiritualTodayNotifier(this._ref) : super(const AsyncValue.loading()) {
    load();
  }

  final Ref _ref;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final day = await _ref.read(spiritualApiProvider).getToday();
      state = AsyncValue.data(day);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggle(int practiceId, bool done, {String? notes}) async {
    final current = state.value;
    final existingNotes = notes ?? current?.practices.firstWhere(
          (p) => p.practiceId == practiceId,
          orElse: () => SpiritualPracticeLog(practiceId: practiceId, name: '', done: done, notes: null, logId: null),
        ).notes;

    final updated = await _ref.read(spiritualApiProvider).toggle(
          practiceId: practiceId,
          done: done,
          notes: existingNotes,
          date: current?.date,
        );
    state = AsyncValue.data(updated);
    _ref.invalidate(dashboardProvider);
  }
}

final spiritualTodayProvider = StateNotifierProvider.autoDispose<SpiritualTodayNotifier, AsyncValue<SpiritualToday>>((ref) {
  return SpiritualTodayNotifier(ref);
});

/// Full practice list (active + inactive), for the management tab.
/// Backed by `GET/POST /spiritual/practices` and `PUT .../{id}`.
class SpiritualPracticesNotifier extends StateNotifier<AsyncValue<List<SpiritualPractice>>> {
  SpiritualPracticesNotifier(this._ref) : super(const AsyncValue.loading()) {
    load();
  }

  final Ref _ref;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final practices = await _ref.read(spiritualApiProvider).getPractices();
      state = AsyncValue.data(practices);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addPractice(String name) async {
    final current = state.value;
    if (current == null) return;
    final created = await _ref.read(spiritualApiProvider).addPractice(name);
    state = AsyncValue.data([...current, created]);
    // A new practice is active by default, so it'll show up in Today too.
    _ref.invalidate(spiritualTodayProvider);
  }

  /// Practices can only be archived, never deleted (no DELETE route).
  Future<void> setActive(SpiritualPractice practice, bool active) async {
    final current = state.value;
    if (current == null) return;
    final updated = await _ref.read(spiritualApiProvider).updatePractice(practice.id, active: active);
    state = AsyncValue.data([for (final p in current) if (p.id == practice.id) updated else p]);
    _ref.invalidate(spiritualTodayProvider);
  }
}

final spiritualPracticesProvider =
    StateNotifierProvider.autoDispose<SpiritualPracticesNotifier, AsyncValue<List<SpiritualPractice>>>((ref) {
  return SpiritualPracticesNotifier(ref);
});

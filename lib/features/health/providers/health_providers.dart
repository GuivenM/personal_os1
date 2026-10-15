import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/health_model.dart';
import '../../../core/services/auth_service.dart';
import '../../dashboard/dashboard_screen.dart' show dashboardProvider;

class HealthNotifier extends StateNotifier<AsyncValue<HealthLog>> {
  HealthNotifier(this._ref) : super(const AsyncValue.loading()) {
    load();
  }

  final Ref _ref;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final log = await _ref.read(healthApiProvider).getHealth();
      state = AsyncValue.data(log);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Flips one of the three toggles. Follows the spec exactly:
  /// `POST /health` if today's log doesn't exist yet, `PUT /health`
  /// otherwise. Always re-checks `exists` against a fresh `GET /health`
  /// first, since another part of the app (the Dashboard's health chips)
  /// can create today's log independently.
  Future<void> toggle({required String field, required bool value}) async {
    final api = _ref.read(healthApiProvider);
    final current = state.value ?? await api.getHealth();

    final sleepOk = field == 'sleep' ? value : current.sleepOk;
    final exerciseOk = field == 'exercise' ? value : current.exerciseOk;
    final foodOk = field == 'food' ? value : current.foodOk;

    final HealthLog updated;
    if (current.exists) {
      updated = await api.updateHealth(sleepOk: sleepOk, exerciseOk: exerciseOk, foodOk: foodOk);
    } else {
      updated = await api.createHealth(sleepOk: sleepOk, exerciseOk: exerciseOk, foodOk: foodOk);
    }

    state = AsyncValue.data(updated.copyWith(exists: true));
    // Keep the Dashboard's read-only-looking health chips in sync.
    _ref.invalidate(dashboardProvider);
  }
}

final healthProvider = StateNotifierProvider.autoDispose<HealthNotifier, AsyncValue<HealthLog>>((ref) {
  return HealthNotifier(ref);
});

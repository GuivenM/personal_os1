import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/vision_model.dart';
import '../../../../core/services/auth_service.dart';

enum VisionSaveStatus { idle, saving, saved, error }

class VisionState {
  const VisionState({required this.data, required this.saveStatus});

  final VisionResponse data;
  final VisionSaveStatus saveStatus;

  VisionState copyWith({VisionResponse? data, VisionSaveStatus? saveStatus}) {
    return VisionState(
      data: data ?? this.data,
      saveStatus: saveStatus ?? this.saveStatus,
    );
  }
}

class VisionNotifier extends StateNotifier<AsyncValue<VisionState>> {
  VisionNotifier(this._ref) : super(const AsyncValue.loading()) {
    load();
  }

  final Ref _ref;
  Timer? _debounce;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final vision = await _ref.read(visionApiProvider).getVision();
      state = AsyncValue.data(VisionState(data: vision, saveStatus: VisionSaveStatus.idle));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Updates the vision text locally right away (so typing feels
  /// instant), and debounces the actual `PUT /vision` call by 1500ms.
  void updateVisionText(String text) {
    final current = state.value;
    if (current == null) return;
    state = AsyncValue.data(
      current.copyWith(data: current.data.copyWith(visionText: text), saveStatus: VisionSaveStatus.saving),
    );
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 1500), () => _saveVisionText(text));
  }

  Future<void> _saveVisionText(String text) async {
    try {
      await _ref.read(visionApiProvider).updateVisionText(text);
      final current = state.value;
      if (current != null) {
        state = AsyncValue.data(current.copyWith(saveStatus: VisionSaveStatus.saved));
      }
    } catch (_) {
      final current = state.value;
      if (current != null) {
        state = AsyncValue.data(current.copyWith(saveStatus: VisionSaveStatus.error));
      }
    }
  }

  Future<void> addGoal({required String title, required String horizon}) async {
    final goal = await _ref.read(visionApiProvider).addGoal(title: title, horizon: horizon);
    final current = state.value;
    if (current == null) return;
    final goals = Map<String, List<Goal>>.from(current.data.goals);
    goals[horizon] = [...(goals[horizon] ?? []), goal];
    state = AsyncValue.data(current.copyWith(data: current.data.copyWith(goals: goals)));
  }

  Future<void> toggleGoal(Goal goal) async {
    final newStatus = goal.isDone ? 'active' : 'done';
    await _ref.read(visionApiProvider).updateGoal(goal.id, status: newStatus);
    _replaceGoal(goal.copyWith(status: newStatus));
  }

  Future<void> deleteGoal(Goal goal) async {
    final current = state.value;
    if (current == null) return;
    await _ref.read(visionApiProvider).deleteGoal(goal.id);
    final goals = Map<String, List<Goal>>.from(current.data.goals);
    goals[goal.horizon] = (goals[goal.horizon] ?? []).where((g) => g.id != goal.id).toList();
    state = AsyncValue.data(current.copyWith(data: current.data.copyWith(goals: goals)));
  }

  void _replaceGoal(Goal updated) {
    final current = state.value;
    if (current == null) return;
    final goals = Map<String, List<Goal>>.from(current.data.goals);
    goals[updated.horizon] = (goals[updated.horizon] ?? []).map((g) => g.id == updated.id ? updated : g).toList();
    state = AsyncValue.data(current.copyWith(data: current.data.copyWith(goals: goals)));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

final visionProvider = StateNotifierProvider.autoDispose<VisionNotifier, AsyncValue<VisionState>>((ref) {
  return VisionNotifier(ref);
});

/// One of [goalHorizons] — filters the Goals tab.
final goalHorizonFilterProvider = StateProvider.autoDispose<String>((ref) => goalHorizons.first);

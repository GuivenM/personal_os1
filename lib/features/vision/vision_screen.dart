import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/models/vision_model.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/glass_card.dart';
import 'providers/vision_providers.dart';

class VisionScreen extends StatelessWidget {
  const VisionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Vision & Goals'),
          bottom: const TabBar(tabs: [Tab(text: 'My vision'), Tab(text: 'Goals')]),
        ),
        body: const TabBarView(children: [_VisionTextTab(), _GoalsTab()]),
      ),
    );
  }
}

class _VisionTextTab extends ConsumerStatefulWidget {
  const _VisionTextTab();

  @override
  ConsumerState<_VisionTextTab> createState() => _VisionTextTabState();
}

class _VisionTextTabState extends ConsumerState<_VisionTextTab> {
  final _controller = TextEditingController();
  bool _seeded = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visionAsync = ref.watch(visionProvider);

    return visionAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.violet)),
      error: (error, _) => ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          const SizedBox(height: 100),
          const Icon(Icons.cloud_off, size: 44, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text(
            error is ApiException ? error.message : 'Could not load your vision.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          Center(child: ElevatedButton(onPressed: () => ref.read(visionProvider.notifier).load(), child: const Text('Retry'))),
        ],
      ),
      data: (state) {
        if (!_seeded) {
          _controller.text = state.data.visionText;
          _seeded = true;
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            const Text(
              'What are you building, and why?',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _controller,
              maxLines: 12,
              minLines: 8,
              onChanged: (value) => ref.read(visionProvider.notifier).updateVisionText(value),
              decoration: const InputDecoration(hintText: 'Write your vision...'),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: _SaveIndicator(status: state.saveStatus),
            ),
            if (_controller.text.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text('Preview', style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              GlassCard(
                child: Text(
                  _controller.text,
                  style: const TextStyle(fontStyle: FontStyle.italic, color: AppColors.textSecondary, height: 1.4),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _SaveIndicator extends StatelessWidget {
  const _SaveIndicator({required this.status});
  final VisionSaveStatus status;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case VisionSaveStatus.saving:
        return const Text('●  Saving...', style: TextStyle(color: AppColors.orange, fontSize: 12));
      case VisionSaveStatus.saved:
        return const Text('✓  Saved', style: TextStyle(color: AppColors.vert, fontSize: 12));
      case VisionSaveStatus.error:
        return const Text('Could not save', style: TextStyle(color: AppColors.rouge, fontSize: 12));
      case VisionSaveStatus.idle:
        return const SizedBox.shrink();
    }
  }
}

class _GoalsTab extends ConsumerStatefulWidget {
  const _GoalsTab();

  @override
  ConsumerState<_GoalsTab> createState() => _GoalsTabState();
}

class _GoalsTabState extends ConsumerState<_GoalsTab> {
  final _newGoalController = TextEditingController();
  bool _isAdding = false;

  @override
  void dispose() {
    _newGoalController.dispose();
    super.dispose();
  }

  Future<void> _addGoal(String horizon) async {
    final title = _newGoalController.text.trim();
    if (title.isEmpty) return;
    setState(() => _isAdding = true);
    try {
      await ref.read(visionProvider.notifier).addGoal(title: title, horizon: horizon);
      _newGoalController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not add this goal: $e')));
      }
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final visionAsync = ref.watch(visionProvider);
    final horizon = ref.watch(goalHorizonFilterProvider);

    return visionAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.violet)),
      error: (error, _) => ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          const SizedBox(height: 100),
          const Icon(Icons.cloud_off, size: 44, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text(
            error is ApiException ? error.message : 'Could not load your goals.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          Center(child: ElevatedButton(onPressed: () => ref.read(visionProvider.notifier).load(), child: const Text('Retry'))),
        ],
      ),
      data: (state) {
        final goals = state.data.goals[horizon] ?? [];

        return Column(
          children: [
            const SizedBox(height: 16),
            SizedBox(
              height: 40,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: goalHorizons.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final value = goalHorizons[index];
                  final selected = value == horizon;
                  return ChoiceChip(
                    label: Text(goalHorizonLabel(value)),
                    selected: selected,
                    onSelected: (_) => ref.read(goalHorizonFilterProvider.notifier).state = value,
                    selectedColor: AppColors.violet,
                    backgroundColor: AppColors.surfaceGlass,
                    labelStyle: TextStyle(color: selected ? Colors.white : AppColors.textSecondary, fontWeight: FontWeight.w600),
                    side: BorderSide(color: selected ? AppColors.violet : AppColors.borderGlass),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: goals.isEmpty
                  ? const Center(child: Text('No goals for this horizon yet.', style: TextStyle(color: AppColors.textMuted)))
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: goals.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final goal = goals[index];
                        return Dismissible(
                          key: ValueKey(goal.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(color: AppColors.rouge.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                            child: const Icon(Icons.delete_outline, color: AppColors.rouge),
                          ),
                          onDismissed: (_) => ref.read(visionProvider.notifier).deleteGoal(goal),
                          child: GlassCard(
                            onTap: () => ref.read(visionProvider.notifier).toggleGoal(goal),
                            child: Row(
                              children: [
                                Icon(
                                  goal.isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                                  color: goal.isDone ? AppColors.vert : AppColors.textMuted,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    goal.title,
                                    style: TextStyle(
                                      fontSize: 15,
                                      decoration: goal.isDone ? TextDecoration.lineThrough : null,
                                      color: goal.isDone ? AppColors.textMuted : AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _newGoalController,
                      decoration: InputDecoration(hintText: 'Add a goal for ${goalHorizonLabel(horizon)}'),
                      onSubmitted: (_) => _addGoal(horizon),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filled(
                    onPressed: _isAdding ? null : () => _addGoal(horizon),
                    style: IconButton.styleFrom(backgroundColor: AppColors.violet),
                    icon: _isAdding
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
                        : const Icon(Icons.add, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

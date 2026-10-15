import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/models/spiritual_model.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/glass_card.dart';
import 'providers/spiritual_providers.dart';

class SpiritualScreen extends StatelessWidget {
  const SpiritualScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Spiritual'),
          bottom: const TabBar(tabs: [Tab(text: 'Today'), Tab(text: 'Practices')]),
        ),
        body: const TabBarView(children: [_TodayTab(), _PracticesTab()]),
      ),
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  const _ErrorRetry({required this.error, required this.fallbackMessage, required this.onRetry});

  final Object error;
  final String fallbackMessage;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        const SizedBox(height: 100),
        const Icon(Icons.cloud_off, size: 44, color: AppColors.textMuted),
        const SizedBox(height: 16),
        Text(
          error is ApiException ? (error as ApiException).message : fallbackMessage,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 20),
        Center(child: ElevatedButton(onPressed: onRetry, child: const Text('Retry'))),
      ],
    );
  }
}

class _TodayTab extends ConsumerWidget {
  const _TodayTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(spiritualTodayProvider);

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.violet)),
      error: (error, _) => _ErrorRetry(
        error: error,
        fallbackMessage: "Could not load today's practices.",
        onRetry: () => ref.read(spiritualTodayProvider.notifier).load(),
      ),
      data: (day) {
        if (day.practices.isEmpty) {
          return const Center(
            child: Text('No active practices yet — add one in the Practices tab.', style: TextStyle(color: AppColors.textMuted)),
          );
        }
        final doneCount = day.practices.where((p) => p.done).length;

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          children: [
            Text('$doneCount/${day.practices.length} today', style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            const SizedBox(height: 20),
            for (final practice in day.practices) ...[
              _PracticeToggle(
                practice: practice,
                onTap: () => ref.read(spiritualTodayProvider.notifier).toggle(practice.practiceId, !practice.done),
                onEditNote: () => _editNote(context, ref, practice),
              ),
              const SizedBox(height: 16),
            ],
          ],
        );
      },
    );
  }

  Future<void> _editNote(BuildContext context, WidgetRef ref, SpiritualPracticeLog practice) async {
    final controller = TextEditingController(text: practice.notes ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(practice.name),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Add a note for today...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(controller.text.trim()), child: const Text('Save')),
        ],
      ),
    );
    if (result == null) return;
    await ref.read(spiritualTodayProvider.notifier).toggle(practice.practiceId, practice.done, notes: result);
  }
}

class _PracticeToggle extends StatefulWidget {
  const _PracticeToggle({required this.practice, required this.onTap, required this.onEditNote});

  final SpiritualPracticeLog practice;
  final Future<void> Function() onTap;
  final VoidCallback onEditNote;

  @override
  State<_PracticeToggle> createState() => _PracticeToggleState();
}

class _PracticeToggleState extends State<_PracticeToggle> {
  bool _isUpdating = false;

  Future<void> _handleTap() async {
    if (_isUpdating) return;
    setState(() => _isUpdating = true);
    try {
      await widget.onTap();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final done = widget.practice.done;
    final color = done ? AppColors.vert : AppColors.textMuted;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: _handleTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: done ? AppColors.vert.withOpacity(0.1) : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: done ? AppColors.vert.withOpacity(0.5) : AppColors.borderGlass, width: 1.4),
          boxShadow: [
            BoxShadow(color: const Color(0xFF1C1C24).withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: color.withOpacity(0.14), shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Icon(Icons.self_improvement_outlined, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.practice.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  if (widget.practice.notes != null && widget.practice.notes!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      widget.practice.notes!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_note_outlined, color: AppColors.textMuted),
              onPressed: widget.onEditNote,
              tooltip: 'Add a note',
            ),
            _isUpdating
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.2, color: AppColors.violet))
                : Icon(done ? Icons.check_circle : Icons.radio_button_unchecked, color: color, size: 26),
          ],
        ),
      ),
    );
  }
}

class _PracticesTab extends ConsumerStatefulWidget {
  const _PracticesTab();

  @override
  ConsumerState<_PracticesTab> createState() => _PracticesTabState();
}

class _PracticesTabState extends ConsumerState<_PracticesTab> {
  final _newPracticeController = TextEditingController();
  bool _isAdding = false;

  @override
  void dispose() {
    _newPracticeController.dispose();
    super.dispose();
  }

  Future<void> _addPractice() async {
    final name = _newPracticeController.text.trim();
    if (name.isEmpty) return;
    setState(() => _isAdding = true);
    try {
      await ref.read(spiritualPracticesProvider.notifier).addPractice(name);
      _newPracticeController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not add this practice: $e')));
      }
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(spiritualPracticesProvider);

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.violet)),
      error: (error, _) => _ErrorRetry(
        error: error,
        fallbackMessage: 'Could not load your practices.',
        onRetry: () => ref.read(spiritualPracticesProvider.notifier).load(),
      ),
      data: (practices) {
        return Column(
          children: [
            Expanded(
              child: practices.isEmpty
                  ? const Center(child: Text('No practices yet — add your first one below.', style: TextStyle(color: AppColors.textMuted)))
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                      itemCount: practices.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final practice = practices[index];
                        return GlassCard(
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  practice.name,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: practice.active ? AppColors.textPrimary : AppColors.textMuted,
                                  ),
                                ),
                              ),
                              // No delete route on the backend — practices
                              // are archived (active: false), never removed.
                              Switch(
                                value: practice.active,
                                activeColor: AppColors.violet,
                                onChanged: (value) => ref.read(spiritualPracticesProvider.notifier).setActive(practice, value),
                              ),
                            ],
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
                      controller: _newPracticeController,
                      decoration: const InputDecoration(hintText: 'Add a practice (e.g. Méditation)'),
                      onSubmitted: (_) => _addPractice(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filled(
                    onPressed: _isAdding ? null : _addPractice,
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

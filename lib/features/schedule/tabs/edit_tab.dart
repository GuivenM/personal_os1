import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/models/schedule_block_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_card.dart';
import '../providers/schedule_providers.dart';

const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

class EditTab extends ConsumerStatefulWidget {
  const EditTab({super.key});

  @override
  ConsumerState<EditTab> createState() => _EditTabState();
}

class _EditTabState extends ConsumerState<EditTab> {
  int _selectedDay = DateTime.now().weekday - 1;

  /// Local, editable copy of the selected day's blocks (kept in sync with
  /// [weekScheduleProvider] but mutated optimistically on reorder/save).
  List<ScheduleBlock>? _localBlocks;
  int? _localBlocksForDay;

  void _syncLocalBlocks(List<ScheduleBlock> fromServer) {
    if (_localBlocksForDay != _selectedDay) {
      _localBlocks = [...fromServer];
      _localBlocksForDay = _selectedDay;
    }
  }

  Future<void> _reload() async {
    ref.invalidate(weekScheduleProvider);
    setState(() {
      _localBlocks = null;
      _localBlocksForDay = null;
    });
    // Editing a template can change today's blocks too.
    ref.invalidate(todayScheduleProvider);
  }

  @override
  Widget build(BuildContext context) {
    final weekAsync = ref.watch(weekScheduleProvider);

    return weekAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.violet)),
      error: (error, _) => ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          const SizedBox(height: 100),
          const Icon(Icons.cloud_off, size: 44, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text(
            error is ApiException ? error.message : 'Could not load the week template.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton(onPressed: _reload, child: const Text('Retry')),
          ),
        ],
      ),
      data: (week) {
        final day = week.days.where((d) => d.dayOfWeek == _selectedDay).toList();
        final serverBlocks = day.isNotEmpty ? day.first.blocks : const <ScheduleBlock>[];
        _syncLocalBlocks(serverBlocks);
        final blocks = _localBlocks ?? serverBlocks;

        return Column(
          children: [
            const SizedBox(height: 16),
            SizedBox(
              height: 44,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: 7,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final selected = index == _selectedDay;
                  return ChoiceChip(
                    label: Text(_dayLabels[index]),
                    selected: selected,
                    onSelected: (_) => setState(() => _selectedDay = index),
                    selectedColor: AppColors.violet,
                    backgroundColor: AppColors.surfaceGlass,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                    side: BorderSide(color: selected ? AppColors.violet : AppColors.borderGlass),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: const [
                  Expanded(
                    child: Text(
                      'Tap a block to edit it. Hold and drag the handle to reorder.',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: blocks.isEmpty
                  ? const Center(child: Text('No blocks for this day.', style: TextStyle(color: AppColors.textMuted)))
                  : ReorderableListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                      itemCount: blocks.length,
                      onReorder: (oldIndex, newIndex) => _handleReorder(blocks, oldIndex, newIndex),
                      itemBuilder: (context, index) {
                        final block = blocks[index];
                        return Padding(
                          key: ValueKey(block.blockId),
                          padding: const EdgeInsets.only(bottom: 10),
                          child: GlassCard(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            onTap: () => _openEditSheet(block),
                            child: Row(
                              children: [
                                const Icon(Icons.drag_indicator, color: AppColors.textMuted, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(block.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                                      Text(
                                        '${_trimSeconds(block.timeStart)} – ${_trimSeconds(block.timeEnd)}',
                                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right, color: AppColors.textMuted),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleReorder(List<ScheduleBlock> blocks, int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex -= 1;
    final reordered = [...blocks];
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, moved);

    setState(() {
      _localBlocks = reordered;
      _localBlocksForDay = _selectedDay;
    });

    try {
      await ref.read(scheduleApiProvider).reorder(reordered.map((b) => b.blockId).toList());
      ref.invalidate(todayScheduleProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save the new order: $e')),
        );
      }
    }
  }

  Future<void> _openEditSheet(ScheduleBlock block) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => _EditBlockSheet(block: block),
    );

    if (saved == true) {
      await _reload();
    }
  }
}

class _EditBlockSheet extends ConsumerStatefulWidget {
  const _EditBlockSheet({required this.block});
  final ScheduleBlock block;

  @override
  ConsumerState<_EditBlockSheet> createState() => _EditBlockSheetState();
}

class _EditBlockSheetState extends ConsumerState<_EditBlockSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late TimeOfDay _timeStart;
  late TimeOfDay _timeEnd;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.block.name);
    _descriptionController = TextEditingController(text: widget.block.description);
    _timeStart = _parseTime(widget.block.timeStart);
    _timeEnd = _parseTime(widget.block.timeEnd);
  }

  static TimeOfDay _parseTime(String value) {
    final parts = value.split(':');
    if (parts.length >= 2) {
      return TimeOfDay(hour: int.tryParse(parts[0]) ?? 0, minute: int.tryParse(parts[1]) ?? 0);
    }
    return const TimeOfDay(hour: 0, minute: 0);
  }

  String _formatTimeForApi(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m:00';
  }

  String _formatTimeLabel(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _timeStart : _timeEnd,
    );
    if (picked != null) {
      setState(() => isStart ? _timeStart = picked : _timeEnd = picked);
    }
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      setState(() => _error = 'Name is required.');
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      await ref.read(scheduleApiProvider).updateBlockTemplate(
            blockId: widget.block.blockId,
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim(),
            timeStart: _formatTimeForApi(_timeStart),
            timeEnd: _formatTimeForApi(_timeEnd),
          );
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Could not save changes.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Edit block', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 18),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _TimeField(label: 'Start', value: _formatTimeLabel(_timeStart), onTap: () => _pickTime(true)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TimeField(label: 'End', value: _formatTimeLabel(_timeEnd), onTap: () => _pickTime(false)),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 14),
              Text(_error!, style: const TextStyle(color: AppColors.rouge, fontSize: 13)),
            ],
            const SizedBox(height: 22),
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeField extends StatelessWidget {
  const _TimeField({required this.label, required this.value, required this.onTap});

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceGlass,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderGlass),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ],
            ),
            const Icon(Icons.access_time, color: AppColors.textMuted, size: 18),
          ],
        ),
      ),
    );
  }
}

String _trimSeconds(String time) {
  final parts = time.split(':');
  if (parts.length >= 2) return '${parts[0]}:${parts[1]}';
  return time;
}

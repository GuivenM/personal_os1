import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/schedule_api.dart';
import '../../../core/models/schedule_block_model.dart';
import '../../../core/models/schedule_model.dart';
import '../../../core/utils/sheet_text.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_card.dart';
import '../providers/schedule_providers.dart';

const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tap a block to edit it. Hold and drag the handle to reorder.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _openCreateSheet,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add block'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: blocks.isEmpty ? null : _openCopySheet,
                          icon: const Icon(Icons.copy_all_outlined, size: 18),
                          label: const Text('Copy day'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _openImportSheet,
                          icon: const Icon(Icons.table_view_outlined, size: 18),
                          label: const Text('Import'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _exportWeek(week),
                          icon: const Icon(Icons.content_copy_outlined, size: 18),
                          label: const Text('Copy as sheet'),
                        ),
                      ),
                    ],
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

  Future<void> _openEditSheet(ScheduleBlock block) => _showBlockSheet(block: block);

  Future<void> _openCreateSheet() {
    // Suggest starting where the day's last block ends.
    final blocks = _localBlocks ?? const <ScheduleBlock>[];
    final suggestedStart = blocks.isEmpty ? null : _parseTimeOfDay(blocks.last.timeEnd);
    return _showBlockSheet(suggestedStart: suggestedStart);
  }

  Future<void> _showBlockSheet({ScheduleBlock? block, TimeOfDay? suggestedStart}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => _EditBlockSheet(
        block: block,
        dayOfWeek: _selectedDay,
        suggestedStart: suggestedStart,
      ),
    );

    if (saved == true) {
      await _reload();
    }
  }

  Future<void> _openImportSheet() async {
    final imported = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => const _ImportSheet(),
    );

    if (imported == true) {
      await _reload();
    }
  }

  /// Puts the whole week on the clipboard as tab-separated text: paste it in
  /// Google Sheets / Excel, edit, copy the cells back and use Import.
  Future<void> _exportWeek(WeekScheduleResponse week) async {
    await Clipboard.setData(ClipboardData(text: buildScheduleTsv(week)));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Week copied. Paste it into Google Sheets or Excel.')),
    );
  }

  Future<void> _openCopySheet() async {
    final copied = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => _CopyDaySheet(fromDay: _selectedDay),
    );

    if (copied == true) {
      await _reload();
    }
  }
}

class _EditBlockSheet extends ConsumerStatefulWidget {
  const _EditBlockSheet({required this.block, required this.dayOfWeek, this.suggestedStart});

  /// null = creating a new block on [dayOfWeek].
  final ScheduleBlock? block;
  final int dayOfWeek;
  final TimeOfDay? suggestedStart;

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
    final block = widget.block;
    _nameController = TextEditingController(text: block?.name ?? '');
    _descriptionController = TextEditingController(text: block?.description ?? '');
    if (block != null) {
      _timeStart = _parseTime(block.timeStart);
      _timeEnd = _parseTime(block.timeEnd);
    } else {
      _timeStart = widget.suggestedStart ?? const TimeOfDay(hour: 9, minute: 0);
      final endHour = _timeStart.hour + 1;
      _timeEnd = endHour > 23 ? const TimeOfDay(hour: 23, minute: 59) : TimeOfDay(hour: endHour, minute: _timeStart.minute);
    }
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
    if (_timeEnd.hour * 60 + _timeEnd.minute <= _timeStart.hour * 60 + _timeStart.minute) {
      setState(() => _error = 'End must be after start.');
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final api = ref.read(scheduleApiProvider);
      final block = widget.block;
      if (block == null) {
        await api.createBlock(
          dayOfWeek: widget.dayOfWeek,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          timeStart: _formatTimeForApi(_timeStart),
          timeEnd: _formatTimeForApi(_timeEnd),
        );
      } else {
        await api.updateBlockTemplate(
          blockId: block.blockId,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          timeStart: _formatTimeForApi(_timeStart),
          timeEnd: _formatTimeForApi(_timeEnd),
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Could not save changes.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _delete() async {
    final block = widget.block;
    if (block == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete "${block.name}"?'),
        content: const Text('This block and its completion history will be removed. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: AppColors.rouge)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      await ref.read(scheduleApiProvider).deleteBlock(block.blockId);
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not delete the block.');
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
            Text(
              widget.block == null ? 'New block · ${_dayNames[widget.dayOfWeek]}' : 'Edit block',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
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
                  : Text(widget.block == null ? 'Add block' : 'Save'),
            ),
            if (widget.block != null) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _isSaving ? null : _delete,
                icon: const Icon(Icons.delete_outline, color: AppColors.rouge, size: 20),
                label: const Text('Delete block', style: TextStyle(color: AppColors.rouge)),
              ),
            ],
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

/// Import a schedule from spreadsheet cells (paste) or a CSV/TSV file.
class _ImportSheet extends ConsumerStatefulWidget {
  const _ImportSheet();

  @override
  ConsumerState<_ImportSheet> createState() => _ImportSheetState();
}

class _ImportSheetState extends ConsumerState<_ImportSheet> {
  final _controller = TextEditingController();
  bool _replace = false;
  bool _busy = false;
  String? _error;
  List<String> _details = const [];
  ScheduleImportSummary? _summary;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Any change to the text or mode invalidates the previous preview.
  void _resetPreview() {
    if (_summary == null && _error == null) return;
    setState(() {
      _summary = null;
      _error = null;
      _details = const [];
    });
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.trim().isEmpty) return;
    _controller.text = text;
    _resetPreview();
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['csv', 'tsv', 'txt'],
        withData: true,
      );
      final bytes = result?.files.single.bytes;
      if (bytes == null) return;
      _controller.text = utf8.decode(bytes, allowMalformed: true);
      _resetPreview();
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not read that file. Export it as CSV (UTF-8) and try again.');
    }
  }

  Future<void> _run({required bool dryRun}) async {
    final rows = parseDelimited(_controller.text);
    if (rows.isEmpty) {
      setState(() => _error = 'Paste some rows or pick a file first.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _details = const [];
    });
    try {
      final summary = await ref.read(scheduleApiProvider).importSchedule(
            rows: rows,
            replace: _replace,
            dryRun: dryRun,
          );
      if (dryRun) {
        if (mounted) setState(() => _summary = summary);
      } else {
        ref.invalidate(todayScheduleProvider);
        if (mounted) Navigator.of(context).pop(true);
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _details = e.details ?? const [];
          _summary = null;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not import the schedule.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _breakdown(ScheduleImportSummary s) {
    final days = s.perDay.keys.toList()..sort();
    return days.map((d) => '${_dayLabels[d]} ${s.perDay[d]}').join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final summary = _summary;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Import schedule', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text(
              'Columns: Day, Start, End, Name, Description (a header row is optional).\n'
              'Day accepts Mon, Mon-Fri, Mon/Wed/Fri, Daily, Weekdays or Weekend. '
              'Times: 6:30, 18:00, 6h30 or 6:30 PM.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : _paste,
                    icon: const Icon(Icons.content_paste, size: 18),
                    label: const Text('Paste'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : _pickFile,
                    icon: const Icon(Icons.upload_file, size: 18),
                    label: const Text('Choose file'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              minLines: 5,
              maxLines: 9,
              onChanged: (_) => _resetPreview(),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              decoration: const InputDecoration(
                hintText: 'Day\tStart\tEnd\tName\tDescription\nMon-Fri\t06:30\t07:00\tWake up\t',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Add to existing')),
                ButtonSegment(value: true, label: Text('Replace days')),
              ],
              selected: {_replace},
              onSelectionChanged: (value) {
                setState(() => _replace = value.first);
                _resetPreview();
              },
            ),
            if (_replace) ...[
              const SizedBox(height: 8),
              const Text(
                'Replace only affects the days present in your file. Their current blocks and completion history are deleted.',
                style: TextStyle(color: AppColors.rouge, fontSize: 12),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppColors.rouge, fontSize: 13, fontWeight: FontWeight.w600)),
              for (final line in _details)
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(line, style: const TextStyle(color: AppColors.rouge, fontSize: 12)),
                ),
            ],
            if (summary != null) ...[
              const SizedBox(height: 12),
              Text(
                'Ready: ${summary.blocksToCreate} block(s) will be created (${_breakdown(summary)}).'
                '${summary.blocksToDelete > 0 ? '\nThis deletes ${summary.blocksToDelete} existing block(s) and their history.' : ''}',
                style: const TextStyle(fontSize: 13),
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _busy ? null : () => _run(dryRun: summary == null),
              child: _busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                    )
                  : Text(summary == null ? 'Preview' : 'Import ${summary.blocksToCreate} block(s)'),
            ),
          ],
        ),
      ),
    );
  }
}

TimeOfDay _parseTimeOfDay(String value) {
  final parts = value.split(':');
  if (parts.length >= 2) {
    return TimeOfDay(hour: int.tryParse(parts[0]) ?? 0, minute: int.tryParse(parts[1]) ?? 0);
  }
  return const TimeOfDay(hour: 9, minute: 0);
}

/// Copy one day's blocks onto other days of the week.
class _CopyDaySheet extends ConsumerStatefulWidget {
  const _CopyDaySheet({required this.fromDay});

  final int fromDay;

  @override
  ConsumerState<_CopyDaySheet> createState() => _CopyDaySheetState();
}

class _CopyDaySheetState extends ConsumerState<_CopyDaySheet> {
  final Set<int> _targets = {};
  bool _replace = false;
  bool _isSaving = false;
  String? _error;

  Future<void> _copy() async {
    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      await ref.read(scheduleApiProvider).copyDay(
            fromDay: widget.fromDay,
            toDays: _targets.toList()..sort(),
            replace: _replace,
          );
      ref.invalidate(todayScheduleProvider);
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not copy the day.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final others = [for (var i = 0; i < 7; i++) if (i != widget.fromDay) i];
    final allSelected = _targets.length == others.length;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Copy ${_dayNames[widget.fromDay]} to…',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilterChip(
                  label: const Text('All other days'),
                  selected: allSelected,
                  selectedColor: AppColors.violet.withOpacity(0.18),
                  onSelected: (on) => setState(() {
                    _targets
                      ..clear()
                      ..addAll(on ? others : const <int>[]);
                  }),
                ),
                for (final d in others)
                  FilterChip(
                    label: Text(_dayLabels[d]),
                    selected: _targets.contains(d),
                    selectedColor: AppColors.violet.withOpacity(0.18),
                    onSelected: (on) => setState(() => on ? _targets.add(d) : _targets.remove(d)),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Add to existing')),
                ButtonSegment(value: true, label: Text('Replace existing')),
              ],
              selected: {_replace},
              onSelectionChanged: (value) => setState(() => _replace = value.first),
            ),
            if (_replace) ...[
              const SizedBox(height: 10),
              const Text(
                'Replacing deletes the selected days\' current blocks together with their completion history.',
                style: TextStyle(color: AppColors.rouge, fontSize: 12),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppColors.rouge, fontSize: 13)),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isSaving || _targets.isEmpty ? null : _copy,
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                    )
                  : Text(_targets.isEmpty ? 'Select days' : 'Copy to ${_targets.length} day(s)'),
            ),
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

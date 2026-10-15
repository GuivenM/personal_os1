import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_card.dart';
import '../providers/schedule_providers.dart';

const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

class WeekTab extends ConsumerStatefulWidget {
  const WeekTab({super.key});

  @override
  ConsumerState<WeekTab> createState() => _WeekTabState();
}

class _WeekTabState extends ConsumerState<WeekTab> {
  int _selectedDay = DateTime.now().weekday - 1; // 0 = Monday

  @override
  Widget build(BuildContext context) {
    final weekAsync = ref.watch(weekScheduleProvider);

    return RefreshIndicator(
      onRefresh: () => ref.refresh(weekScheduleProvider.future),
      child: weekAsync.when(
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
              child: ElevatedButton(
                onPressed: () => ref.invalidate(weekScheduleProvider),
                child: const Text('Retry'),
              ),
            ),
          ],
        ),
        data: (week) {
          final day = week.days.where((d) => d.dayOfWeek == _selectedDay).toList();
          final blocks = day.isNotEmpty ? day.first.blocks : const [];
          final dayName = day.isNotEmpty && day.first.dayName.isNotEmpty ? day.first.dayName : _dayLabels[_selectedDay];

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              SizedBox(
                height: 44,
                child: ListView.separated(
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
              const SizedBox(height: 18),
              Text(dayName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              if (blocks.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(
                    child: Text('No blocks for this day.', style: TextStyle(color: AppColors.textMuted)),
                  ),
                )
              else
                for (final block in blocks) ...[
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text(block.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
                            Text(
                              '${_trimSeconds(block.timeStart)} – ${_trimSeconds(block.timeEnd)}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                        if (block.description.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(block.description, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4)),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
            ],
          );
        },
      ),
    );
  }
}

String _trimSeconds(String time) {
  final parts = time.split(':');
  if (parts.length >= 2) return '${parts[0]}:${parts[1]}';
  return time;
}

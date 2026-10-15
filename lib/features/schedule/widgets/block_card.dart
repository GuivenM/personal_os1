import 'package:flutter/material.dart';

import '../../../core/models/schedule_block_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/status_badge.dart';

/// A single block row on the "Today" tab: name, time range, status badge,
/// an expandable description, and three action buttons (Done / Partial /
/// Skipped).
class BlockCard extends StatefulWidget {
  const BlockCard({
    super.key,
    required this.block,
    required this.onSetStatus,
  });

  final ScheduleBlock block;
  final Future<void> Function(String status) onSetStatus;

  @override
  State<BlockCard> createState() => _BlockCardState();
}

class _BlockCardState extends State<BlockCard> {
  bool _expanded = false;
  bool _isUpdating = false;

  Future<void> _handleStatus(String status) async {
    if (_isUpdating) return;
    setState(() => _isUpdating = true);
    try {
      await widget.onSetStatus(status);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update this block: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final block = widget.block;

    return GlassCard(
      borderColor: block.isCurrent ? AppColors.violet.withOpacity(0.6) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: block.description.isEmpty ? null : () => setState(() => _expanded = !_expanded),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              block.name,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (block.isCurrent) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.violet.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Text(
                                'NOW',
                                style: TextStyle(color: AppColors.violet, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_trimSeconds(block.timeStart)} – ${_trimSeconds(block.timeEnd)}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                StatusBadge(status: block.status),
                if (block.description.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  Icon(_expanded ? Icons.expand_less : Icons.expand_more, color: AppColors.textMuted, size: 20),
                ],
              ],
            ),
          ),
          if (_expanded && block.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(block.description, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4)),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: 'Done',
                  color: AppColors.vert,
                  active: block.status == 'done',
                  isLoading: _isUpdating,
                  onTap: () => _handleStatus('done'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionButton(
                  label: 'Partial',
                  color: AppColors.orange,
                  active: block.status == 'partial',
                  isLoading: _isUpdating,
                  onTap: () => _handleStatus('partial'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionButton(
                  label: 'Skipped',
                  color: AppColors.rouge,
                  active: block.status == 'skipped',
                  isLoading: _isUpdating,
                  onTap: () => _handleStatus('skipped'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.color,
    required this.active,
    required this.isLoading,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool active;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? color.withOpacity(0.18) : AppColors.surfaceGlass,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: isLoading ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: active ? color.withOpacity(0.6) : AppColors.borderGlass),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: active ? color : AppColors.textSecondary,
            ),
          ),
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

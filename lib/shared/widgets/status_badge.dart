import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Small colored pill showing a block/log status.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final String status; // done | partial | skipped | pending

  String get _label {
    switch (status) {
      case 'done':
        return 'Done';
      case 'partial':
        return 'Partial';
      case 'skipped':
        return 'Skipped';
      case 'pending':
      default:
        return 'To do';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = AppColors.statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        _label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

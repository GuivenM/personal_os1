import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Placeholder screen for tabs/pages not built yet.
class ComingSoon extends StatelessWidget {
  const ComingSoon({super.key, required this.title, this.icon = Icons.hourglass_empty});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: AppColors.textMuted),
            const SizedBox(height: 14),
            const Text('Coming soon', style: TextStyle(color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

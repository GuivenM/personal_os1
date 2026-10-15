import 'package:flutter/material.dart';

import '../../core/services/notification_service.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/coming_soon.dart';
import '../health/health_screen.dart';
import '../journal/journal_screen.dart';
import '../learning/learning_screen.dart';
import '../music/music_screen.dart';
import '../recap/recap_screen.dart';
import '../spiritual/spiritual_screen.dart';
import '../vision/vision_screen.dart';

class _MoreItem {
  const _MoreItem({required this.label, required this.icon, this.builder, this.onTap});
  final String label;
  final IconData icon;
  final WidgetBuilder? builder;
  final VoidCallback? onTap;
}

final _items = <_MoreItem>[
  _MoreItem(label: 'Journal', icon: Icons.edit_note_outlined, builder: (context) => const JournalScreen()),
  _MoreItem(label: 'Vision & Goals', icon: Icons.flag_outlined, builder: (context) => const VisionScreen()),
  _MoreItem(label: 'Learning', icon: Icons.school_outlined, builder: (context) => const LearningScreen()),
  _MoreItem(label: 'Music · Zixe', icon: Icons.music_note_outlined, builder: (context) => const MusicScreen()),
  _MoreItem(label: 'Health', icon: Icons.favorite_outline, builder: (context) => const HealthScreen()),
  _MoreItem(label: 'Spiritual', icon: Icons.self_improvement_outlined, builder: (context) => const SpiritualScreen()),
  const _MoreItem(label: 'Network', icon: Icons.people_outline),
  _MoreItem(label: 'Monthly AI recap', icon: Icons.auto_awesome_outlined, builder: (context) => const RecapScreen()),
  _MoreItem(
    label: 'Send test notification',
    icon: Icons.notifications_active_outlined,
    onTap: () => NotificationService.instance.showTestNotification(),
  ),
];

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        itemCount: _items.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = _items[index];
          return Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                if (item.onTap != null) {
                  item.onTap!();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${item.label} sent.')),
                  );
                  return;
                }
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: item.builder ?? (context) => ComingSoon(title: item.label, icon: item.icon),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderGlass),
                ),
                child: Row(
                  children: [
                    Icon(item.icon, color: AppColors.violet, size: 22),
                    const SizedBox(width: 14),
                    Expanded(child: Text(item.label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
                    const Icon(Icons.chevron_right, color: AppColors.textMuted),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

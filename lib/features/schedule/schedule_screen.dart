import 'package:flutter/material.dart';

import 'tabs/edit_tab.dart';
import 'tabs/history_tab.dart';
import 'tabs/today_tab.dart';
import 'tabs/week_tab.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Planning'),
          bottom: const TabBar(
            isScrollable: false,
            tabs: [
              Tab(text: 'Today'),
              Tab(text: 'Week'),
              Tab(text: 'History'),
              Tab(text: 'Edit'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            TodayTab(),
            WeekTab(),
            HistoryTab(),
            EditTab(),
          ],
        ),
      ),
    );
  }
}

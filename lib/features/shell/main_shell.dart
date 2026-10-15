import 'package:flutter/material.dart';

import '../../shared/widgets/coming_soon.dart';
import '../books/books_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../schedule/schedule_screen.dart';
 import '../more/more_screen.dart';

/// Root shell hosting the 5-tab bottom navigation from the spec:
/// Dashboard · Planning · Books · Stats · More.
/// Dashboard, Planning and Books are wired up so far; the rest are
/// placeholders until those screens are built.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _screens = [
    DashboardScreen(),
    ScheduleScreen(),
    BooksScreen(),
    ComingSoon(title: 'Stats', icon: Icons.bar_chart_outlined),
    MoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (value) => setState(() => _index = value),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), activeIcon: Icon(Icons.calendar_today), label: 'Planning'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book_outlined), activeIcon: Icon(Icons.menu_book), label: 'Books'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), activeIcon: Icon(Icons.bar_chart), label: 'Stats'),
          BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: 'More'),
        ],
      ),
    );
  }
}

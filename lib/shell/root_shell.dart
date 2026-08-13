import 'package:flutter/material.dart';

import '../screens/home/home_screen.dart';
import '../screens/news/news_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/ranking/ranking_screen.dart';
import '../theme/app_colors.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int index = 0;

  static const _tabs = [
    HomeScreen(),
    RankingScreen(),
    NewsScreen(),
    ProfileScreen(),
  ];

  static const _labels = ['Home', 'Rangliste', 'News', 'Profil'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: index, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: [
          for (var i = 0; i < _labels.length; i++)
            NavigationDestination(
              icon: _NavMark(active: index == i),
              selectedIcon: _NavMark(active: true),
              label: _labels[i],
            ),
        ],
      ),
    );
  }
}

class _NavMark extends StatelessWidget {
  const _NavMark({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? AppColors.accent : Colors.transparent,
        border: Border.all(color: active ? AppColors.accent : AppColors.inkFaint),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import 'add_meal_screen.dart';
import 'health_context_screen.dart';
import 'history_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  final ValueNotifier<int> _refreshTrigger = ValueNotifier<int>(0);

  void _onMealSaved() {
    _refreshTrigger.value++;
  }

  void _navigateToTab(int index) {
    setState(() => _currentIndex = index);
  }

  void _openProfile() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProfileScreen(refreshTrigger: _refreshTrigger),
      ),
    );
  }

  @override
  void dispose() {
    _refreshTrigger.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        onNavigateToAddMeal: () => _navigateToTab(1),
        onNavigateToHealth: () => _navigateToTab(2),
        onNavigateToHistory: () => _navigateToTab(3),
        onNavigateToProfile: _openProfile,
        refreshTrigger: _refreshTrigger,
      ),
      AddMealScreen(
        onMealSaved: _onMealSaved,
        onOpenHealth: () => _navigateToTab(2),
      ),
      HealthContextScreen(refreshTrigger: _refreshTrigger),
      HistoryScreen(refreshTrigger: _refreshTrigger),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _navigateToTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.restaurant_outlined),
            selectedIcon: Icon(Icons.restaurant),
            label: 'Meal',
          ),
          NavigationDestination(
            icon: Icon(Icons.monitor_heart_outlined),
            selectedIcon: Icon(Icons.monitor_heart),
            label: 'Health',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
        ],
      ),
    );
  }
}

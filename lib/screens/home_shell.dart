import 'package:flutter/material.dart';

import '../core/finance_controller.dart';
import '../widgets/app_logo.dart';
import 'modules.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.controller});

  final FinanceController controller;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      DashboardScreen(controller: widget.controller),
      ExpensesScreen(controller: widget.controller),
      AnalyticsScreen(controller: widget.controller),
      AiScreen(controller: widget.controller),
      HealthScreen(controller: widget.controller),
      GoalsScreen(controller: widget.controller),
      SubscriptionsScreen(controller: widget.controller),
      ProfileScreen(controller: widget.controller),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const AppLogo(
          size: 34,
          nameStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        actions: <Widget>[
          IconButton(
            onPressed: widget.controller.toggleTheme,
            icon: const Icon(Icons.brightness_6_rounded),
            tooltip: 'Toggle Theme',
          ),
          IconButton(
            onPressed: widget.controller.syncNow,
            icon: const Icon(Icons.sync_rounded),
            tooltip: 'Sync Now',
          ),
          IconButton(
            onPressed: widget.controller.logout,
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: screens[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const <NavigationDestination>[
          NavigationDestination(icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.receipt_long_rounded), label: 'Expenses'),
          NavigationDestination(icon: Icon(Icons.query_stats_rounded), label: 'Analytics'),
          NavigationDestination(icon: Icon(Icons.psychology_rounded), label: 'AI'),
          NavigationDestination(icon: Icon(Icons.monitor_heart_rounded), label: 'Health'),
          NavigationDestination(icon: Icon(Icons.savings_rounded), label: 'Goals'),
          NavigationDestination(icon: Icon(Icons.subscriptions_rounded), label: 'Subs'),
          NavigationDestination(icon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}

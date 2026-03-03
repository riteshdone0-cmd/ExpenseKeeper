import 'package:flutter/material.dart';

import 'core/finance_controller.dart';
import 'core/theme.dart';
import 'screens/auth_screen.dart';
import 'screens/home_shell.dart';
import 'screens/splash_screen.dart';

class FinanceApp extends StatefulWidget {
  const FinanceApp({super.key});

  @override
  State<FinanceApp> createState() => _FinanceAppState();
}

class _FinanceAppState extends State<FinanceApp> {
  late final FinanceController _controller;
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    _controller = FinanceController();
    _controller.addListener(_onState);
  }

  @override
  void dispose() {
    _controller.removeListener(_onState);
    _controller.dispose();
    super.dispose();
  }

  void _onState() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final home = _showSplash
        ? SplashScreen(onFinished: () => setState(() => _showSplash = false))
        : (_controller.isAuthenticated
            ? HomeShell(controller: _controller)
            : AuthScreen(controller: _controller));

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AI Expense Intelligence',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: _controller.themeMode,
      home: home,
    );
  }
}

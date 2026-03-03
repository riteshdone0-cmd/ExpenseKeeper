import 'package:flutter/material.dart';

import '../core/finance_controller.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.controller});

  final FinanceController controller;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _loginEmail = TextEditingController(text: 'demo@finpilot.ai');
  final _loginPass = TextEditingController(text: 'demo123');
  final _registerName = TextEditingController();
  final _registerEmail = TextEditingController();
  final _registerPass = TextEditingController();
  final _registerIncome = TextEditingController(text: '60000');
  final _registerBudget = TextEditingController(text: '32000');
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _loginEmail.dispose();
    _loginPass.dispose();
    _registerName.dispose();
    _registerEmail.dispose();
    _registerPass.dispose();
    _registerIncome.dispose();
    _registerBudget.dispose();
    super.dispose();
  }

  void _handleLogin() {
    try {
      widget.controller.login(_loginEmail.text.trim(), _loginPass.text.trim());
      setState(() => _error = null);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _handleRegister() {
    final income = double.tryParse(_registerIncome.text.trim());
    final budget = double.tryParse(_registerBudget.text.trim());
    if (income == null || budget == null || income <= 0 || budget <= 0) {
      setState(() => _error = 'Income and budget must be valid numbers.');
      return;
    }
    try {
      widget.controller.register(
        name: _registerName.text.trim(),
        email: _registerEmail.text.trim(),
        password: _registerPass.text.trim(),
        monthlyIncome: income,
        monthlyBudget: budget,
      );
      setState(() => _error = null);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Card(
              margin: const EdgeInsets.all(18),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      'AI Expense Intelligence',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 14),
                    TabBar(controller: _tabs, tabs: const <Widget>[Tab(text: 'Login'), Tab(text: 'Register')]),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 330,
                      child: TabBarView(
                        controller: _tabs,
                        children: <Widget>[
                          _AuthForm(
                            children: <Widget>[
                              TextField(controller: _loginEmail, decoration: const InputDecoration(labelText: 'Email')),
                              const SizedBox(height: 10),
                              TextField(
                                controller: _loginPass,
                                obscureText: true,
                                decoration: const InputDecoration(labelText: 'Password'),
                              ),
                              const SizedBox(height: 18),
                              FilledButton(
                                onPressed: _handleLogin,
                                child: const Text('Login'),
                              ),
                            ],
                          ),
                          _AuthForm(
                            children: <Widget>[
                              TextField(controller: _registerName, decoration: const InputDecoration(labelText: 'Name')),
                              const SizedBox(height: 10),
                              TextField(controller: _registerEmail, decoration: const InputDecoration(labelText: 'Email')),
                              const SizedBox(height: 10),
                              TextField(
                                controller: _registerPass,
                                obscureText: true,
                                decoration: const InputDecoration(labelText: 'Password'),
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: _registerIncome,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(labelText: 'Monthly Income'),
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: _registerBudget,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(labelText: 'Monthly Budget'),
                              ),
                              const SizedBox(height: 14),
                              FilledButton(
                                onPressed: _handleRegister,
                                child: const Text('Create Account'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (_error != null) ...<Widget>[
                      const SizedBox(height: 10),
                      Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthForm extends StatelessWidget {
  const _AuthForm({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: children,
    );
  }
}

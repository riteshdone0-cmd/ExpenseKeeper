import 'package:flutter/material.dart';

import '../core/finance_controller.dart';
import '../widgets/app_logo.dart';

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
  int _registerPassScore = 0;
  String _registerPassLabel = '';
  final _registerIncome = TextEditingController(text: '60000');
  final _registerBudget = TextEditingController(text: '32000');
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  Future<String?> _promptForOtp(String email, {required String purpose}) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Enter OTP'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text('We sent an OTP to $email for $purpose.'),
            const SizedBox(height: 8),
            TextField(controller: controller, decoration: const InputDecoration(labelText: 'OTP')),
          ],
        ),
        actions: <Widget>[
          TextButton(onPressed: () async  => Navigator.of(ctx).pop(null), child: const Text('Cancel')),
          FilledButton(onPressed: () async => Navigator.of(ctx).pop(controller.text.trim()), child: const Text('Verify')),
        ],
      ),
    );
  }

  Future<void> _handleForgotPassword() async {
    final emailController = TextEditingController(text: _loginEmail.text.trim());
    final email = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Forgot password'),
        content: TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
        actions: <Widget>[
          TextButton(onPressed: () async  => Navigator.of(ctx).pop(null), child: const Text('Cancel')),
          FilledButton(onPressed: () async => Navigator.of(ctx).pop(emailController.text.trim()), child: const Text('Send OTP')),
        ],
      ),
    );
    if (email == null || email.isEmpty) {
      return;
    }
    try {
      final sent = widget.controller.sendPasswordResetOtp(email);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('OTP sent (demo): $sent')));
      final otp = await _promptForOtp(email, purpose: 'password reset');
      if (otp == null) {
        setState(() => _error = 'Password reset cancelled.');
        return;
      }
      final newPassController = TextEditingController();
      final newPass = await showDialog<String?>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Set new password'),
          content: TextField(controller: newPassController, obscureText: true, decoration: const InputDecoration(labelText: 'New password')),
          actions: <Widget>[
            TextButton(onPressed: () async => Navigator.of(ctx).pop(null), child: const Text('Cancel')),
            FilledButton(onPressed: () async => Navigator.of(ctx).pop(newPassController.text.trim()), child: const Text('Set')),
          ],
        ),
      );
      if (newPass == null || newPass.isEmpty) {
        setState(() => _error = 'Password reset cancelled.');
        return;
      }
      final score = _assessPassword(newPass);
      if (score < 2) {
        setState(() => _error = 'New password is too weak.');
        return;
      }
      widget.controller.resetPasswordWithOtp(email: email, otp: otp, newPassword: newPass);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated successfully')));
      setState(() => _error = null);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    }
  }

  int _assessPassword(String pwd) {
    var score = 0;
    if (pwd.length >= 8) score += 1;
    if (RegExp(r'[a-z]').hasMatch(pwd) && RegExp(r'[A-Z]').hasMatch(pwd)) score += 1;
    if (RegExp(r'\d').hasMatch(pwd)) score += 1;
    if (RegExp(r'[!@#\$%\^&*(),.?":{}|<>]').hasMatch(pwd)) score += 1;
    return score; // 0..4
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

  Future<void> _handleRegister() async {
    final income = double.tryParse(_registerIncome.text.trim());
    final budget = double.tryParse(_registerBudget.text.trim());
    final email = _registerEmail.text.trim();
    final pass = _registerPass.text.trim();
    if (income == null || budget == null || income <= 0 || budget <= 0) {
      setState(() => _error = 'Income and budget must be valid numbers.');
      return;
    }
    if (email.isEmpty || _registerName.text.trim().isEmpty) {
      setState(() => _error = 'Name and email are required.');
      return;
    }
    if (_registerPassScore < 2) {
      setState(() => _error = 'Password is too weak. Use a stronger password.');
      return;
    }

    try {
      final sentOtp = widget.controller.sendRegistrationOtp(email);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('OTP sent (demo): $sentOtp')));
    final otp = await _promptForOtp(email, purpose: 'registration');
      if (otp == null) {
        setState(() => _error = 'Registration cancelled.');
        return;
      }
      final ok = widget.controller.verifyRegistrationOtp(email, otp);
      if (!ok) {
        setState(() => _error = 'Invalid or expired OTP.');
        return;
      }
      widget.controller.register(
        name: _registerName.text.trim(),
        email: email,
        password: pass,
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
                    const AppLogo(size: 54),
                    const SizedBox(height: 8),
                    Text(
                      'AI Expense Intelligence',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
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
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(onPressed: _handleForgotPassword, child: const Text('Forgot password?')),
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
                                onChanged: (v) {
                                  final s = _assessPassword(v);
                                  setState(() {
                                    _registerPassScore = s;
                                    if (s <= 1) {
                                      _registerPassLabel = 'Weak';
                                    } else if (s == 2) {
                                      _registerPassLabel = 'Medium';
                                    } else {
                                      _registerPassLabel = 'Strong';
                                    }
                                  });
                                },
                                decoration: const InputDecoration(labelText: 'Password'),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: LinearProgressIndicator(
                                      value: _registerPassScore / 4,
                                      color: _registerPassScore >= 3 ? Colors.green : (_registerPassScore == 2 ? Colors.orange : Colors.red),
                                      backgroundColor: Colors.grey.shade200,
                                      minHeight: 6,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(_registerPassLabel),
                                ],
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

import '../models/finance_models.dart';

class AuthResponse {
  const AuthResponse({required this.token, required this.profile});

  final String token;
  final UserProfile profile;
}

class AuthService {
  final Map<String, String> _passwords = <String, String>{};
  final Map<String, UserProfile> _profiles = <String, UserProfile>{};
  final Map<String, String> _otps = <String, String>{};
  final Map<String, DateTime> _otpExpiry = <String, DateTime>{};

  AuthService() {
    final seed = const UserProfile(
      id: 'u1',
      name: 'Ritesh',
      email: 'demo@finpilot.ai',
      monthlyIncome: 85000,
      monthlyBudget: 42000,
      hiddenSavingsEnabled: false,
      hiddenSavingsPct: 0.0,
      questionnaire: <int>[3, 2, 4, 2, 4],
    );
    _profiles[seed.email] = seed;
    _passwords[seed.email] = 'demo123';
  }

  AuthResponse login(String email, String password) {
    if (!_passwords.containsKey(email) || _passwords[email] != password) {
      throw Exception('Invalid credentials');
    }
    return AuthResponse(
      token: _makeToken(email),
      profile: _profiles[email]!,
    );
  }

  /// Send an OTP for the given email. Returns the OTP (for debug/demo).
  /// OTP is valid for 5 minutes.
  String sendOtp(String email) {
    final otp = (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString();
    _otps[email] = otp;
    _otpExpiry[email] = DateTime.now().add(const Duration(minutes: 5));
    return otp;
  }

  bool verifyOtp(String email, String otp) {
    if (!_otps.containsKey(email) || !_otpExpiry.containsKey(email)) {
      return false;
    }
    final expiry = _otpExpiry[email]!;
    if (DateTime.now().isAfter(expiry)) {
      _otps.remove(email);
      _otpExpiry.remove(email);
      return false;
    }
    final match = _otps[email] == otp;
    if (match) {
      _otps.remove(email);
      _otpExpiry.remove(email);
    }
    return match;
  }

  AuthResponse register({
    required String name,
    required String email,
    required String password,
    required double monthlyIncome,
    required double monthlyBudget,
  }) {
    if (_profiles.containsKey(email)) {
      throw Exception('Email already exists');
    }
    final profile = UserProfile(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      email: email,
      monthlyIncome: monthlyIncome,
      monthlyBudget: monthlyBudget,
      hiddenSavingsEnabled: false,
      hiddenSavingsPct: 0,
      questionnaire: const <int>[3, 3, 3, 3, 3],
    );
    _profiles[email] = profile;
    _passwords[email] = password;
    return AuthResponse(
      token: _makeToken(email),
      profile: profile,
    );
  }

  /// Reset password using a previously sent OTP. Throws on failure.
  void resetPasswordWithOtp({required String email, required String otp, required String newPassword}) {
    if (!_profiles.containsKey(email)) {
      throw Exception('Unknown email');
    }
    if (!verifyOtp(email, otp)) {
      throw Exception('Invalid or expired OTP');
    }
    _passwords[email] = newPassword;
  }

  String _makeToken(String email) {
    return 'jwt_${email.hashCode}_${DateTime.now().millisecondsSinceEpoch}';
  }
}

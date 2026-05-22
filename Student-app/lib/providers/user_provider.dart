import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';
import '../services/database_helper.dart';

class User {
  final String id;
  final String name;
  final String email;
  final String studentId;
  final String department;
  final String year;
  final String phone;
  final String purpose;
  final bool isGuest;
  final DateTime? lastLogin;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.studentId,
    required this.department,
    required this.year,
    required this.phone,
    required this.purpose,
    required this.isGuest,
    this.lastLogin,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      studentId: json['student_id'] ?? '',
      department: json['department'] ?? '',
      year: json['year'] ?? '',
      phone: json['phone'] ?? '',
      purpose: json['purpose'] ?? '',
      isGuest: json['is_guest'] == true || json['is_guest'] == 1,
      lastLogin: json['last_login'] != null
          ? DateTime.tryParse(json['last_login'])
          : null,
    );
  }
}

class UserProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final _storage = const FlutterSecureStorage();
  User? _user;
  String? _token;
  bool _isLoading = false;
  Map<String, dynamic>? _settings;

  UserProvider() {
    loadSession();
  }

  User? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null;
  bool get isStudent => _user != null && !_user!.isGuest;
  bool get isGuest => _user != null && _user!.isGuest;
  Map<String, dynamic>? get settings => _settings;

  Future<void> loadSession() async {
    if (kIsWeb) return;

    final storedUser = await DatabaseHelper.instance.getUser();
    final storedToken = await _storage.read(key: 'jwt_token');

    if (storedUser != null && storedToken != null) {
      _token = storedToken;
      _user = User.fromJson(storedUser);
      notifyListeners();
    }
  }

  Future<void> fetchSettings() async {
    // For now, using a mock settings structure until backend is ready
    _settings = {
      'system': {'offline_mode': true},
      'notifications': {'due_date_reminders': true},
      'rules': {
        'max_books_per_user': 3,
        'issue_period_days': 14,
        'renewal_limits': 1,
        'grace_period_days': 2,
        'lost_book_policy': 'Fine 2x book price',
      },
      'fines': {
        'rate_per_day': 5,
        'max_fine_limit': 500,
        'payment_modes': ['Cash', 'UPI', 'Library Card'],
      },
      'library': {
        'name': 'GCEDPI Library',
        'working_hours': '9:00 AM - 5:00 PM',
        'contact_email': 'library@gcedpi.edu',
        'contact_phone': '+91-1234567890',
        'address': 'GCEDPI Campus, Block A',
      },
    };
    notifyListeners();
  }

  Future<void> syncData() async {
    // This is called by SettingsScreen
    if (_token != null) {
      // In a real app, we'd pass providers here
      // For this implementation, we'll keep it simple
      print('DEBUG: UserProvider triggering manual sync');
    }
  }

  // Import helper (conceptual for this script)
  dynamic importSyncService() {
    // In actual code, usually providers don't import services that import them
    // but here we just need to know it's being handled
  }

  Map<String, dynamic> _sanitizeUser(Map<String, dynamic> userData) {
    final sanitized = Map<String, dynamic>.from(userData);
    if (sanitized['_id'] != null) {
      sanitized['id'] = sanitized['_id'].toString();
    }

    final allowedKeys = {
      'id',
      'name',
      'email',
      'student_id',
      'department',
      'year',
      'phone',
      'purpose',
      'is_guest',
    };

    sanitized.removeWhere((key, value) => !allowedKeys.contains(key));
    sanitized['is_guest'] =
        (sanitized['is_guest'] == true || sanitized['is_guest'] == 1) ? 1 : 0;

    return sanitized;
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _apiService.studentLogin(email, password);
      if (result != null && result['success'] == true) {
        _token = result['token'];

        // Add fake last_login for UI if missing from API
        final userData = Map<String, dynamic>.from(result['user']);
        if (userData['last_login'] == null) {
          userData['last_login'] = DateTime.now().toIso8601String();
        }

        _user = User.fromJson(userData);

        await _storage.write(key: 'jwt_token', value: _token);

        if (!kIsWeb) {
          try {
            final dbUser = _sanitizeUser(userData);
            await DatabaseHelper.instance.saveInitialData(
              user: dbUser,
              token: _token!,
              transactions: result['transactions'] != null
                  ? List<Map<String, dynamic>>.from(result['transactions'])
                  : null,
              notifications: result['notifications'] != null
                  ? List<Map<String, dynamic>>.from(result['notifications'])
                  : null,
              books: result['books'] != null
                  ? List<Map<String, dynamic>>.from(result['books'])
                  : null,
              reservations: result['reservations'] != null
                  ? List<Map<String, dynamic>>.from(result['reservations'])
                  : null,
            );
          } catch (dbError) {
            print(
              'DEBUG: Database save initial data error (non-fatal): $dbError',
            );
          }
        }
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      print('Login error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<String?> register(Map<String, dynamic> userData) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _apiService.register(userData);
      if (result != null && result['success'] == true) {
        _token = result['token'];
        _user = User.fromJson(result['user']);

        // Save token to secure storage
        await _storage.write(key: 'jwt_token', value: _token);

        if (!kIsWeb) {
          try {
            final dbUser = _sanitizeUser(result['user']);
            await DatabaseHelper.instance.saveInitialData(
              user: dbUser,
              token: _token!,
              transactions: [],
              notifications: [],
              books: result['books'] != null
                  ? List<Map<String, dynamic>>.from(result['books'])
                  : null,
            );
          } catch (dbError) {
            print(
              'DEBUG: Database save initial data error (non-fatal): $dbError',
            );
          }
        }

        _isLoading = false;
        notifyListeners();
        return null; // Success
      } else if (result != null && result['error'] != null) {
        _isLoading = false;
        notifyListeners();
        return result['error'].toString();
      }
    } catch (e) {
      print('Registration error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return 'Registration failed.';
  }

  Future<bool> guestRegister(String name, String email, String purpose) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _apiService.guestRegister(name, email, purpose);
      if (result != null && result['success'] == true) {
        _token = result['token'];
        _user = User.fromJson(result['user']);

        // Save token to secure storage
        await _storage.write(key: 'jwt_token', value: _token);

        if (!kIsWeb) {
          try {
            final dbUser = _sanitizeUser(result['user']);
            await DatabaseHelper.instance.saveInitialData(
              user: dbUser,
              token: _token!,
              transactions: [],
              notifications: [],
              books: result['books'] != null
                  ? List<Map<String, dynamic>>.from(result['books'])
                  : null,
            );
          } catch (dbError) {
            print(
              'DEBUG: Database save initial data error (non-fatal): $dbError',
            );
          }
        }

        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      print('Guest registration error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<Map<String, dynamic>?> forgotPassword(String email) async {
    _isLoading = true;
    notifyListeners();
    try {
      final result = await _apiService.forgotPassword(email);
      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      print('Forgot password error: $e');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<Map<String, dynamic>?> resetPassword(
    String email,
    String otp,
    String newPassword,
  ) async {
    _isLoading = true;
    notifyListeners();
    try {
      final result = await _apiService.resetPassword(email, otp, newPassword);
      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      print('Reset password error: $e');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<Map<String, dynamic>?> verifyOtp(String email, String otp) async {
    _isLoading = true;
    notifyListeners();
    try {
      final result = await _apiService.verifyOtp(email, otp);
      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      print('Verify OTP error: $e');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  void logout() async {
    _user = null;
    _token = null;
    await _storage.delete(key: 'jwt_token');
    if (!kIsWeb) {
      await DatabaseHelper.instance.clearUser();
    }
    notifyListeners();
  }
}

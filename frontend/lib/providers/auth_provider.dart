import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  final ApiService _apiService;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  bool get isTrainer => _user?.role.trim().toLowerCase() == 'trainer';

  AuthProvider(this._apiService);

  Future<bool> login(String email, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _apiService.post(
        '/auth/login.php',
        data: {
          'email': email,
          'password': password,
        },
      );

      print('DEBUG: Login response status: ${response.statusCode}');
      print('DEBUG: Raw response data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        print('DEBUG: Parsed login data: $data');
        print('DEBUG: User data from response: ${data['user']}');

        if (data['user'] != null) {
          _user = User.fromJson(data['user']);
          print('DEBUG: Created user object: ${_user?.toJson()}');
          print('DEBUG: User role after creation: ${_user?.role}');
          print(
              'DEBUG: Is trainer check: ${_user?.role.trim().toLowerCase() == 'trainer'}');
          notifyListeners();
          return true;
        }
      }

      _error = 'Invalid credentials';
      notifyListeners();
      return false;
    } catch (e) {
      print('DEBUG: Login error: $e');
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signup(
      String username, String email, String password, String role) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.signup(username, email, password, role);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      print('Signup error: $_error');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _apiService.logout();
      _user = null;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

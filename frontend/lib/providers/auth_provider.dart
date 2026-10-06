import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

export '../models/user.dart' show User, UserRole;

/// Authentication state for the application.
///
/// Wraps the existing [AuthService] static methods and exposes
/// reactive state via [ChangeNotifier] so the widget tree (and
/// the go_router redirect guard) can listen for auth changes.
///
class AuthProvider extends ChangeNotifier {
  static final ChangeNotifier navigationChanges = ChangeNotifier();

  bool _isAuthenticated = false;
  bool _isInitialising = true;
  UserRole _role = UserRole.unknown;
  User? _user;

  AuthProvider() {
    AuthService.onUnauthorized = _handleUnauthorized;
  }

  // ── Public getters ──────────────────────────────────────────
  /// Whether a valid auth token is present in SharedPreferences.
  bool get isAuthenticated => _isAuthenticated;

  /// True while the initial token check is running (before [initialise]
  /// completes). Use this to show a splash / loading state.
  bool get isInitialising => _isInitialising;

  /// The authenticated account's role.
  UserRole get role => _role;
  User? get user => _user;

  bool get isCustomer => _role.isCustomer;
  bool get isStaff => _role.isStaff;
  bool get isAdmin => _role.isAdmin;

  Future<void> initialise() async {
    _isInitialising = true;
    _notify();
    try {
      _isAuthenticated = await AuthService.isAuthenticated();
      if (_isAuthenticated) {
        _user = await AuthService.getCachedUser();
        _role = _user?.role ??
            UserRole.fromString(await AuthService.getCachedRole());
        if (_role == UserRole.unknown) {
          await AuthService.clearLocalSession();
          _isAuthenticated = false;
          _user = null;
        }
      } else {
        _role = UserRole.unknown;
        _user = null;
      }
    } finally {
      _isInitialising = false;
      _notify();
    }
  }

  void notifyAuthenticated([User? user]) {
    _isAuthenticated = true;
    _user = user;
    _role = user?.role ?? UserRole.unknown;
    _notify();
  }

  Future<void> logout() async {
    await AuthService.logout();
    _isAuthenticated = false;
    _role = UserRole.unknown;
    _user = null;
    _notify();
  }

  Future<void> refresh() async {
    _isAuthenticated = await AuthService.isAuthenticated();
    if (_isAuthenticated) {
      _user = await AuthService.getCachedUser();
      _role = _user?.role ??
          UserRole.fromString(await AuthService.getCachedRole());
    } else {
      _role = UserRole.unknown;
      _user = null;
    }
    _notify();
  }

  void _handleUnauthorized() {
    _isAuthenticated = false;
    _role = UserRole.unknown;
    _user = null;
    _notify();
  }

  void _notify() {
    notifyListeners();
    navigationChanges.notifyListeners();
  }

  @override
  void dispose() {
    if (AuthService.onUnauthorized == _handleUnauthorized) {
      AuthService.onUnauthorized = null;
    }
    super.dispose();
  }
}

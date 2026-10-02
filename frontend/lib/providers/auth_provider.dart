import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

/// Authentication state for the application.
///
/// Wraps the existing [AuthService] static methods and exposes
/// reactive state via [ChangeNotifier] so the widget tree (and
/// the go_router redirect guard) can listen for auth changes.
///
/// ⚠️  STATUS: DEFINED BUT NOT YET WIRED INTO main.dart
///
/// TO ACTIVATE in Step 2:
///   1. Wrap [MyApp] with [MultiProvider] in main.dart:
///
///      runApp(
///        MultiProvider(
///          providers: [
///            ChangeNotifierProvider(create: (_) => AuthProvider()..initialise()),
///          ],
///          child: const MyApp(),
///        ),
///      );
///
///   2. Switch [MyApp] to [MaterialApp.router] with [AppRouter.router].
///   3. Add the redirect guard in [AppRouter] using
///      `context.read<AuthProvider>().isAuthenticated`.
///   4. Replace [AuthService] calls in screens with [AuthProvider] where
///      it makes sense (login screen can still call [AuthService.login]
///      directly and then call [AuthProvider.notifyAuthenticated]).
///
/// The existing screens call [AuthService] static methods directly.
/// Those calls continue to work unchanged. [AuthProvider] is an
/// additive layer — it does NOT remove or duplicate any API logic.
class AuthProvider extends ChangeNotifier {
  // ── State ───────────────────────────────────────────────────
  bool _isAuthenticated = false;
  bool _isInitialising = true;

  // ── Public getters ──────────────────────────────────────────
  /// Whether a valid auth token is present in SharedPreferences.
  bool get isAuthenticated => _isAuthenticated;

  /// True while the initial token check is running (before [initialise]
  /// completes). Use this to show a splash / loading state.
  bool get isInitialising => _isInitialising;

  // ── Initialisation ──────────────────────────────────────────

  /// Read the persisted token and update [isAuthenticated].
  ///
  /// Call once at app startup (from the [MultiProvider] create callback
  /// or from [SplashScreen.initState]).
  Future<void> initialise() async {
    _isInitialising = true;
    notifyListeners();

    _isAuthenticated = await AuthService.isAuthenticated();

    _isInitialising = false;
    notifyListeners();
  }

  // ── Auth actions ────────────────────────────────────────────

  /// Call after a successful [AuthService.login] to update reactive state.
  ///
  /// The actual API call stays in [AuthService] — this provider only
  /// tracks the resulting state change.
  void notifyAuthenticated() {
    _isAuthenticated = true;
    notifyListeners();
  }

  /// Calls [AuthService.logout] (clears the token) then resets state.
  Future<void> logout() async {
    await AuthService.logout();
    _isAuthenticated = false;
    notifyListeners();
  }

  /// Refreshes the auth state from storage — useful after a deep-link
  /// or when the token may have been revoked externally.
  Future<void> refresh() async {
    _isAuthenticated = await AuthService.isAuthenticated();
    notifyListeners();
  }
}

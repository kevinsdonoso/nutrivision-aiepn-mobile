// ╔═══════════════════════════════════════════════════════════════════════════════╗
// ║                          session_manager.dart                                 ║
// ║                    Gestión de sesión y onboarding                             ║
// ╠═══════════════════════════════════════════════════════════════════════════════╣
// ║  Gestiona el estado de la sesión usando SharedPreferences.                    ║
// ║  Controla si el onboarding fue completado y preferencias locales.             ║
// ╚═══════════════════════════════════════════════════════════════════════════════╝

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Claves para SharedPreferences.
class SessionKeys {
  static const String onboardingSeen = 'onboarding_seen';
  static const String lastUserId = 'last_user_id';
  static const String themeMode = 'theme_mode';
  static const String languageCode = 'language_code';

  SessionKeys._();
}

/// Servicio de gestión de sesión local.
///
/// Gestiona datos persistentes locales:
/// - Estado del onboarding
/// - Último usuario logueado
/// - Preferencias de tema e idioma
///
/// Ejemplo de uso:
/// ```dart
/// final sessionManager = SessionManager();
/// await sessionManager.init();
/// final seenOnboarding = sessionManager.hasSeenOnboarding;
/// ```
class SessionManager {
  SharedPreferences? _prefs;

  /// Indica si el SessionManager fue inicializado.
  bool get isInitialized => _prefs != null;

  /// Inicializa SharedPreferences.
  ///
  /// Debe llamarse antes de usar otros métodos.
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Asegura que esté inicializado antes de usar.
  void _ensureInitialized() {
    if (_prefs == null) {
      throw StateError(
        'SessionManager no inicializado. Llama init() primero.',
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ONBOARDING
  // ═══════════════════════════════════════════════════════════════════════════

  /// Indica si el usuario ya vio el onboarding.
  bool get hasSeenOnboarding {
    _ensureInitialized();
    return _prefs!.getBool(SessionKeys.onboardingSeen) ?? false;
  }

  /// Marca el onboarding como visto.
  Future<void> markOnboardingSeen() async {
    _ensureInitialized();
    await _prefs!.setBool(SessionKeys.onboardingSeen, true);
  }

  /// Resetea el estado del onboarding (para testing/debugging).
  Future<void> resetOnboarding() async {
    _ensureInitialized();
    await _prefs!.remove(SessionKeys.onboardingSeen);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ÚLTIMO USUARIO
  // ═══════════════════════════════════════════════════════════════════════════

  /// ID del último usuario que inició sesión.
  String? get lastUserId {
    _ensureInitialized();
    return _prefs!.getString(SessionKeys.lastUserId);
  }

  /// Guarda el ID del usuario actual.
  Future<void> setLastUserId(String userId) async {
    _ensureInitialized();
    await _prefs!.setString(SessionKeys.lastUserId, userId);
  }

  /// Limpia el ID del último usuario (al hacer logout).
  Future<void> clearLastUserId() async {
    _ensureInitialized();
    await _prefs!.remove(SessionKeys.lastUserId);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PREFERENCIAS DE TEMA
  // ═══════════════════════════════════════════════════════════════════════════

  /// Modo de tema guardado ('light', 'dark', 'system').
  String get themeMode {
    _ensureInitialized();
    return _prefs!.getString(SessionKeys.themeMode) ?? 'system';
  }

  /// Guarda el modo de tema.
  Future<void> setThemeMode(String mode) async {
    _ensureInitialized();
    await _prefs!.setString(SessionKeys.themeMode, mode);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PREFERENCIAS DE IDIOMA
  // ═══════════════════════════════════════════════════════════════════════════

  /// Código de idioma guardado.
  String? get languageCode {
    _ensureInitialized();
    return _prefs!.getString(SessionKeys.languageCode);
  }

  /// Guarda el código de idioma.
  Future<void> setLanguageCode(String code) async {
    _ensureInitialized();
    await _prefs!.setString(SessionKeys.languageCode, code);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UTILIDADES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Limpia todos los datos de sesión (para logout completo).
  Future<void> clearAll() async {
    _ensureInitialized();
    await _prefs!.clear();
  }

  /// Limpia datos de sesión pero mantiene preferencias.
  Future<void> clearSession() async {
    _ensureInitialized();
    await _prefs!.remove(SessionKeys.lastUserId);
    // Mantiene: onboardingSeen, themeMode, languageCode
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════════

/// Provider del SessionManager.
///
/// Se inicializa de forma asíncrona, por lo que debe usarse
/// con FutureProvider o inicializarse en main().
final sessionManagerProvider = Provider<SessionManager>((ref) {
  return SessionManager();
});

/// Provider para inicializar el SessionManager.
///
/// Uso en main():
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   final container = ProviderContainer();
///   await container.read(initSessionManagerProvider.future);
///   runApp(UncontrolledProviderScope(
///     container: container,
///     child: const MyApp(),
///   ));
/// }
/// ```
final initSessionManagerProvider = FutureProvider<void>((ref) async {
  final sessionManager = ref.read(sessionManagerProvider);
  await sessionManager.init();
});

/// Provider que indica si el usuario vio el onboarding.
final hasSeenOnboardingProvider = Provider<bool>((ref) {
  final sessionManager = ref.watch(sessionManagerProvider);
  try {
    return sessionManager.hasSeenOnboarding;
  } catch (_) {
    return false;
  }
});

/// Provider del modo de tema actual.
final themeModeProvider = StateProvider<String>((ref) {
  final sessionManager = ref.watch(sessionManagerProvider);
  try {
    return sessionManager.themeMode;
  } catch (_) {
    return 'system';
  }
});

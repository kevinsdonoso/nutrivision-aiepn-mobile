// ╔═══════════════════════════════════════════════════════════════════════════════╗
// ║                           auth_provider.dart                                  ║
// ║                   Providers de autenticación con Riverpod                     ║
// ╠═══════════════════════════════════════════════════════════════════════════════╣
// ║  Providers para gestionar el estado de autenticación de forma reactiva.       ║
// ║  Incluye: authStateProvider, currentUserProvider, authNotifier.               ║
// ╚═══════════════════════════════════════════════════════════════════════════════╝

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/auth_state.dart';
import '../../../data/models/user_profile.dart';
import '../repositories/auth_repository.dart';
import '../services/firebase_auth_service.dart';
import '../services/firestore_user_service.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// PROVIDERS DE SERVICIOS
// ═══════════════════════════════════════════════════════════════════════════════

/// Provider del servicio de autenticación Firebase.
final firebaseAuthServiceProvider = Provider<FirebaseAuthService>((ref) {
  return FirebaseAuthService();
});

/// Provider del servicio de usuarios Firestore.
final firestoreUserServiceProvider = Provider<FirestoreUserService>((ref) {
  return FirestoreUserService();
});

/// Provider del repositorio de autenticación.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    authService: ref.watch(firebaseAuthServiceProvider),
    userService: ref.watch(firestoreUserServiceProvider),
  );
});

// ═══════════════════════════════════════════════════════════════════════════════
// PROVIDER DE ESTADO DE AUTENTICACIÓN
// ═══════════════════════════════════════════════════════════════════════════════

/// Provider del estado de autenticación.
///
/// Gestiona el ciclo completo de autenticación:
/// - Verifica sesión al iniciar
/// - Actualiza estado en login/logout
/// - Proporciona el perfil del usuario
///
/// Uso:
/// ```dart
/// final authState = ref.watch(authStateProvider);
/// switch (authState) {
///   case AuthStateAuthenticated(:final profile):
///     return HomeScreen(profile: profile);
///   case AuthStateUnauthenticated():
///     return WelcomeScreen();
///   // ...
/// }
/// ```
final authStateProvider =
    StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  return AuthStateNotifier(ref.watch(authRepositoryProvider));
});

/// Notifier que gestiona el estado de autenticación.
class AuthStateNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  StreamSubscription? _authSubscription;

  AuthStateNotifier(this._repository) : super(const AuthStateInitial()) {
    _init();
  }

  /// Inicializa el listener de cambios de autenticación.
  void _init() {
    _authSubscription = _repository.authStateChanges.listen((user) async {
      if (user == null) {
        // Usuario no autenticado
        if (state is AuthStateAuthenticated) {
          state = const AuthStateUnauthenticated(wasSignedOut: true);
        } else {
          state = const AuthStateUnauthenticated();
        }
      } else {
        // Usuario autenticado, cargar perfil
        await _loadUserProfile();
      }
    });
  }

  /// Carga el perfil del usuario actual.
  Future<void> _loadUserProfile() async {
    state = const AuthStateLoading(message: 'Cargando perfil...');

    try {
      final profile = await _repository.getCurrentUserProfile();
      if (profile != null) {
        state = AuthStateAuthenticated(profile: profile);
      } else {
        // Usuario autenticado pero sin perfil (caso raro)
        state = const AuthStateUnauthenticated();
      }
    } catch (e) {
      state = AuthStateError(
        message: 'Error al cargar perfil',
        exception: e,
      );
    }
  }

  /// Registra un nuevo usuario.
  Future<AuthResult<UserProfile>> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    state = const AuthStateLoading(message: 'Creando cuenta...');

    final result = await _repository.signUp(
      email: email,
      password: password,
      displayName: displayName,
    );

    result.when(
      success: (profile) {
        state = AuthStateAuthenticated(profile: profile);
      },
      failure: (message, code) {
        state = AuthStateError(message: message, code: code);
      },
    );

    return result;
  }

  /// Inicia sesión.
  Future<AuthResult<UserProfile>> signIn({
    required String email,
    required String password,
  }) async {
    state = const AuthStateLoading(message: 'Iniciando sesión...');

    final result = await _repository.signIn(
      email: email,
      password: password,
    );

    result.when(
      success: (profile) {
        state = AuthStateAuthenticated(profile: profile);
      },
      failure: (message, code) {
        state = AuthStateError(message: message, code: code);
      },
    );

    return result;
  }

  /// Cierra sesión.
  Future<void> signOut() async {
    state = const AuthStateLoading(message: 'Cerrando sesión...');

    final result = await _repository.signOut();

    result.when(
      success: (_) {
        state = const AuthStateUnauthenticated(wasSignedOut: true);
      },
      failure: (message, code) {
        state = AuthStateError(message: message, code: code);
      },
    );
  }

  /// Envía email para restablecer contraseña.
  Future<AuthResult<void>> sendPasswordResetEmail({
    required String email,
  }) async {
    return _repository.sendPasswordResetEmail(email: email);
  }

  /// Actualiza el perfil del usuario.
  Future<AuthResult<UserProfile>> updateProfile(UserProfile profile) async {
    final result = await _repository.updateProfile(profile);

    result.when(
      success: (updatedProfile) {
        state = AuthStateAuthenticated(profile: updatedProfile);
      },
      failure: (_, __) {
        // No cambiar el estado en caso de error
      },
    );

    return result;
  }

  /// Marca el onboarding como completado.
  Future<AuthResult<void>> completeOnboarding() async {
    final result = await _repository.completeOnboarding();

    if (result.isSuccess && state is AuthStateAuthenticated) {
      final currentProfile = (state as AuthStateAuthenticated).profile;
      state = AuthStateAuthenticated(
        profile: currentProfile.copyWith(onboardingCompleted: true),
      );
    }

    return result;
  }

  /// Recarga el perfil del usuario.
  Future<void> refreshProfile() async {
    if (state is AuthStateAuthenticated) {
      await _loadUserProfile();
    }
  }

  /// Limpia el estado de error.
  void clearError() {
    if (state is AuthStateError) {
      if (_repository.isAuthenticated) {
        _loadUserProfile();
      } else {
        state = const AuthStateUnauthenticated();
      }
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PROVIDERS DERIVADOS
// ═══════════════════════════════════════════════════════════════════════════════

/// Provider del perfil del usuario actual.
///
/// Retorna null si no está autenticado.
final currentUserProfileProvider = Provider<UserProfile?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.profile;
});

/// Provider que indica si el usuario está autenticado.
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.isAuthenticated;
});

/// Provider que indica si está cargando (autenticación en progreso).
final isAuthLoadingProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.isLoading;
});

/// Provider que indica si el usuario necesita completar onboarding.
final needsOnboardingProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  if (authState is AuthStateAuthenticated) {
    return authState.needsProfileSetup;
  }
  return false;
});

/// Provider del stream del perfil actual (actualizaciones en tiempo real).
final userProfileStreamProvider = StreamProvider<UserProfile?>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  if (!repository.isAuthenticated) {
    return Stream.value(null);
  }
  return repository.watchCurrentUserProfile();
});

// ═══════════════════════════════════════════════════════════════════════════════
// PROVIDER DE ACCIONES DE PERFIL
// ═══════════════════════════════════════════════════════════════════════════════

/// Provider para actualizar datos nutricionales.
final updateNutritionDataProvider = Provider((ref) {
  final repository = ref.watch(authRepositoryProvider);
  final authNotifier = ref.watch(authStateProvider.notifier);

  return ({
    double? weightKg,
    double? heightCm,
    ActivityLevel? activityLevel,
    NutritionGoal? nutritionGoal,
    int? dailyCalorieTarget,
  }) async {
    final result = await repository.updateNutritionData(
      weightKg: weightKg,
      heightCm: heightCm,
      activityLevel: activityLevel,
      nutritionGoal: nutritionGoal,
      dailyCalorieTarget: dailyCalorieTarget,
    );

    if (result.isSuccess) {
      await authNotifier.refreshProfile();
    }

    return result;
  };
});

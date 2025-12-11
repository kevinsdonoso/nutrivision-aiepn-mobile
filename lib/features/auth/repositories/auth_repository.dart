// ╔═══════════════════════════════════════════════════════════════════════════════╗
// ║                          auth_repository.dart                                 ║
// ║                  Repositorio de autenticación y perfil                        ║
// ╠═══════════════════════════════════════════════════════════════════════════════╣
// ║  Combina FirebaseAuthService y FirestoreUserService para gestionar            ║
// ║  el ciclo completo de autenticación y datos de usuario.                       ║
// ╚═══════════════════════════════════════════════════════════════════════════════╝

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/exceptions/app_exceptions.dart';
import '../../../data/models/auth_state.dart';
import '../../../data/models/user_profile.dart';
import '../services/firebase_auth_service.dart';
import '../services/firestore_user_service.dart';

/// Repositorio que orquesta la autenticación y gestión de perfiles.
///
/// Proporciona una API unificada para:
/// - Registro (crea cuenta + perfil en Firestore)
/// - Login (autentica + carga perfil)
/// - Logout
/// - Gestión del perfil de usuario
///
/// Ejemplo de uso:
/// ```dart
/// final authRepo = AuthRepository();
/// final result = await authRepo.signUp(
///   email: 'user@example.com',
///   password: 'password123',
///   displayName: 'Juan Pérez',
/// );
/// result.when(
///   success: (profile) => print('Bienvenido ${profile.displayName}'),
///   failure: (msg, code) => print('Error: $msg'),
/// );
/// ```
class AuthRepository {
  /// Servicio de autenticación Firebase
  final FirebaseAuthService _authService;

  /// Servicio de usuarios Firestore
  final FirestoreUserService _userService;

  /// Constructor con inyección de dependencias.
  AuthRepository({
    FirebaseAuthService? authService,
    FirestoreUserService? userService,
  })  : _authService = authService ?? FirebaseAuthService(),
        _userService = userService ?? FirestoreUserService();

  // ═══════════════════════════════════════════════════════════════════════════
  // PROPIEDADES
  // ═══════════════════════════════════════════════════════════════════════════

  /// ID del usuario actual (null si no autenticado).
  String? get currentUserId => _authService.currentUserId;

  /// Indica si hay un usuario autenticado.
  bool get isAuthenticated => _authService.isAuthenticated;

  /// Stream de cambios en el estado de autenticación.
  Stream<User?> get authStateChanges => _authService.authStateChanges;

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS DE AUTENTICACIÓN
  // ═══════════════════════════════════════════════════════════════════════════

  /// Registra un nuevo usuario y crea su perfil.
  ///
  /// [email] Email del usuario
  /// [password] Contraseña (mínimo 6 caracteres)
  /// [displayName] Nombre para mostrar
  ///
  /// Returns: [AuthResult] con el perfil creado o error
  Future<AuthResult<UserProfile>> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      // 1. Crear cuenta en Firebase Auth
      final user = await _authService.signUpWithEmailAndPassword(
        email: email,
        password: password,
        displayName: displayName,
      );

      // 2. Crear perfil en Firestore
      final profile = UserProfile.newUser(
        id: user.uid,
        email: user.email ?? email,
        displayName: displayName,
      );

      final savedProfile = await _userService.createUserProfile(profile);

      return AuthSuccess(savedProfile);
    } on NutriVisionException catch (e) {
      return AuthFailure(message: e.userMessage, code: e.code);
    } catch (e) {
      return AuthFailure(message: 'Error durante el registro: ${e.toString()}');
    }
  }

  /// Inicia sesión y carga el perfil del usuario.
  ///
  /// [email] Email del usuario
  /// [password] Contraseña
  ///
  /// Returns: [AuthResult] con el perfil o error
  Future<AuthResult<UserProfile>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // 1. Autenticar con Firebase
      final user = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Cargar perfil de Firestore
      var profile = await _userService.getUserProfile(user.uid);

      // 3. Si no existe perfil, crear uno básico
      if (profile == null) {
        profile = UserProfile.newUser(
          id: user.uid,
          email: user.email ?? email,
          displayName: user.displayName ?? email.split('@')[0],
        );
        await _userService.createUserProfile(profile);
      }

      return AuthSuccess(profile);
    } on NutriVisionException catch (e) {
      return AuthFailure(message: e.userMessage, code: e.code);
    } catch (e) {
      return AuthFailure(
        message: 'Error al iniciar sesión: ${e.toString()}',
      );
    }
  }

  /// Cierra la sesión del usuario actual.
  ///
  /// Returns: [AuthResult] indicando éxito o error
  Future<AuthResult<void>> signOut() async {
    try {
      await _authService.signOut();
      return const AuthSuccess(null);
    } on NutriVisionException catch (e) {
      return AuthFailure(message: e.userMessage, code: e.code);
    } catch (e) {
      return AuthFailure(message: 'Error al cerrar sesión: ${e.toString()}');
    }
  }

  /// Envía email para restablecer contraseña.
  ///
  /// [email] Email de la cuenta
  ///
  /// Returns: [AuthResult] indicando éxito o error
  Future<AuthResult<void>> sendPasswordResetEmail({
    required String email,
  }) async {
    try {
      await _authService.sendPasswordResetEmail(email: email);
      return const AuthSuccess(null);
    } on NutriVisionException catch (e) {
      return AuthFailure(message: e.userMessage, code: e.code);
    } catch (e) {
      return AuthFailure(
        message: 'Error al enviar email: ${e.toString()}',
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS DE PERFIL
  // ═══════════════════════════════════════════════════════════════════════════

  /// Obtiene el perfil del usuario actual.
  ///
  /// Returns: Perfil o null si no está autenticado
  Future<UserProfile?> getCurrentUserProfile() async {
    final userId = currentUserId;
    if (userId == null) return null;

    return _userService.getUserProfile(userId);
  }

  /// Stream del perfil del usuario actual.
  ///
  /// Emite actualizaciones en tiempo real del perfil.
  Stream<UserProfile?> watchCurrentUserProfile() {
    final userId = currentUserId;
    if (userId == null) {
      return Stream.value(null);
    }
    return _userService.watchUserProfile(userId);
  }

  /// Actualiza el perfil del usuario actual.
  ///
  /// [profile] Perfil con los nuevos datos
  ///
  /// Returns: [AuthResult] con el perfil actualizado o error
  Future<AuthResult<UserProfile>> updateProfile(UserProfile profile) async {
    try {
      final updatedProfile = await _userService.updateUserProfile(profile);

      // Actualizar también en Firebase Auth si cambia el nombre
      if (profile.displayName != _authService.currentUser?.displayName) {
        await _authService.updateProfile(displayName: profile.displayName);
      }

      return AuthSuccess(updatedProfile);
    } on NutriVisionException catch (e) {
      return AuthFailure(message: e.userMessage, code: e.code);
    } catch (e) {
      return AuthFailure(
        message: 'Error al actualizar perfil: ${e.toString()}',
      );
    }
  }

  /// Actualiza la foto de perfil.
  ///
  /// [photoUrl] URL de la nueva foto
  ///
  /// Returns: [AuthResult] indicando éxito o error
  Future<AuthResult<void>> updateProfilePhoto(String photoUrl) async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        return const AuthFailure(
          message: 'No hay usuario autenticado',
          code: 'NO_USER',
        );
      }

      await _userService.updatePhotoUrl(userId, photoUrl);
      await _authService.updateProfile(photoURL: photoUrl);

      return const AuthSuccess(null);
    } on NutriVisionException catch (e) {
      return AuthFailure(message: e.userMessage, code: e.code);
    } catch (e) {
      return AuthFailure(
        message: 'Error al actualizar foto: ${e.toString()}',
      );
    }
  }

  /// Marca el onboarding como completado.
  ///
  /// Returns: [AuthResult] indicando éxito o error
  Future<AuthResult<void>> completeOnboarding() async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        return const AuthFailure(
          message: 'No hay usuario autenticado',
          code: 'NO_USER',
        );
      }

      await _userService.completeOnboarding(userId);
      return const AuthSuccess(null);
    } on NutriVisionException catch (e) {
      return AuthFailure(message: e.userMessage, code: e.code);
    } catch (e) {
      return AuthFailure(
        message: 'Error al completar onboarding: ${e.toString()}',
      );
    }
  }

  /// Actualiza los datos nutricionales del perfil.
  Future<AuthResult<void>> updateNutritionData({
    double? weightKg,
    double? heightCm,
    ActivityLevel? activityLevel,
    NutritionGoal? nutritionGoal,
    int? dailyCalorieTarget,
  }) async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        return const AuthFailure(
          message: 'No hay usuario autenticado',
          code: 'NO_USER',
        );
      }

      await _userService.updateNutritionData(
        userId,
        weightKg: weightKg,
        heightCm: heightCm,
        activityLevel: activityLevel,
        nutritionGoal: nutritionGoal,
        dailyCalorieTarget: dailyCalorieTarget,
      );

      return const AuthSuccess(null);
    } on NutriVisionException catch (e) {
      return AuthFailure(message: e.userMessage, code: e.code);
    } catch (e) {
      return AuthFailure(
        message: 'Error al actualizar datos: ${e.toString()}',
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS DE CUENTA
  // ═══════════════════════════════════════════════════════════════════════════

  /// Elimina la cuenta del usuario actual.
  ///
  /// ADVERTENCIA: Elimina tanto la cuenta de Firebase Auth como el perfil
  /// en Firestore. Esta acción es irreversible.
  ///
  /// [password] Contraseña actual para confirmar
  ///
  /// Returns: [AuthResult] indicando éxito o error
  Future<AuthResult<void>> deleteAccount({required String password}) async {
    try {
      final userId = currentUserId;
      final email = _authService.currentUserEmail;

      if (userId == null || email == null) {
        return const AuthFailure(
          message: 'No hay usuario autenticado',
          code: 'NO_USER',
        );
      }

      // 1. Re-autenticar para confirmar
      await _authService.reauthenticateWithPassword(
        email: email,
        password: password,
      );

      // 2. Eliminar perfil de Firestore
      await _userService.deleteUserProfile(userId);

      // 3. Eliminar cuenta de Firebase Auth
      await _authService.deleteAccount();

      return const AuthSuccess(null);
    } on NutriVisionException catch (e) {
      return AuthFailure(message: e.userMessage, code: e.code);
    } catch (e) {
      return AuthFailure(
        message: 'Error al eliminar cuenta: ${e.toString()}',
      );
    }
  }

  /// Cambia la contraseña del usuario actual.
  ///
  /// [currentPassword] Contraseña actual
  /// [newPassword] Nueva contraseña
  ///
  /// Returns: [AuthResult] indicando éxito o error
  Future<AuthResult<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final email = _authService.currentUserEmail;
      if (email == null) {
        return const AuthFailure(
          message: 'No hay usuario autenticado',
          code: 'NO_USER',
        );
      }

      // Re-autenticar primero
      await _authService.reauthenticateWithPassword(
        email: email,
        password: currentPassword,
      );

      // Cambiar contraseña
      await _authService.updatePassword(newPassword: newPassword);

      return const AuthSuccess(null);
    } on NutriVisionException catch (e) {
      return AuthFailure(message: e.userMessage, code: e.code);
    } catch (e) {
      return AuthFailure(
        message: 'Error al cambiar contraseña: ${e.toString()}',
      );
    }
  }
}

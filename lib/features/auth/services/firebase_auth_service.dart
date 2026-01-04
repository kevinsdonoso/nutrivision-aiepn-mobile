// ╔═══════════════════════════════════════════════════════════════════════════════╗
// ║                        firebase_auth_service.dart                             ║
// ║                   Servicio de autenticación con Firebase                      ║
// ╠═══════════════════════════════════════════════════════════════════════════════╣
// ║  Wrapper del SDK de Firebase Authentication.                                  ║
// ║  Maneja login, registro, logout y gestión de sesión.                          ║
// ║  Convierte errores de Firebase a excepciones personalizadas.                  ║
// ╚═══════════════════════════════════════════════════════════════════════════════╝

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/exceptions/app_exceptions.dart';

/// Servicio de autenticación que envuelve Firebase Auth.
///
/// Proporciona métodos para:
/// - Registro con email/password
/// - Login con email/password
/// - Logout
/// - Recuperación de contraseña
/// - Observación del estado de autenticación
///
/// Ejemplo de uso:
/// ```dart
/// final authService = FirebaseAuthService();
/// final user = await authService.signInWithEmailAndPassword(
///   email: 'user@example.com',
///   password: 'password123',
/// );
/// ```
class FirebaseAuthService {
  /// Instancia de FirebaseAuth
  final FirebaseAuth _auth;

  /// Constructor con inyección de dependencia opcional.
  FirebaseAuthService({FirebaseAuth? auth})
      : _auth = auth ?? FirebaseAuth.instance;

  // ═══════════════════════════════════════════════════════════════════════════
  // PROPIEDADES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Usuario actual de Firebase (null si no autenticado).
  User? get currentUser => _auth.currentUser;

  /// ID del usuario actual (null si no autenticado).
  String? get currentUserId => _auth.currentUser?.uid;

  /// Email del usuario actual (null si no autenticado).
  String? get currentUserEmail => _auth.currentUser?.email;

  /// Indica si hay un usuario autenticado.
  bool get isAuthenticated => _auth.currentUser != null;

  /// Stream de cambios en el estado de autenticación.
  ///
  /// Emite el usuario actual cuando:
  /// - La app se inicia (usuario previo o null)
  /// - El usuario inicia sesión
  /// - El usuario cierra sesión
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Stream de cambios en el usuario (incluye actualizaciones de perfil).
  Stream<User?> get userChanges => _auth.userChanges();

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS DE AUTENTICACIÓN
  // ═══════════════════════════════════════════════════════════════════════════

  /// Registra un nuevo usuario con email y contraseña.
  ///
  /// [email] Email del nuevo usuario
  /// [password] Contraseña (mínimo 6 caracteres)
  /// [displayName] Nombre para mostrar (opcional)
  ///
  /// Returns: Usuario de Firebase creado
  /// Throws: [AuthException] si el registro falla
  Future<User> signUpWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw const AuthException(
          message: 'No se pudo crear el usuario',
          code: 'USER_NULL',
        );
      }

      // Actualizar el displayName si se proporciona
      if (displayName != null && displayName.isNotEmpty) {
        await user.updateDisplayName(displayName.trim());
        await user.reload();
      }

      return _auth.currentUser ?? user;
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(
        message: 'Error durante el registro: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Inicia sesión con email y contraseña.
  ///
  /// [email] Email del usuario
  /// [password] Contraseña del usuario
  ///
  /// Returns: Usuario de Firebase autenticado
  /// Throws: [AuthException] si el login falla
  Future<User> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw const AuthException(
          message: 'No se pudo iniciar sesión',
          code: 'USER_NULL',
        );
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(
        message: 'Error durante el inicio de sesión: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Cierra la sesión del usuario actual.
  ///
  /// Throws: [AuthException] si el logout falla
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw AuthException(
        message: 'Error al cerrar sesión: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Envía un email para restablecer la contraseña.
  ///
  /// [email] Email de la cuenta a recuperar
  ///
  /// Throws: [AuthException] si falla el envío
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    } catch (e) {
      throw AuthException(
        message: 'Error al enviar email de recuperación: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Actualiza el perfil del usuario actual.
  ///
  /// [displayName] Nuevo nombre para mostrar (null para no cambiar)
  /// [photoURL] Nueva URL de foto (null para no cambiar)
  ///
  /// Throws: [AuthException] si la actualización falla
  Future<void> updateProfile({
    String? displayName,
    String? photoURL,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthException(
        message: 'No hay usuario autenticado',
        code: 'NO_USER',
      );
    }

    try {
      if (displayName != null) {
        await user.updateDisplayName(displayName.trim());
      }
      if (photoURL != null) {
        await user.updatePhotoURL(photoURL);
      }
      await user.reload();
    } catch (e) {
      throw AuthException(
        message: 'Error al actualizar perfil: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Actualiza el email del usuario actual.
  ///
  /// Requiere verificación previa del email.
  ///
  /// [newEmail] Nuevo email
  ///
  /// Throws: [AuthException] si la actualización falla
  Future<void> updateEmail({required String newEmail}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthException(
        message: 'No hay usuario autenticado',
        code: 'NO_USER',
      );
    }

    try {
      await user.verifyBeforeUpdateEmail(newEmail.trim());
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    } catch (e) {
      throw AuthException(
        message: 'Error al actualizar email: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Actualiza la contraseña del usuario actual.
  ///
  /// [newPassword] Nueva contraseña
  ///
  /// Throws: [AuthException] si la actualización falla
  Future<void> updatePassword({required String newPassword}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthException(
        message: 'No hay usuario autenticado',
        code: 'NO_USER',
      );
    }

    try {
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    } catch (e) {
      throw AuthException(
        message: 'Error al actualizar contraseña: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Re-autentica al usuario con sus credenciales actuales.
  ///
  /// Necesario antes de operaciones sensibles como cambiar email/contraseña.
  ///
  /// [email] Email actual
  /// [password] Contraseña actual
  ///
  /// Throws: [AuthException] si la re-autenticación falla
  Future<void> reauthenticateWithPassword({
    required String email,
    required String password,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthException(
        message: 'No hay usuario autenticado',
        code: 'NO_USER',
      );
    }

    try {
      final credential = EmailAuthProvider.credential(
        email: email.trim(),
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    } catch (e) {
      throw AuthException(
        message: 'Error al re-autenticar: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Elimina la cuenta del usuario actual.
  ///
  /// ADVERTENCIA: Esta acción es irreversible.
  ///
  /// Throws: [AuthException] si la eliminación falla
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthException(
        message: 'No hay usuario autenticado',
        code: 'NO_USER',
      );
    }

    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    } catch (e) {
      throw AuthException(
        message: 'Error al eliminar cuenta: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Envía un email de verificación al usuario actual.
  ///
  /// Throws: [AuthException] si falla el envío
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthException(
        message: 'No hay usuario autenticado',
        code: 'NO_USER',
      );
    }

    try {
      await user.sendEmailVerification();
    } catch (e) {
      throw AuthException(
        message: 'Error al enviar verificación: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Recarga los datos del usuario actual desde Firebase.
  ///
  /// Útil para verificar si el email fue verificado.
  Future<void> reloadUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.reload();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UTILIDADES PRIVADAS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Convierte excepciones de Firebase a excepciones personalizadas.
  AuthException _mapFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return AuthInvalidEmailException(originalError: e);

      case 'user-disabled':
        return AuthUserDisabledException(originalError: e);

      case 'user-not-found':
        return AuthUserNotFoundException(originalError: e);

      case 'wrong-password':
      case 'invalid-credential':
        return AuthInvalidCredentialsException(originalError: e);

      case 'email-already-in-use':
        return AuthEmailAlreadyInUseException(
          email: e.email,
          originalError: e,
        );

      case 'operation-not-allowed':
        return AuthException(
          message: 'Operación no permitida',
          code: 'AUTH_OPERATION_NOT_ALLOWED',
          originalError: e,
        );

      case 'weak-password':
        return AuthWeakPasswordException(originalError: e);

      case 'too-many-requests':
        return AuthTooManyRequestsException(originalError: e);

      case 'network-request-failed':
        return AuthNetworkException(originalError: e);

      case 'requires-recent-login':
        return AuthSessionExpiredException(originalError: e);

      default:
        return AuthException(
          message: e.message ?? 'Error de autenticación desconocido',
          code: e.code,
          originalError: e,
        );
    }
  }
}

// ╔═══════════════════════════════════════════════════════════════════════════════╗
// ║                            auth_state.dart                                    ║
// ║                    Estados de autenticación del usuario                       ║
// ╠═══════════════════════════════════════════════════════════════════════════════╣
// ║  Define los diferentes estados de autenticación posibles en la aplicación.    ║
// ║  Usado por AuthProvider para gestionar el flujo de autenticación.             ║
// ╚═══════════════════════════════════════════════════════════════════════════════╝

import 'package:flutter/foundation.dart';

import 'user_profile.dart';

/// Estado base de autenticación.
///
/// Representa los diferentes estados posibles del usuario en la app:
/// - [AuthStateInitial]: Estado inicial, aún no se ha verificado
/// - [AuthStateLoading]: Verificando o procesando autenticación
/// - [AuthStateUnauthenticated]: Usuario no autenticado
/// - [AuthStateAuthenticated]: Usuario autenticado con perfil
/// - [AuthStateError]: Error durante autenticación
///
/// Ejemplo de uso con pattern matching:
/// ```dart
/// switch (authState) {
///   case AuthStateAuthenticated(:final user, :final profile):
///     return HomeScreen(user: user, profile: profile);
///   case AuthStateUnauthenticated():
///     return WelcomeScreen();
///   case AuthStateLoading():
///     return LoadingScreen();
///   default:
///     return SplashScreen();
/// }
/// ```
@immutable
sealed class AuthState {
  const AuthState();

  /// Indica si el usuario está autenticado.
  bool get isAuthenticated => this is AuthStateAuthenticated;

  /// Indica si se está cargando/procesando.
  bool get isLoading => this is AuthStateLoading;

  /// Indica si hay un error.
  bool get hasError => this is AuthStateError;

  /// Obtiene el perfil si está autenticado.
  UserProfile? get profile {
    if (this is AuthStateAuthenticated) {
      return (this as AuthStateAuthenticated).profile;
    }
    return null;
  }
}

/// Estado inicial de autenticación.
///
/// Este es el estado cuando la app acaba de iniciar y aún no se ha
/// verificado si el usuario tiene sesión activa.
@immutable
class AuthStateInitial extends AuthState {
  const AuthStateInitial();

  @override
  String toString() => 'AuthStateInitial()';
}

/// Estado de carga durante autenticación.
///
/// Se usa durante:
/// - Verificación de sesión al iniciar la app
/// - Proceso de login
/// - Proceso de registro
/// - Actualización de perfil
@immutable
class AuthStateLoading extends AuthState {
  /// Mensaje opcional de estado (para mostrar en UI).
  final String? message;

  const AuthStateLoading({this.message});

  @override
  String toString() => 'AuthStateLoading(message: $message)';
}

/// Estado de usuario no autenticado.
///
/// Indica que no hay sesión activa y el usuario debe
/// iniciar sesión o registrarse.
@immutable
class AuthStateUnauthenticated extends AuthState {
  /// Indica si el usuario cerró sesión manualmente.
  final bool wasSignedOut;

  const AuthStateUnauthenticated({this.wasSignedOut = false});

  @override
  String toString() => 'AuthStateUnauthenticated(wasSignedOut: $wasSignedOut)';
}

/// Estado de usuario autenticado.
///
/// Contiene el perfil completo del usuario autenticado.
/// También indica si el perfil necesita completarse (onboarding).
@immutable
class AuthStateAuthenticated extends AuthState {
  /// Perfil del usuario autenticado.
  @override
  final UserProfile profile;

  /// Indica si el usuario necesita completar su perfil.
  bool get needsProfileSetup => !profile.onboardingCompleted;

  /// Indica si el perfil tiene todos los datos necesarios.
  bool get hasCompleteProfile => profile.isProfileComplete;

  const AuthStateAuthenticated({required this.profile});

  /// Crea un nuevo estado con el perfil actualizado.
  AuthStateAuthenticated copyWithProfile(UserProfile newProfile) {
    return AuthStateAuthenticated(profile: newProfile);
  }

  @override
  String toString() =>
      'AuthStateAuthenticated(profile: ${profile.email}, needsSetup: $needsProfileSetup)';
}

/// Estado de error durante autenticación.
///
/// Contiene información sobre el error ocurrido.
@immutable
class AuthStateError extends AuthState {
  /// Mensaje de error para mostrar al usuario.
  final String message;

  /// Código de error (para logging/debugging).
  final String? code;

  /// Excepción original (para debugging).
  final Object? exception;

  const AuthStateError({
    required this.message,
    this.code,
    this.exception,
  });

  @override
  String toString() => 'AuthStateError(message: $message, code: $code)';
}

// ═══════════════════════════════════════════════════════════════════════════════
// TIPOS DE RESULTADO DE AUTENTICACIÓN
// ═══════════════════════════════════════════════════════════════════════════════

/// Resultado de una operación de autenticación.
///
/// Usa [AuthSuccess] o [AuthFailure] según el resultado.
@immutable
sealed class AuthResult<T> {
  const AuthResult();

  /// Indica si la operación fue exitosa.
  bool get isSuccess => this is AuthSuccess<T>;

  /// Indica si la operación falló.
  bool get isFailure => this is AuthFailure<T>;

  /// Obtiene el valor si fue exitoso.
  T? get value {
    if (this is AuthSuccess<T>) {
      return (this as AuthSuccess<T>).data;
    }
    return null;
  }

  /// Ejecuta una función según el resultado.
  R when<R>({
    required R Function(T data) success,
    required R Function(String message, String? code) failure,
  }) {
    if (this is AuthSuccess<T>) {
      return success((this as AuthSuccess<T>).data);
    } else {
      final failure_ = this as AuthFailure<T>;
      return failure(failure_.message, failure_.code);
    }
  }
}

/// Resultado exitoso de una operación de autenticación.
@immutable
class AuthSuccess<T> extends AuthResult<T> {
  /// Datos retornados por la operación.
  final T data;

  const AuthSuccess(this.data);

  @override
  String toString() => 'AuthSuccess(data: $data)';
}

/// Resultado fallido de una operación de autenticación.
@immutable
class AuthFailure<T> extends AuthResult<T> {
  /// Mensaje de error.
  final String message;

  /// Código de error (opcional).
  final String? code;

  const AuthFailure({required this.message, this.code});

  @override
  String toString() => 'AuthFailure(message: $message, code: $code)';
}

// ═══════════════════════════════════════════════════════════════════════════════
// ENUM DE ACCIONES DE AUTENTICACIÓN
// ═══════════════════════════════════════════════════════════════════════════════

/// Acciones de autenticación posibles.
enum AuthAction {
  /// Iniciar sesión
  signIn,

  /// Registrarse
  signUp,

  /// Cerrar sesión
  signOut,

  /// Restablecer contraseña
  resetPassword,

  /// Actualizar perfil
  updateProfile,

  /// Verificar sesión
  verifySession,

  /// Eliminar cuenta
  deleteAccount;

  /// Nombre para mostrar en español.
  String get displayName {
    switch (this) {
      case AuthAction.signIn:
        return 'Iniciar sesión';
      case AuthAction.signUp:
        return 'Registrarse';
      case AuthAction.signOut:
        return 'Cerrar sesión';
      case AuthAction.resetPassword:
        return 'Restablecer contraseña';
      case AuthAction.updateProfile:
        return 'Actualizar perfil';
      case AuthAction.verifySession:
        return 'Verificar sesión';
      case AuthAction.deleteAccount:
        return 'Eliminar cuenta';
    }
  }
}

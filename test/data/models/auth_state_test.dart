// ═══════════════════════════════════════════════════════════════════════════════════
// ║                           auth_state_test.dart                                  ║
// ║                  Tests para estados de autenticacion                            ║
// ═══════════════════════════════════════════════════════════════════════════════════
// ║  Verifica el comportamiento de AuthState, AuthResult y AuthAction.              ║
// ═══════════════════════════════════════════════════════════════════════════════════

import 'package:flutter_test/flutter_test.dart';
import 'package:nutrivision_aiepn_mobile/data/models/auth_state.dart';
import 'package:nutrivision_aiepn_mobile/data/models/user_profile.dart';

void main() {
  // Helper para crear UserProfile de prueba
  UserProfile createTestProfile(
      {String id = 'test-id', bool onboardingCompleted = false}) {
    final now = DateTime.now();
    return UserProfile(
      id: id,
      email: 'test@example.com',
      displayName: 'Test User',
      createdAt: now,
      updatedAt: now,
      onboardingCompleted: onboardingCompleted,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TESTS PARA AuthStateInitial
  // ═══════════════════════════════════════════════════════════════════════════

  group('AuthStateInitial', () {
    test('isAuthenticated es false', () {
      const state = AuthStateInitial();
      expect(state.isAuthenticated, isFalse);
    });

    test('isLoading es false', () {
      const state = AuthStateInitial();
      expect(state.isLoading, isFalse);
    });

    test('hasError es false', () {
      const state = AuthStateInitial();
      expect(state.hasError, isFalse);
    });

    test('profile es null', () {
      const state = AuthStateInitial();
      expect(state.profile, isNull);
    });

    test('toString retorna representacion correcta', () {
      const state = AuthStateInitial();
      expect(state.toString(), 'AuthStateInitial()');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // TESTS PARA AuthStateLoading
  // ═══════════════════════════════════════════════════════════════════════════

  group('AuthStateLoading', () {
    test('isLoading es true', () {
      const state = AuthStateLoading();
      expect(state.isLoading, isTrue);
    });

    test('isAuthenticated es false', () {
      const state = AuthStateLoading();
      expect(state.isAuthenticated, isFalse);
    });

    test('hasError es false', () {
      const state = AuthStateLoading();
      expect(state.hasError, isFalse);
    });

    test('acepta mensaje opcional', () {
      const state = AuthStateLoading(message: 'Cargando...');
      expect(state.message, 'Cargando...');
    });

    test('mensaje es null por defecto', () {
      const state = AuthStateLoading();
      expect(state.message, isNull);
    });

    test('toString incluye mensaje', () {
      const state = AuthStateLoading(message: 'Test');
      expect(state.toString(), contains('Test'));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // TESTS PARA AuthStateUnauthenticated
  // ═══════════════════════════════════════════════════════════════════════════

  group('AuthStateUnauthenticated', () {
    test('isAuthenticated es false', () {
      const state = AuthStateUnauthenticated();
      expect(state.isAuthenticated, isFalse);
    });

    test('isLoading es false', () {
      const state = AuthStateUnauthenticated();
      expect(state.isLoading, isFalse);
    });

    test('hasError es false', () {
      const state = AuthStateUnauthenticated();
      expect(state.hasError, isFalse);
    });

    test('wasSignedOut es false por defecto', () {
      const state = AuthStateUnauthenticated();
      expect(state.wasSignedOut, isFalse);
    });

    test('wasSignedOut puede ser true', () {
      const state = AuthStateUnauthenticated(wasSignedOut: true);
      expect(state.wasSignedOut, isTrue);
    });

    test('toString incluye wasSignedOut', () {
      const state = AuthStateUnauthenticated(wasSignedOut: true);
      expect(state.toString(), contains('wasSignedOut: true'));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // TESTS PARA AuthStateAuthenticated
  // ═══════════════════════════════════════════════════════════════════════════

  group('AuthStateAuthenticated', () {
    test('isAuthenticated es true', () {
      final profile = createTestProfile();
      final state = AuthStateAuthenticated(profile: profile);
      expect(state.isAuthenticated, isTrue);
    });

    test('isLoading es false', () {
      final profile = createTestProfile();
      final state = AuthStateAuthenticated(profile: profile);
      expect(state.isLoading, isFalse);
    });

    test('hasError es false', () {
      final profile = createTestProfile();
      final state = AuthStateAuthenticated(profile: profile);
      expect(state.hasError, isFalse);
    });

    test('profile retorna el perfil correcto', () {
      final profile = createTestProfile(id: 'my-id');
      final state = AuthStateAuthenticated(profile: profile);
      expect(state.profile, isNotNull);
      expect(state.profile.id, 'my-id');
    });

    test('needsProfileSetup es true cuando onboarding no completado', () {
      final profile = createTestProfile(onboardingCompleted: false);
      final state = AuthStateAuthenticated(profile: profile);
      expect(state.needsProfileSetup, isTrue);
    });

    test('needsProfileSetup es false cuando onboarding completado', () {
      final profile = createTestProfile(onboardingCompleted: true);
      final state = AuthStateAuthenticated(profile: profile);
      expect(state.needsProfileSetup, isFalse);
    });

    test('copyWithProfile actualiza el perfil', () {
      final original = createTestProfile(id: 'original');
      final newProfile = createTestProfile(id: 'updated');
      final state = AuthStateAuthenticated(profile: original);
      final updatedState = state.copyWithProfile(newProfile);

      expect(updatedState.profile.id, 'updated');
    });

    test('toString incluye email y needsSetup', () {
      final profile = createTestProfile();
      final state = AuthStateAuthenticated(profile: profile);
      final str = state.toString();

      expect(str, contains('test@example.com'));
      expect(str, contains('needsSetup'));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // TESTS PARA AuthStateError
  // ═══════════════════════════════════════════════════════════════════════════

  group('AuthStateError', () {
    test('hasError es true', () {
      const state = AuthStateError(message: 'Error');
      expect(state.hasError, isTrue);
    });

    test('isAuthenticated es false', () {
      const state = AuthStateError(message: 'Error');
      expect(state.isAuthenticated, isFalse);
    });

    test('isLoading es false', () {
      const state = AuthStateError(message: 'Error');
      expect(state.isLoading, isFalse);
    });

    test('message contiene el mensaje de error', () {
      const state = AuthStateError(message: 'Credenciales incorrectas');
      expect(state.message, 'Credenciales incorrectas');
    });

    test('code es opcional', () {
      const state = AuthStateError(message: 'Error', code: 'AUTH_001');
      expect(state.code, 'AUTH_001');
    });

    test('exception es opcional', () {
      final exception = Exception('Test');
      final state = AuthStateError(message: 'Error', exception: exception);
      expect(state.exception, exception);
    });

    test('toString incluye message y code', () {
      const state = AuthStateError(message: 'Error', code: 'CODE');
      final str = state.toString();

      expect(str, contains('Error'));
      expect(str, contains('CODE'));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // TESTS PARA AuthResult
  // ═══════════════════════════════════════════════════════════════════════════

  group('AuthSuccess', () {
    test('isSuccess es true', () {
      const result = AuthSuccess<String>('data');
      expect(result.isSuccess, isTrue);
    });

    test('isFailure es false', () {
      const result = AuthSuccess<String>('data');
      expect(result.isFailure, isFalse);
    });

    test('value retorna los datos', () {
      const result = AuthSuccess<int>(42);
      expect(result.value, 42);
    });

    test('data retorna los datos', () {
      const result = AuthSuccess<String>('test data');
      expect(result.data, 'test data');
    });

    test('when ejecuta success callback', () {
      const result = AuthSuccess<int>(10);
      final value = result.when(
        success: (data) => data * 2,
        failure: (message, code) => 0,
      );
      expect(value, 20);
    });

    test('toString incluye data', () {
      const result = AuthSuccess<String>('test');
      expect(result.toString(), contains('test'));
    });
  });

  group('AuthFailure', () {
    test('isFailure es true', () {
      const result = AuthFailure<String>(message: 'Error');
      expect(result.isFailure, isTrue);
    });

    test('isSuccess es false', () {
      const result = AuthFailure<String>(message: 'Error');
      expect(result.isSuccess, isFalse);
    });

    test('value es null', () {
      const result = AuthFailure<int>(message: 'Error');
      expect(result.value, isNull);
    });

    test('message contiene el mensaje de error', () {
      const result = AuthFailure<String>(message: 'Algo salio mal');
      expect(result.message, 'Algo salio mal');
    });

    test('code es opcional', () {
      const result = AuthFailure<String>(message: 'Error', code: 'E001');
      expect(result.code, 'E001');
    });

    test('when ejecuta failure callback', () {
      const result = AuthFailure<int>(message: 'Error', code: 'CODE');
      final value = result.when(
        success: (data) => 'success',
        failure: (message, code) => 'failure: $code',
      );
      expect(value, 'failure: CODE');
    });

    test('toString incluye message y code', () {
      const result = AuthFailure<String>(message: 'Error', code: 'CODE');
      final str = result.toString();

      expect(str, contains('Error'));
      expect(str, contains('CODE'));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // TESTS PARA AuthAction
  // ═══════════════════════════════════════════════════════════════════════════

  group('AuthAction', () {
    test('displayName retorna nombres correctos en espanol', () {
      expect(AuthAction.signIn.displayName, 'Iniciar sesión');
      expect(AuthAction.signUp.displayName, 'Registrarse');
      expect(AuthAction.signOut.displayName, 'Cerrar sesión');
      expect(AuthAction.resetPassword.displayName, 'Restablecer contraseña');
      expect(AuthAction.updateProfile.displayName, 'Actualizar perfil');
      expect(AuthAction.verifySession.displayName, 'Verificar sesión');
      expect(AuthAction.deleteAccount.displayName, 'Eliminar cuenta');
    });

    test('tiene 7 valores definidos', () {
      expect(AuthAction.values.length, 7);
    });
  });
}

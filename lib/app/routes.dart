// ╔═══════════════════════════════════════════════════════════════════════════════╗
// ║                             routes.dart                                       ║
// ║              Sistema de navegación con go_router                              ║
// ╠═══════════════════════════════════════════════════════════════════════════════╣
// ║  Configura la navegación declarativa de la aplicación.                        ║
// ║  Define rutas, transiciones y redirección basada en autenticación.            ║
// ╚═══════════════════════════════════════════════════════════════════════════════╝

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_constants.dart';
import '../data/models/auth_state.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/auth/views/login_screen.dart';
import '../features/auth/views/profile_setup_screen.dart';
import '../features/auth/views/register_screen.dart';
import '../features/detection/views/detection_gallery_screen.dart';
import '../features/detection/views/detection_live_screen.dart';
import '../features/home/views/home_screen.dart';
import '../features/onboarding/views/splash_screen.dart';
import '../features/onboarding/views/welcome_screen.dart';
import '../features/profile/views/edit_profile_screen.dart';
import '../features/profile/views/profile_screen.dart';

/// Provider del router de la aplicación.
///
/// Usa Riverpod para acceder al estado de autenticación
/// y configurar redirects dinámicos.
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    // Ruta inicial es splash para verificar auth
    initialLocation: AppConstants.routeSplash,

    // Habilitar logs en debug
    debugLogDiagnostics: true,

    // Redirect basado en estado de autenticación
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final isAuthRoute = [
        AppConstants.routeLogin,
        AppConstants.routeRegister,
        AppConstants.routeWelcome,
        AppConstants.routeSplash,
        AppConstants.routeForgotPassword,
      ].contains(state.matchedLocation);

      final isProfileSetup =
          state.matchedLocation == AppConstants.routeProfileSetup;

      // Si está en splash, dejar que la pantalla maneje la navegación
      if (state.matchedLocation == AppConstants.routeSplash) {
        return null;
      }

      // Si no está autenticado y no está en ruta de auth
      if (!isAuthenticated && !isAuthRoute) {
        return AppConstants.routeWelcome;
      }

      // Si está autenticado y está en ruta de auth (excepto profile setup)
      if (isAuthenticated && isAuthRoute && !isProfileSetup) {
        // Verificar si necesita completar perfil
        if (authState is AuthStateAuthenticated &&
            !authState.profile.onboardingCompleted) {
          return AppConstants.routeProfileSetup;
        }
        return AppConstants.routeHome;
      }

      return null;
    },

    // Definición de rutas
    routes: <RouteBase>[
      // ═══════════════════════════════════════════════════════════════════════
      // ONBOARDING & AUTH
      // ═══════════════════════════════════════════════════════════════════════

      // Splash Screen
      GoRoute(
        path: AppConstants.routeSplash,
        name: 'splash',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SplashScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),

      // Welcome Screen
      GoRoute(
        path: AppConstants.routeWelcome,
        name: 'welcome',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const WelcomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),

      // Login Screen
      GoRoute(
        path: AppConstants.routeLogin,
        name: 'login',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              )),
              child: child,
            );
          },
        ),
      ),

      // Register Screen
      GoRoute(
        path: AppConstants.routeRegister,
        name: 'register',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const RegisterScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              )),
              child: child,
            );
          },
        ),
      ),

      // Forgot Password Screen (placeholder)
      GoRoute(
        path: AppConstants.routeForgotPassword,
        name: 'forgot-password',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const _ForgotPasswordPlaceholder(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              )),
              child: child,
            );
          },
        ),
      ),

      // Profile Setup Screen
      GoRoute(
        path: AppConstants.routeProfileSetup,
        name: 'profile-setup',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ProfileSetupScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),

      // ═══════════════════════════════════════════════════════════════════════
      // PANTALLA PRINCIPAL
      // ═══════════════════════════════════════════════════════════════════════
      GoRoute(
        path: AppConstants.routeHome,
        name: 'home',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const HomePage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),

      // ═══════════════════════════════════════════════════════════════════════
      // PERFIL DE USUARIO
      // ═══════════════════════════════════════════════════════════════════════
      GoRoute(
        path: AppConstants.routeProfile,
        name: 'profile',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ProfileScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              )),
              child: child,
            );
          },
        ),
      ),

      // Edit Profile
      GoRoute(
        path: AppConstants.routeEditProfile,
        name: 'edit-profile',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const EditProfileScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              )),
              child: child,
            );
          },
        ),
      ),

      // ═══════════════════════════════════════════════════════════════════════
      // DETECCIÓN DESDE GALERÍA
      // ═══════════════════════════════════════════════════════════════════════
      GoRoute(
        path: AppConstants.routeGallery,
        name: 'gallery',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const GalleryDetectionPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              )),
              child: child,
            );
          },
        ),
      ),

      // ═══════════════════════════════════════════════════════════════════════
      // DETECCIÓN DESDE CÁMARA
      // ═══════════════════════════════════════════════════════════════════════
      GoRoute(
        path: AppConstants.routeCamera,
        name: 'camera',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const CameraDetectionPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              )),
              child: child,
            );
          },
        ),
      ),

      // ═══════════════════════════════════════════════════════════════════════
      // RESULTADOS (Placeholder)
      // ═══════════════════════════════════════════════════════════════════════
      GoRoute(
        path: AppConstants.routeResults,
        name: 'results',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const _ResultsPlaceholderPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 1.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              )),
              child: child,
            );
          },
        ),
      ),
    ],

    // Manejo de errores de navegación
    errorPageBuilder: (context, state) => MaterialPage(
      key: state.pageKey,
      child: _ErrorPage(error: state.error?.message ?? 'Página no encontrada'),
    ),
  );
});

/// Router legacy para compatibilidad (usa el provider internamente).
/// Nota: Preferir usar appRouterProvider con Consumer/ConsumerWidget.
final GoRouter appRouter = GoRouter(
  initialLocation: AppConstants.routeSplash,
  debugLogDiagnostics: true,
  routes: <RouteBase>[
    GoRoute(
      path: AppConstants.routeSplash,
      name: 'splash-legacy',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: AppConstants.routeWelcome,
      name: 'welcome-legacy',
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(
      path: AppConstants.routeLogin,
      name: 'login-legacy',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: AppConstants.routeRegister,
      name: 'register-legacy',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: AppConstants.routeProfileSetup,
      name: 'profile-setup-legacy',
      builder: (context, state) => const ProfileSetupScreen(),
    ),
    GoRoute(
      path: AppConstants.routeHome,
      name: 'home-legacy',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: AppConstants.routeProfile,
      name: 'profile-legacy',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: AppConstants.routeEditProfile,
      name: 'edit-profile-legacy',
      builder: (context, state) => const EditProfileScreen(),
    ),
    GoRoute(
      path: AppConstants.routeGallery,
      name: 'gallery-legacy',
      builder: (context, state) => const GalleryDetectionPage(),
    ),
    GoRoute(
      path: AppConstants.routeCamera,
      name: 'camera-legacy',
      builder: (context, state) => const CameraDetectionPage(),
    ),
  ],
  errorBuilder: (context, state) =>
      _ErrorPage(error: state.error?.message ?? 'Página no encontrada'),
);

// ═══════════════════════════════════════════════════════════════════════════════
// PÁGINAS PLACEHOLDER
// ═══════════════════════════════════════════════════════════════════════════════

/// Página placeholder para recuperar contraseña.
class _ForgotPasswordPlaceholder extends StatelessWidget {
  const _ForgotPasswordPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recuperar Contraseña'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_reset,
                size: 80,
                color: Theme.of(context).colorScheme.primary.withAlpha(128),
              ),
              const SizedBox(height: 24),
              Text(
                'Próximamente',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'La funcionalidad de recuperación de contraseña estará disponible pronto.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withAlpha(153),
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              OutlinedButton.icon(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Volver'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Página placeholder para resultados nutricionales.
class _ResultsPlaceholderPage extends StatelessWidget {
  const _ResultsPlaceholderPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultados'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withAlpha(128),
            ),
            const SizedBox(height: 24),
            Text(
              'Próximamente',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Información nutricional detallada',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color:
                        Theme.of(context).colorScheme.onSurface.withAlpha(153),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: () => context.go(AppConstants.routeHome),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Volver al inicio'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Página de error de navegación.
class _ErrorPage extends StatelessWidget {
  final String error;

  const _ErrorPage({required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 24),
            Text(
              'Página no encontrada',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                error,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => context.go(AppConstants.routeHome),
              icon: const Icon(Icons.home),
              label: const Text('Ir al inicio'),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// EXTENSIONES DE NAVEGACIÓN
// ═══════════════════════════════════════════════════════════════════════════════

/// Extensión para facilitar la navegación desde BuildContext.
extension NavigationExtension on BuildContext {
  /// Navega a la pantalla de detección desde galería.
  void goToGallery() => go(AppConstants.routeGallery);

  /// Navega a la pantalla de detección con cámara.
  void goToCamera() => go(AppConstants.routeCamera);

  /// Navega a la pantalla de resultados.
  void goToResults() => go(AppConstants.routeResults);

  /// Navega al inicio.
  void goToHome() => go(AppConstants.routeHome);

  /// Navega al perfil.
  void goToProfile() => go(AppConstants.routeProfile);

  /// Navega al login.
  void goToLogin() => go(AppConstants.routeLogin);

  /// Navega al registro.
  void goToRegister() => go(AppConstants.routeRegister);

  /// Navega al welcome.
  void goToWelcome() => go(AppConstants.routeWelcome);

  /// Navega hacia atrás o al inicio si no hay historial.
  void goBackOrHome() {
    if (canPop()) {
      pop();
    } else {
      go(AppConstants.routeHome);
    }
  }
}

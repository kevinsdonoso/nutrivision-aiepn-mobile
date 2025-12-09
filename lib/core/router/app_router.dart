// ╔═══════════════════════════════════════════════════════════════════════════════╗
// ║                         app_router.dart                                       ║
// ║              Sistema de navegación con go_router                              ║
// ╠═══════════════════════════════════════════════════════════════════════════════╣
// ║  Configura la navegación declarativa de la aplicación.                        ║
// ║  Define rutas, transiciones y manejo de deep links.                           ║
// ╚═══════════════════════════════════════════════════════════════════════════════╝

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_constants.dart';
import '../../presentation/pages/home_page.dart';
import '../../presentation/pages/gallery_detection_page.dart';

/// Configuración del router de la aplicación.
///
/// Uso en main.dart:
/// ```dart
/// MaterialApp.router(
///   routerConfig: appRouter,
///   // ...
/// )
/// ```
final GoRouter appRouter = GoRouter(
  // Ruta inicial
  initialLocation: AppConstants.routeHome,

  // Habilitar logs en debug
  debugLogDiagnostics: true,

  // Definición de rutas
  routes: <RouteBase>[
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
    // DETECCIÓN DESDE CÁMARA (Placeholder)
    // ═══════════════════════════════════════════════════════════════════════
    GoRoute(
      path: AppConstants.routeCamera,
      name: 'camera',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const _CameraPlaceholderPage(),
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

// ═══════════════════════════════════════════════════════════════════════════════
// PÁGINAS PLACEHOLDER (Se reemplazarán con implementaciones reales)
// ═══════════════════════════════════════════════════════════════════════════════

/// Página placeholder para detección con cámara.
class _CameraPlaceholderPage extends StatelessWidget {
  const _CameraPlaceholderPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detección con Cámara'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt_outlined,
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
              'Detección en tiempo real desde la cámara',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
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
                    color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
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

  /// Navega hacia atrás o al inicio si no hay historial.
  void goBackOrHome() {
    if (canPop()) {
      pop();
    } else {
      go(AppConstants.routeHome);
    }
  }
}

// ╔═══════════════════════════════════════════════════════════════════════════════╗
// ║                           splash_screen.dart                                  ║
// ║                    Pantalla de carga inicial de la app                        ║
// ╠═══════════════════════════════════════════════════════════════════════════════╣
// ║  Primera pantalla que ve el usuario al abrir la app.                          ║
// ║  Muestra logo mientras verifica estado de autenticación.                      ║
// ╚═══════════════════════════════════════════════════════════════════════════════╝

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/session/session_manager.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../data/models/auth_state.dart';

/// Pantalla de splash/carga inicial.
///
/// Muestra el logo de NutriVision mientras:
/// 1. Inicializa Firebase
/// 2. Verifica si hay sesión activa
/// 3. Redirige según el estado
///
/// Flujo de navegación:
/// - No autenticado + no vio onboarding → Welcome
/// - No autenticado + vio onboarding → Login
/// - Autenticado + sin perfil completo → ProfileSetup
/// - Autenticado + perfil completo → Home
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Configurar animaciones
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();

    // Iniciar verificación después de animación
    Future.delayed(const Duration(milliseconds: 2000), _checkAuthState);
  }

  Future<void> _checkAuthState() async {
    if (!mounted) return;

    final authState = ref.read(authStateProvider);
    final sessionManager = ref.read(sessionManagerProvider);

    // Asegurar que SessionManager esté inicializado
    if (!sessionManager.isInitialized) {
      await sessionManager.init();
    }

    if (!mounted) return;

    _navigate(authState, sessionManager);
  }

  void _navigate(AuthState authState, SessionManager sessionManager) {
    switch (authState) {
      case AuthStateAuthenticated(:final profile):
        // Usuario autenticado
        if (!profile.onboardingCompleted) {
          context.go('/profile-setup');
        } else {
          context.go('/');
        }
        break;

      case AuthStateUnauthenticated():
      case AuthStateInitial():
      case AuthStateError():
        // Usuario no autenticado
        if (sessionManager.hasSeenOnboarding) {
          context.go('/login');
        } else {
          context.go('/welcome');
        }
        break;

      case AuthStateLoading():
        // Esperar a que termine de cargar
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _checkAuthState();
          }
        });
        break;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Escuchar cambios en el estado de autenticación
    ref.listen<AuthState>(authStateProvider, (previous, next) {
      if (next is! AuthStateLoading && next is! AuthStateInitial) {
        final sessionManager = ref.read(sessionManagerProvider);
        if (sessionManager.isInitialized) {
          _navigate(next, sessionManager);
        }
      }
    });

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primary.withAlpha(200),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // Logo animado
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: child,
                    ),
                  );
                },
                child: Column(
                  children: [
                    // Icono
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(40),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.restaurant_menu,
                        size: 64,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Nombre de la app
                    Text(
                      'NutriVision',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                    ),
                    const SizedBox(height: 8),

                    // Subtítulo
                    Text(
                      'Tu asistente nutricional con IA',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.white.withAlpha(200),
                          ),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 2),

              // Indicador de carga
              Padding(
                padding: const EdgeInsets.only(bottom: 48),
                child: Column(
                  children: [
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Cargando...',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withAlpha(180),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

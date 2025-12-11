// ╔═══════════════════════════════════════════════════════════════════════════════╗
// ║                          welcome_screen.dart                                  ║
// ║                   Pantalla de bienvenida para nuevos usuarios                 ║
// ╠═══════════════════════════════════════════════════════════════════════════════╣
// ║  Primera pantalla después del splash para usuarios no autenticados.           ║
// ║  Presenta la app y opciones de login/registro.                                ║
// ╚═══════════════════════════════════════════════════════════════════════════════╝

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/session/session_manager.dart';

/// Pantalla de bienvenida para nuevos usuarios.
///
/// Presenta:
/// - Logo y nombre de la app
/// - Descripción breve de funcionalidades
/// - Botones para iniciar sesión o registrarse
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Logo y título
              _buildHeader(context, theme),

              const SizedBox(height: 48),

              // Features
              _buildFeatures(context, theme),

              const Spacer(flex: 2),

              // Botones de acción
              _buildButtons(context, ref, theme, size),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Column(
      children: [
        // Logo
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primary.withAlpha(200),
              ],
            ),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withAlpha(60),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.restaurant_menu,
            size: 50,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 24),

        // Título
        Text(
          'NutriVision AI',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),

        // Subtítulo
        Text(
          'Detecta ingredientes y conoce\nsu información nutricional',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: Colors.grey[600],
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatures(BuildContext context, ThemeData theme) {
    return Column(
      children: [
        _FeatureItem(
          icon: Icons.camera_alt_outlined,
          title: 'Detección con IA',
          description: 'Detecta ingredientes automáticamente con tu cámara',
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 16),
        _FeatureItem(
          icon: Icons.analytics_outlined,
          title: 'Información nutricional',
          description: 'Conoce calorías, proteínas, carbohidratos y más',
          color: Colors.orange,
        ),
        const SizedBox(height: 16),
        _FeatureItem(
          icon: Icons.offline_bolt_outlined,
          title: '100% Offline',
          description: 'Funciona sin conexión a internet',
          color: Colors.blue,
        ),
      ],
    );
  }

  Widget _buildButtons(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    Size size,
  ) {
    return Column(
      children: [
        // Botón Crear Cuenta
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () => _navigateToRegister(context, ref),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
            ),
            child: const Text(
              'Crear Cuenta',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Botón Iniciar Sesión
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            onPressed: () => _navigateToLogin(context, ref),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.primary,
              side: BorderSide(
                color: theme.colorScheme.primary,
                width: 2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Ya tengo cuenta',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _navigateToRegister(BuildContext context, WidgetRef ref) {
    _markOnboardingSeen(ref);
    context.go('/register');
  }

  void _navigateToLogin(BuildContext context, WidgetRef ref) {
    _markOnboardingSeen(ref);
    context.go('/login');
  }

  void _markOnboardingSeen(WidgetRef ref) {
    final sessionManager = ref.read(sessionManagerProvider);
    if (sessionManager.isInitialized) {
      sessionManager.markOnboardingSeen();
    }
  }
}

/// Widget para mostrar una característica de la app.
class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Icono
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withAlpha(26),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),

        // Texto
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

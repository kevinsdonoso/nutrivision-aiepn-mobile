// ╔═══════════════════════════════════════════════════════════════════════════════╗
// ║                         home_screen.dart                                      ║
// ║              Pantalla principal de NutriVisionAIEPN                           ║
// ╠═══════════════════════════════════════════════════════════════════════════════╣
// ║  Punto de entrada visual de la aplicación.                                    ║
// ║  Ofrece acceso a detección desde galería y cámara.                            ║
// ╚═══════════════════════════════════════════════════════════════════════════════╝

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/widgets/runtime_mode_indicator.dart';

/// Pantalla principal de la aplicación.
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final ScrollController _scrollController = ScrollController();
  double _scrollOpacity = 1.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Calcular opacidad basada en el scroll (fade out de 0 a 150 pixels)
    final offset = _scrollController.offset;
    final opacity = (1.0 - (offset / 150)).clamp(0.0, 1.0);

    if (opacity != _scrollOpacity) {
      setState(() {
        _scrollOpacity = opacity;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentUserProfileProvider);
    final isAuthenticated = ref.watch(isAuthenticatedProvider);

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                // AppBar con diseño expandible
                SliverAppBar(
                  expandedHeight: 200,
                  floating: false,
                  pinned: true,
                  backgroundColor: AppColors.primaryGreen,
                  centerTitle: true,
                  actions: [
                    // Botón de perfil/avatar
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _ProfileButton(
                        isAuthenticated: isAuthenticated,
                        photoUrl: profile?.photoUrl,
                        initials: profile?.initials ?? '?',
                        onTap: () {
                          if (isAuthenticated) {
                            context.push(AppConstants.routeProfile);
                          } else {
                            context.push(AppConstants.routeLogin);
                          }
                        },
                      ),
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    centerTitle: true,
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.primaryGreen,
                            AppColors.primaryGreenDark,
                          ],
                        ),
                      ),
                      child: Opacity(
                        opacity: _scrollOpacity,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 40),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Icono de cubiertos
                                const Icon(
                                  Icons.restaurant_menu,
                                  size: 60,
                                  color: Colors.white,
                                ),
                                const SizedBox(height: 12),
                                // Texto "NutriVision AI"
                                Text(
                                  'NutriVision AI',
                                  style: GoogleFonts.poppins(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Saludo personalizado
                                if (isAuthenticated && profile != null)
                                  Text(
                                    'Hola, ${profile.displayName}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.white70,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Contenido principal
                SliverPadding(
                  padding: const EdgeInsets.all(AppConstants.paddingMedium),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: 8),

                      // Sección de título
                      Text(
                        '¿Cómo quieres detectar?',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),

                      // Card: Detectar desde Galería
                      _DetectionOptionCard(
                        icon: Icons.photo_library_outlined,
                        title: 'Desde Galería',
                        subtitle: 'Selecciona una imagen de tu galería',
                        color: AppColors.primaryGreen,
                        onTap: () => context.go(AppConstants.routeGallery),
                      ),
                      const SizedBox(height: 12),

                      // Card: Detectar con Cámara
                      _DetectionOptionCard(
                        icon: Icons.camera_alt_outlined,
                        title: 'Con Cámara',
                        subtitle: 'Detecta ingredientes en tiempo real',
                        color: AppColors.secondaryOrange,
                        onTap: () => context.go(AppConstants.routeCamera),
                      ),
                      const SizedBox(height: 32),

                      // Sección de información
                      Text(
                        'Platos soportados',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),

                      // Grid de platos
                      _SupportedDishesGrid(),
                      const SizedBox(height: 32),

                      // Estadísticas del modelo
                      _ModelInfoCard(),
                      const SizedBox(height: 24),
                    ]),
                  ),
                ),
              ],
            ),
          ),
          // RuntimeModeBadge en esquina superior izquierda
          const SafeArea(
            child: Padding(
              padding: EdgeInsets.only(left: 16, top: 16),
              child: RuntimeModeBadge(show: true),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// WIDGETS PRIVADOS
// ═══════════════════════════════════════════════════════════════════════════════

/// Card para opcion de deteccion.
class _DetectionOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _DetectionOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: AppConstants.elevationSmall,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          child: Row(
            children: [
              // Icono con fondo circular
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isDark ? color.withAlpha(40) : color.withAlpha(26),
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusMedium),
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: color,
                ),
              ),
              const SizedBox(width: 16),

              // Textos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),

              // Flecha
              Icon(
                Icons.chevron_right,
                color: color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Grid de platos soportados.
class _SupportedDishesGrid extends StatelessWidget {
  // Íconos representativos para cada plato
  static const List<IconData> _dishIcons = [
    Icons.eco, // Ensalada Caprese
    Icons.water_drop, // Ceviche
    Icons.local_pizza, // Pizza
    Icons.soup_kitchen, // Menestra
    Icons.rice_bowl, // Paella
    Icons.dinner_dining, // Fritada
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(
        AppConstants.supportedDishes.length,
        (index) => _DishChip(
          name: AppConstants.supportedDishes[index],
          icon: _dishIcons[index],
        ),
      ),
    );
  }
}

/// Chip individual de plato.
class _DishChip extends StatelessWidget {
  final String name;
  final IconData icon;

  const _DishChip({
    required this.name,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.chipBackgroundDark
            : AppColors.primaryGreenLight.withAlpha(128),
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        border: Border.all(
          color: theme.colorScheme.primary.withAlpha(51),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 6),
          Text(
            name,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? AppColors.primaryGreenDarkMode
                  : AppColors.primaryGreenDark,
            ),
          ),
        ],
      ),
    );
  }
}

/// Card con información del modelo.
class _ModelInfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 0,
      color: isDark
          ? theme.colorScheme.surfaceContainerHighest
          : AppColors.backgroundLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.psychology_outlined,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Modelo de IA',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const _InfoRow(
              label: 'Arquitectura',
              value: 'YOLO11n (Ultralytics)',
            ),
            const _InfoRow(
              label: 'Ingredientes',
              value: '83 clases',
            ),
            const _InfoRow(
              label: 'Formato',
              value: 'TensorFlow Lite',
            ),
            const _InfoRow(
              label: 'Modo',
              value: '100% Offline',
            ),
          ],
        ),
      ),
    );
  }
}

/// Fila de información.
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}

/// Botón de perfil/avatar en el AppBar.
class _ProfileButton extends StatelessWidget {
  final bool isAuthenticated;
  final String? photoUrl;
  final String initials;
  final VoidCallback onTap;

  const _ProfileButton({
    required this.isAuthenticated,
    required this.photoUrl,
    required this.initials,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withAlpha(51),
            border: Border.all(
              color: Colors.white.withAlpha(128),
              width: 2,
            ),
          ),
          child: isAuthenticated
              ? _buildAvatar()
              : const Icon(
                  Icons.person_outline,
                  color: Colors.white,
                  size: 22,
                ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          photoUrl!,
          width: 36,
          height: 36,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildInitials(),
        ),
      );
    }
    return _buildInitials();
  }

  Widget _buildInitials() {
    return Center(
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}

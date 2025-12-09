// ╔═══════════════════════════════════════════════════════════════════════════════╗
// ║                         home_page.dart                                        ║
// ║              Pantalla principal de NutriVisionAIEPN                           ║
// ╠═══════════════════════════════════════════════════════════════════════════════╣
// ║  Punto de entrada visual de la aplicación.                                    ║
// ║  Ofrece acceso a detección desde galería y cámara.                            ║
// ╚═══════════════════════════════════════════════════════════════════════════════╝

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';

/// Pantalla principal de la aplicación.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // AppBar con diseño expandible
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              backgroundColor: AppColors.primaryGreen,
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,
                title: Text(
                  AppConstants.appName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.restaurant_menu,
                          size: 64,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppConstants.appDescription,
                          style: TextStyle(
                            color: Colors.white.withAlpha(230),
                            fontSize: 14,
                          ),
                        ),
                      ],
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
                    subtitle: 'Toma una foto o detecta en tiempo real',
                    color: AppColors.secondaryOrange,
                    onTap: () => context.go(AppConstants.routeCamera),
                    badge: 'Próximamente',
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
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// WIDGETS PRIVADOS
// ═══════════════════════════════════════════════════════════════════════════════

/// Card para opción de detección.
class _DetectionOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final String? badge;

  const _DetectionOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
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
              // Ícono con fondo circular
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withAlpha(26),
                  borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
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
                    Row(
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryOrangeLight,
                              borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                            ),
                            child: Text(
                              badge!,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.secondaryOrangeDark,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryGreenLight.withAlpha(128),
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        border: Border.all(
          color: AppColors.primaryGreen.withAlpha(51),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: AppColors.primaryGreenDark,
          ),
          const SizedBox(width: 6),
          Text(
            name,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.primaryGreenDark,
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
    return Card(
      elevation: 0,
      color: AppColors.backgroundLight,
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
                  color: AppColors.primaryGreen,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Modelo de IA',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.primaryGreen,
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

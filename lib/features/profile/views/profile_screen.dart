// ╔═══════════════════════════════════════════════════════════════════════════════╗
// ║                           profile_screen.dart                                 ║
// ║                      Pantalla de perfil de usuario                            ║
// ╠═══════════════════════════════════════════════════════════════════════════════╣
// ║  Muestra el perfil completo del usuario con sus datos y opciones.             ║
// ║  Permite cerrar sesión y acceder a edición de perfil.                         ║
// ╚═══════════════════════════════════════════════════════════════════════════════╝

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/user_profile.dart';
import '../../auth/providers/auth_provider.dart';

/// Pantalla de perfil del usuario.
///
/// Muestra:
/// - Avatar y datos básicos
/// - Datos físicos y nutricionales
/// - Opciones de cuenta (editar, cerrar sesión)
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profile = ref.watch(currentUserProfileProvider);

    if (profile == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header con avatar
          _buildHeader(context, theme, profile),

          // Contenido
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Datos personales
                  _buildSection(
                    context,
                    theme,
                    title: 'Datos Personales',
                    icon: Icons.person_outlined,
                    children: [
                      _buildInfoRow(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        value: profile.email,
                      ),
                      if (profile.age != null)
                        _buildInfoRow(
                          icon: Icons.cake_outlined,
                          label: 'Edad',
                          value: '${profile.age} años',
                        ),
                      if (profile.gender != null)
                        _buildInfoRow(
                          icon: Icons.wc_outlined,
                          label: 'Género',
                          value: profile.gender!.displayName,
                        ),
                      if (profile.locationFormatted != null)
                        _buildInfoRow(
                          icon: Icons.location_on_outlined,
                          label: 'Ubicación',
                          value: profile.locationFormatted!,
                        ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Datos físicos
                  if (profile.hasPhysicalData)
                    _buildSection(
                      context,
                      theme,
                      title: 'Datos Físicos',
                      icon: Icons.fitness_center_outlined,
                      children: [
                        if (profile.weightKg != null)
                          _buildInfoRow(
                            icon: Icons.monitor_weight_outlined,
                            label: 'Peso',
                            value: '${profile.weightKg!.toStringAsFixed(1)} kg',
                          ),
                        if (profile.heightCm != null)
                          _buildInfoRow(
                            icon: Icons.height,
                            label: 'Altura',
                            value: '${profile.heightCm!.toStringAsFixed(0)} cm',
                          ),
                        if (profile.bmi != null)
                          _buildInfoRow(
                            icon: Icons.speed_outlined,
                            label: 'IMC',
                            value:
                                '${profile.bmi!.toStringAsFixed(1)} (${profile.bmiCategory?.displayName ?? ""})',
                          ),
                        if (profile.activityLevel != null)
                          _buildInfoRow(
                            icon: Icons.directions_run_outlined,
                            label: 'Actividad',
                            value: profile.activityLevel!.displayName,
                          ),
                      ],
                    ),

                  if (profile.hasPhysicalData) const SizedBox(height: 16),

                  // Metas nutricionales
                  if (profile.hasNutritionData)
                    _buildSection(
                      context,
                      theme,
                      title: 'Metas Nutricionales',
                      icon: Icons.restaurant_outlined,
                      children: [
                        if (profile.nutritionGoal != null)
                          _buildInfoRow(
                            icon: Icons.flag_outlined,
                            label: 'Objetivo',
                            value: profile.nutritionGoal!.displayName,
                          ),
                        if (profile.dailyCalorieTarget != null)
                          _buildInfoRow(
                            icon: Icons.local_fire_department_outlined,
                            label: 'Calorías diarias',
                            value: '${profile.dailyCalorieTarget} kcal',
                            valueColor: Colors.orange,
                          ),
                      ],
                    ),

                  if (profile.hasNutritionData) const SizedBox(height: 16),

                  // Acciones
                  _buildSection(
                    context,
                    theme,
                    title: 'Cuenta',
                    icon: Icons.settings_outlined,
                    children: [
                      _buildActionTile(
                        context,
                        icon: Icons.edit_outlined,
                        label: 'Editar perfil',
                        onTap: () => context.push('/edit-profile'),
                      ),
                      _buildActionTile(
                        context,
                        icon: Icons.logout,
                        label: 'Cerrar sesión',
                        onTap: () => _showLogoutDialog(context, ref),
                        isDestructive: true,
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ThemeData theme,
    UserProfile profile,
  ) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      leading: IconButton(
        onPressed: () => context.pop(),
        icon: const Icon(Icons.arrow_back),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primary.withAlpha(200),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                // Avatar
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  backgroundImage: profile.photoUrl != null
                      ? NetworkImage(profile.photoUrl!)
                      : null,
                  child: profile.photoUrl == null
                      ? Text(
                          profile.initials,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 12),

                // Nombre
                Text(
                  profile.displayName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                // Completitud del perfil
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _showMissingFieldsDialog(context, profile),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(50),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Perfil ${profile.profileCompletionPercent}% completo',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        if (profile.profileCompletionPercent < 100) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.info_outline,
                            color: Colors.white70,
                            size: 14,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    ThemeData theme, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? theme.colorScheme.outline : Colors.grey.shade200,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        final secondaryColor = theme.colorScheme.onSurfaceVariant;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Icon(icon, size: 20, color: secondaryColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(color: secondaryColor),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: valueColor,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final theme = Theme.of(context);
    final defaultColor = theme.colorScheme.onSurfaceVariant;
    final color = isDestructive ? theme.colorScheme.error : null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color ?? defaultColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: color ?? defaultColor.withAlpha(150),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        return AlertDialog(
          title: const Text('Cerrar Sesion'),
          content: const Text('Estas seguro de que deseas cerrar sesion?'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await ref.read(authStateProvider.notifier).signOut();
                if (context.mounted) {
                  context.go('/welcome');
                }
              },
              child: Text(
                'Cerrar Sesion',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showMissingFieldsDialog(BuildContext context, UserProfile profile) {
    final theme = Theme.of(context);
    final missingFields = <String>[];

    // Verificar campos faltantes
    if (profile.photoUrl == null) missingFields.add('Foto de perfil');
    if (profile.birthDate == null) missingFields.add('Fecha de nacimiento');
    if (profile.gender == null) missingFields.add('Genero');
    if (profile.country == null) missingFields.add('Pais');
    if (profile.city == null) missingFields.add('Ciudad');
    if (profile.weightKg == null) missingFields.add('Peso');
    if (profile.heightCm == null) missingFields.add('Altura');
    if (profile.activityLevel == null) missingFields.add('Nivel de actividad');
    if (profile.nutritionGoal == null) missingFields.add('Meta nutricional');
    if (profile.dailyCalorieTarget == null) missingFields.add('Calorias diarias');

    if (missingFields.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: theme.colorScheme.onPrimary),
              const SizedBox(width: 8),
              const Text('Tu perfil esta completo'),
            ],
          ),
          backgroundColor: theme.colorScheme.primary,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              const Text('Completa tu perfil'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Te faltan ${missingFields.length} campos para completar tu perfil:',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              ...missingFields.map((field) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 8,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 12),
                    Text(field),
                  ],
                ),
              )),
            ],
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cerrar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                context.push('/edit-profile');
              },
              child: const Text('Editar perfil'),
            ),
          ],
        );
      },
    );
  }
}

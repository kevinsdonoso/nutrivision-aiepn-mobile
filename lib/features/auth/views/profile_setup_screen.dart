// ╔═══════════════════════════════════════════════════════════════════════════════╗
// ║                        profile_setup_screen.dart                              ║
// ║               Pantalla para completar el perfil de usuario                    ║
// ╠═══════════════════════════════════════════════════════════════════════════════╣
// ║  Permite al usuario completar sus datos después del registro.                 ║
// ║  Incluye datos personales, físicos y metas nutricionales.                     ║
// ╚═══════════════════════════════════════════════════════════════════════════════╝

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/user_profile.dart';
import '../providers/auth_provider.dart';

/// Pantalla para completar el perfil después del registro.
///
/// Recolecta:
/// - Datos personales (fecha de nacimiento, género)
/// - Datos físicos (peso, altura, nivel de actividad)
/// - Metas nutricionales
class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;

  // Datos del formulario
  DateTime? _birthDate;
  Gender? _gender;
  double? _weightKg;
  double? _heightCm;
  ActivityLevel? _activityLevel;
  NutritionGoal? _nutritionGoal;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeSetup();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeSetup() async {
    setState(() => _isLoading = true);

    final authNotifier = ref.read(authStateProvider.notifier);
    final currentProfile = ref.read(currentUserProfileProvider);

    if (currentProfile == null) {
      setState(() => _isLoading = false);
      return;
    }

    // Actualizar perfil con los nuevos datos
    final updatedProfile = currentProfile.copyWith(
      birthDate: _birthDate,
      gender: _gender,
      weightKg: _weightKg,
      heightCm: _heightCm,
      activityLevel: _activityLevel,
      nutritionGoal: _nutritionGoal,
      dailyCalorieTarget: _calculateCalorieTarget(),
      onboardingCompleted: true,
    );

    final result = await authNotifier.updateProfile(updatedProfile);

    if (!mounted) return;

    setState(() => _isLoading = false);

    result.when(
      success: (_) {
        context.go('/');
      },
      failure: (message, _) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      },
    );
  }

  int? _calculateCalorieTarget() {
    if (_weightKg == null ||
        _heightCm == null ||
        _birthDate == null ||
        _gender == null ||
        _activityLevel == null ||
        _nutritionGoal == null) {
      return null;
    }

    // Calcular edad
    final now = DateTime.now();
    int age = now.year - _birthDate!.year;
    if (now.month < _birthDate!.month ||
        (now.month == _birthDate!.month && now.day < _birthDate!.day)) {
      age--;
    }

    // Calcular TMB (Mifflin-St Jeor)
    final baseTmb = 10 * _weightKg! + 6.25 * _heightCm! - 5 * age;
    final tmb = _gender == Gender.male ? baseTmb + 5 : baseTmb - 161;

    // Calcular TDEE
    final tdee = tmb * _activityLevel!.multiplier;

    // Ajustar según meta
    switch (_nutritionGoal!) {
      case NutritionGoal.loseWeight:
        return (tdee * 0.80).round();
      case NutritionGoal.maintain:
        return tdee.round();
      case NutritionGoal.gainMuscle:
        return (tdee * 1.15).round();
    }
  }

  void _skipSetup() async {
    setState(() => _isLoading = true);

    final authNotifier = ref.read(authStateProvider.notifier);
    await authNotifier.completeOnboarding();

    if (!mounted) return;

    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header con indicador de progreso
            _buildHeader(theme),

            // Contenido del step actual
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  _buildPersonalDataStep(theme),
                  _buildPhysicalDataStep(theme),
                  _buildGoalsStep(theme),
                ],
              ),
            ),

            // Botones de navegación
            _buildNavigationButtons(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Completa tu perfil',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: _skipSetup,
                child: const Text('Omitir'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Indicador de progreso
          Row(
            children: List.generate(3, (index) {
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
                  height: 4,
                  decoration: BoxDecoration(
                    color: index <= _currentPage
                        ? theme.colorScheme.primary
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            'Paso ${_currentPage + 1} de 3',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalDataStep(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Datos Personales',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Esta información nos ayuda a personalizar tu experiencia',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),

          // Fecha de nacimiento
          _buildDatePicker(theme),

          const SizedBox(height: 24),

          // Género
          Text(
            'Género',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: Gender.values.map((gender) {
              final isSelected = _gender == gender;
              return ChoiceChip(
                label: Text(gender.displayName),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() => _gender = selected ? gender : null);
                },
                selectedColor: theme.colorScheme.primary.withAlpha(50),
                labelStyle: TextStyle(
                  color: isSelected ? theme.colorScheme.primary : null,
                  fontWeight: isSelected ? FontWeight.w600 : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fecha de nacimiento',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _birthDate ?? DateTime(2000),
              firstDate: DateTime(1920),
              lastDate: DateTime.now(),
              builder: (context, child) {
                return Theme(
                  data: theme.copyWith(
                    colorScheme: theme.colorScheme.copyWith(
                      primary: theme.colorScheme.primary,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (date != null) {
              setState(() => _birthDate = date);
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.grey[600]),
                const SizedBox(width: 12),
                Text(
                  _birthDate != null
                      ? '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}'
                      : 'Selecciona tu fecha de nacimiento',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: _birthDate != null ? null : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhysicalDataStep(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Datos Físicos',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Estos datos nos ayudan a calcular tus necesidades nutricionales',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),

          // Peso
          _buildNumberInput(
            theme: theme,
            label: 'Peso',
            value: _weightKg,
            unit: 'kg',
            icon: Icons.monitor_weight_outlined,
            onChanged: (value) => setState(() => _weightKg = value),
            min: 20,
            max: 300,
          ),

          const SizedBox(height: 24),

          // Altura
          _buildNumberInput(
            theme: theme,
            label: 'Altura',
            value: _heightCm,
            unit: 'cm',
            icon: Icons.height,
            onChanged: (value) => setState(() => _heightCm = value),
            min: 100,
            max: 250,
          ),

          const SizedBox(height: 24),

          // Nivel de actividad
          Text(
            'Nivel de actividad física',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          ...ActivityLevel.values.map((level) {
            final isSelected = _activityLevel == level;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => setState(() => _activityLevel = level),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: isSelected
                        ? theme.colorScheme.primary.withAlpha(20)
                        : null,
                  ),
                  child: Row(
                    children: [
                      // Indicador de selección
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : Colors.grey.shade400,
                            width: 2,
                          ),
                          color: isSelected
                              ? theme.colorScheme.primary
                              : Colors.transparent,
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                size: 16,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              level.displayName,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              level.description,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
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
          }),
        ],
      ),
    );
  }

  Widget _buildNumberInput({
    required ThemeData theme,
    required String label,
    required double? value,
    required String unit,
    required IconData icon,
    required void Function(double?) onChanged,
    required double min,
    required double max,
  }) {
    final controller = TextEditingController(
      text: value?.toStringAsFixed(1) ?? '',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            prefixIcon: Icon(icon),
            suffixText: unit,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          onChanged: (text) {
            final parsed = double.tryParse(text);
            if (parsed != null && parsed >= min && parsed <= max) {
              onChanged(parsed);
            } else if (text.isEmpty) {
              onChanged(null);
            }
          },
        ),
      ],
    );
  }

  Widget _buildGoalsStep(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tu Meta Nutricional',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '¿Cuál es tu objetivo principal?',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),

          ...NutritionGoal.values.map((goal) {
            final isSelected = _nutritionGoal == goal;
            final IconData icon;
            final Color color;

            switch (goal) {
              case NutritionGoal.loseWeight:
                icon = Icons.trending_down;
                color = Colors.blue;
                break;
              case NutritionGoal.maintain:
                icon = Icons.balance;
                color = Colors.green;
                break;
              case NutritionGoal.gainMuscle:
                icon = Icons.fitness_center;
                color = Colors.orange;
                break;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: InkWell(
                onTap: () => setState(() => _nutritionGoal = goal),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected ? color : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    color: isSelected ? color.withAlpha(20) : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: color.withAlpha(30),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: color, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              goal.displayName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              goal.description,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected) Icon(Icons.check_circle, color: color),
                    ],
                  ),
                ),
              ),
            );
          }),

          // Mostrar calorías calculadas si hay datos
          if (_nutritionGoal != null && _calculateCalorieTarget() != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.local_fire_department,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tu meta calórica diaria',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '${_calculateCalorieTarget()} kcal',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          if (_currentPage > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousPage,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Anterior'),
              ),
            ),
          if (_currentPage > 0) const SizedBox(width: 16),
          Expanded(
            flex: _currentPage > 0 ? 1 : 2,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(_currentPage < 2 ? 'Siguiente' : 'Completar'),
            ),
          ),
        ],
      ),
    );
  }
}

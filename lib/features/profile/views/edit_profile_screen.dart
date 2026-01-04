// ╔═══════════════════════════════════════════════════════════════════════════════╗
// ║                         edit_profile_screen.dart                              ║
// ║               Pantalla para editar el perfil de usuario                       ║
// ╠═══════════════════════════════════════════════════════════════════════════════╣
// ║  Permite al usuario modificar sus datos personales, físicos y nutricionales.  ║
// ║  Los cambios se guardan en Firebase Firestore.                                ║
// ╚═══════════════════════════════════════════════════════════════════════════════╝

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/routes.dart';
import '../../../data/models/user_profile.dart';
import '../../auth/providers/auth_provider.dart';

/// Pantalla para editar el perfil del usuario.
///
/// Permite modificar:
/// - Nombre para mostrar
/// - Datos personales (fecha de nacimiento, género, ubicación)
/// - Datos físicos (peso, altura, nivel de actividad)
/// - Meta nutricional y calorías objetivo
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _hasChanges = false;

  // Controllers
  late TextEditingController _displayNameController;
  late TextEditingController _countryController;
  late TextEditingController _cityController;
  late TextEditingController _weightController;
  late TextEditingController _heightController;
  late TextEditingController _caloriesController;

  // Form values
  DateTime? _birthDate;
  Gender? _gender;
  ActivityLevel? _activityLevel;
  NutritionGoal? _nutritionGoal;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    final profile = ref.read(currentUserProfileProvider);

    _displayNameController = TextEditingController(
      text: profile?.displayName ?? '',
    );
    _countryController = TextEditingController(text: profile?.country ?? '');
    _cityController = TextEditingController(text: profile?.city ?? '');
    _weightController = TextEditingController(
      text: profile?.weightKg?.toStringAsFixed(1) ?? '',
    );
    _heightController = TextEditingController(
      text: profile?.heightCm?.toStringAsFixed(1) ?? '',
    );
    _caloriesController = TextEditingController(
      text: profile?.dailyCalorieTarget?.toString() ?? '',
    );

    _birthDate = profile?.birthDate;
    _gender = profile?.gender;
    _activityLevel = profile?.activityLevel;
    _nutritionGoal = profile?.nutritionGoal;

    // Listeners para detectar cambios
    _displayNameController.addListener(_onFieldChanged);
    _countryController.addListener(_onFieldChanged);
    _cityController.addListener(_onFieldChanged);
    _weightController.addListener(_onFieldChanged);
    _heightController.addListener(_onFieldChanged);
    _caloriesController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _countryController.dispose();
    _cityController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final currentProfile = ref.read(currentUserProfileProvider);
    if (currentProfile == null) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Error: No se encontró el perfil');
      return;
    }

    // Parsear valores numéricos
    final weight = double.tryParse(_weightController.text);
    final height = double.tryParse(_heightController.text);
    final calories = int.tryParse(_caloriesController.text);

    // Crear perfil actualizado
    final updatedProfile = currentProfile.copyWith(
      displayName: _displayNameController.text.trim(),
      birthDate: _birthDate,
      gender: _gender,
      country: _countryController.text.trim().isNotEmpty
          ? _countryController.text.trim()
          : null,
      city: _cityController.text.trim().isNotEmpty
          ? _cityController.text.trim()
          : null,
      weightKg: weight,
      heightCm: height,
      activityLevel: _activityLevel,
      nutritionGoal: _nutritionGoal,
      dailyCalorieTarget: calories ?? _calculateCalorieTarget(),
      clearCountry: _countryController.text.trim().isEmpty,
      clearCity: _cityController.text.trim().isEmpty,
    );

    final authNotifier = ref.read(authStateProvider.notifier);
    final result = await authNotifier.updateProfile(updatedProfile);

    if (!mounted) return;

    setState(() => _isLoading = false);

    result.when(
      success: (_) {
        _showSuccessSnackBar('Perfil actualizado correctamente');
        context.goBackOrHome();
      },
      failure: (message, _) {
        _showErrorSnackBar(message);
      },
    );
  }

  int? _calculateCalorieTarget() {
    final weight = double.tryParse(_weightController.text);
    final height = double.tryParse(_heightController.text);

    if (weight == null ||
        height == null ||
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
    final baseTmb = 10 * weight + 6.25 * height - 5 * age;
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

  void _showSuccessSnackBar(String message) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: theme.colorScheme.onPrimary),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: theme.colorScheme.primary,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: theme.colorScheme.onError),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: theme.colorScheme.error,
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Descartar cambios?'),
        content: const Text(
          'Tienes cambios sin guardar. ¿Estás seguro de que quieres salir?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final inputFillColor = isDark
        ? theme.colorScheme.surfaceContainerHighest
        : Colors.grey.shade50;

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          context.goBackOrHome();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Volver',
            onPressed: () async {
              if (_hasChanges) {
                final shouldPop = await _onWillPop();
                if (shouldPop && context.mounted) {
                  context.goBackOrHome();
                }
              } else {
                context.goBackOrHome();
              }
            },
          ),
          title: const Text('Editar Perfil'),
          actions: [
            TextButton(
              onPressed: _isLoading || !_hasChanges ? null : _saveProfile,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      'Guardar',
                      style: TextStyle(
                        color: _hasChanges
                            ? theme.colorScheme.primary
                            : Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ═══════════════════════════════════════════════════════════════
              // DATOS BÁSICOS
              // ═══════════════════════════════════════════════════════════════
              _buildSectionHeader(theme, 'Datos Básicos', Icons.person_outline),
              const SizedBox(height: 16),

              // Nombre
              TextFormField(
                controller: _displayNameController,
                decoration: InputDecoration(
                  labelText: 'Nombre para mostrar',
                  prefixIcon: const Icon(Icons.badge_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: inputFillColor,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El nombre es requerido';
                  }
                  if (value.trim().length < 2) {
                    return 'El nombre debe tener al menos 2 caracteres';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 32),

              // ═══════════════════════════════════════════════════════════════
              // DATOS PERSONALES
              // ═══════════════════════════════════════════════════════════════
              _buildSectionHeader(
                  theme, 'Datos Personales', Icons.account_circle_outlined),
              const SizedBox(height: 16),

              // Fecha de nacimiento
              _buildDatePicker(theme),
              const SizedBox(height: 16),

              // Género
              _buildGenderSelector(theme),
              const SizedBox(height: 16),

              // Pais
              TextFormField(
                controller: _countryController,
                decoration: InputDecoration(
                  labelText: 'Pais',
                  prefixIcon: const Icon(Icons.public),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: inputFillColor,
                ),
              ),
              const SizedBox(height: 16),

              // Ciudad
              TextFormField(
                controller: _cityController,
                decoration: InputDecoration(
                  labelText: 'Ciudad',
                  prefixIcon: const Icon(Icons.location_city),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: inputFillColor,
                ),
              ),

              const SizedBox(height: 32),

              // ═══════════════════════════════════════════════════════════════
              // DATOS FÍSICOS
              // ═══════════════════════════════════════════════════════════════
              _buildSectionHeader(
                  theme, 'Datos Físicos', Icons.fitness_center_outlined),
              const SizedBox(height: 16),

              // Peso y Altura en fila
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _weightController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Peso',
                        suffixText: 'kg',
                        prefixIcon: const Icon(Icons.monitor_weight_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: inputFillColor,
                      ),
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final weight = double.tryParse(value);
                          if (weight == null || weight < 20 || weight > 300) {
                            return '20-300 kg';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _heightController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Altura',
                        suffixText: 'cm',
                        prefixIcon: const Icon(Icons.height),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: inputFillColor,
                      ),
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final height = double.tryParse(value);
                          if (height == null || height < 100 || height > 250) {
                            return '100-250 cm';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Nivel de actividad
              _buildActivityLevelSelector(theme),

              const SizedBox(height: 32),

              // ═══════════════════════════════════════════════════════════════
              // META NUTRICIONAL
              // ═══════════════════════════════════════════════════════════════
              _buildSectionHeader(
                  theme, 'Meta Nutricional', Icons.restaurant_outlined),
              const SizedBox(height: 16),

              // Meta
              _buildNutritionGoalSelector(theme),
              const SizedBox(height: 16),

              // Calorias objetivo
              TextFormField(
                controller: _caloriesController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Calorias diarias objetivo',
                  suffixText: 'kcal',
                  prefixIcon: const Icon(Icons.local_fire_department),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: inputFillColor,
                  helperText: _calculateCalorieTarget() != null
                      ? 'Sugerido: ${_calculateCalorieTarget()} kcal'
                      : null,
                ),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final calories = int.tryParse(value);
                    if (calories == null ||
                        calories < 1000 ||
                        calories > 5000) {
                      return '1000-5000 kcal';
                    }
                  }
                  return null;
                },
              ),

              // Botón para calcular calorías automáticamente
              if (_calculateCalorieTarget() != null) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () {
                    final suggested = _calculateCalorieTarget();
                    if (suggested != null) {
                      _caloriesController.text = suggested.toString();
                      _onFieldChanged();
                    }
                  },
                  icon: const Icon(Icons.calculate),
                  label: const Text('Usar calorías sugeridas'),
                ),
              ],

              const SizedBox(height: 32),

              // ═══════════════════════════════════════════════════════════════
              // BOTÓN GUARDAR
              // ═══════════════════════════════════════════════════════════════
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading || !_hasChanges ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Guardar Cambios',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final inputFillColor = isDark
        ? theme.colorScheme.surfaceContainerHighest
        : Colors.grey.shade50;
    final placeholderColor = theme.colorScheme.onSurfaceVariant;

    return InkWell(
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
          setState(() {
            _birthDate = date;
            _hasChanges = true;
          });
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Fecha de nacimiento',
          prefixIcon: const Icon(Icons.calendar_today),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: inputFillColor,
        ),
        child: Text(
          _birthDate != null
              ? '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}'
              : 'Seleccionar fecha',
          style: TextStyle(
            color: _birthDate != null ? null : placeholderColor,
          ),
        ),
      ),
    );
  }

  Widget _buildGenderSelector(ThemeData theme) {
    final secondaryTextColor = theme.colorScheme.onSurfaceVariant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Genero',
          style: theme.textTheme.bodySmall?.copyWith(
            color: secondaryTextColor,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: Gender.values.map((gender) {
            final isSelected = _gender == gender;
            return ChoiceChip(
              label: Text(gender.displayName),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _gender = selected ? gender : null;
                  _hasChanges = true;
                });
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
    );
  }

  Widget _buildActivityLevelSelector(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final secondaryTextColor = theme.colorScheme.onSurfaceVariant;
    final borderColor =
        isDark ? theme.colorScheme.outline : Colors.grey.shade300;
    final unselectedRadioColor =
        isDark ? theme.colorScheme.outline : Colors.grey.shade400;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nivel de actividad fisica',
          style: theme.textTheme.bodySmall?.copyWith(
            color: secondaryTextColor,
          ),
        ),
        const SizedBox(height: 8),
        ...ActivityLevel.values.map((level) {
          final isSelected = _activityLevel == level;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () {
                setState(() {
                  _activityLevel = level;
                  _hasChanges = true;
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected ? theme.colorScheme.primary : borderColor,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: isSelected
                      ? theme.colorScheme.primary.withAlpha(20)
                      : null,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : unselectedRadioColor,
                          width: 2,
                        ),
                        color: isSelected
                            ? theme.colorScheme.primary
                            : Colors.transparent,
                      ),
                      child: isSelected
                          ? Icon(
                              Icons.check,
                              size: 12,
                              color: theme.colorScheme.onPrimary,
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
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            level.description,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: secondaryTextColor,
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
    );
  }

  Widget _buildNutritionGoalSelector(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final secondaryTextColor = theme.colorScheme.onSurfaceVariant;
    final borderColor =
        isDark ? theme.colorScheme.outline : Colors.grey.shade300;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tu objetivo',
          style: theme.textTheme.bodySmall?.copyWith(
            color: secondaryTextColor,
          ),
        ),
        const SizedBox(height: 8),
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
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () {
                setState(() {
                  _nutritionGoal = goal;
                  _hasChanges = true;
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected ? color : borderColor,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: isSelected ? color.withAlpha(20) : null,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color.withAlpha(30),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: color, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            goal.displayName,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            goal.description,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check_circle, color: color, size: 24),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ╔═══════════════════════════════════════════════════════════════════════════════╗
// ║                           user_profile.dart                                   ║
// ║                    Modelo de perfil de usuario                                ║
// ╠═══════════════════════════════════════════════════════════════════════════════╣
// ║  Representa el perfil completo de un usuario de la aplicación.                ║
// ║  Incluye datos personales, físicos, nutricionales y metadata.                 ║
// ║  Soporta serialización JSON para Firebase Firestore.                          ║
// ╚═══════════════════════════════════════════════════════════════════════════════╝

import 'package:flutter/foundation.dart';

/// Perfil completo de usuario para la aplicación NutriVision.
///
/// Contiene:
/// - Datos de identificación (id, email)
/// - Datos personales (nombre, foto, fecha de nacimiento, género, ubicación)
/// - Datos físicos (peso, altura, nivel de actividad)
/// - Datos nutricionales (meta, calorías objetivo)
/// - Metadata (fechas de creación/actualización, estado de onboarding)
///
/// Ejemplo de uso:
/// ```dart
/// final profile = UserProfile(
///   id: 'user123',
///   email: 'user@example.com',
///   displayName: 'Juan Pérez',
///   createdAt: DateTime.now(),
///   updatedAt: DateTime.now(),
/// );
/// ```
@immutable
class UserProfile {
  // ═══════════════════════════════════════════════════════════════════════════
  // IDENTIFICACIÓN
  // ═══════════════════════════════════════════════════════════════════════════

  /// ID único del usuario (Firebase Auth UID)
  final String id;

  /// Email del usuario (único)
  final String email;

  // ═══════════════════════════════════════════════════════════════════════════
  // DATOS BÁSICOS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Nombre para mostrar del usuario
  final String displayName;

  /// URL de la foto de perfil (Firebase Storage)
  final String? photoUrl;

  // ═══════════════════════════════════════════════════════════════════════════
  // DATOS PERSONALES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Fecha de nacimiento
  final DateTime? birthDate;

  /// Género del usuario
  final Gender? gender;

  /// País de residencia
  final String? country;

  /// Ciudad de residencia
  final String? city;

  // ═══════════════════════════════════════════════════════════════════════════
  // DATOS FÍSICOS Y NUTRICIONALES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Peso en kilogramos
  final double? weightKg;

  /// Altura en centímetros
  final double? heightCm;

  /// Nivel de actividad física
  final ActivityLevel? activityLevel;

  /// Meta nutricional del usuario
  final NutritionGoal? nutritionGoal;

  /// Meta de calorías diarias
  final int? dailyCalorieTarget;

  // ═══════════════════════════════════════════════════════════════════════════
  // METADATA
  // ═══════════════════════════════════════════════════════════════════════════

  /// Fecha de creación del perfil
  final DateTime createdAt;

  /// Fecha de última actualización
  final DateTime updatedAt;

  /// Indica si el usuario completó el onboarding
  final bool onboardingCompleted;

  // ═══════════════════════════════════════════════════════════════════════════
  // CONSTRUCTOR
  // ═══════════════════════════════════════════════════════════════════════════

  /// Crea una nueva instancia de UserProfile.
  ///
  /// [id] y [email] son requeridos para identificación.
  /// [displayName] es requerido para mostrar en la UI.
  /// [createdAt] y [updatedAt] son requeridos para metadata.
  const UserProfile({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.birthDate,
    this.gender,
    this.country,
    this.city,
    this.weightKg,
    this.heightCm,
    this.activityLevel,
    this.nutritionGoal,
    this.dailyCalorieTarget,
    required this.createdAt,
    required this.updatedAt,
    this.onboardingCompleted = false,
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // FACTORY CONSTRUCTORS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Crea un perfil nuevo con valores por defecto.
  ///
  /// Útil para crear un perfil inicial después del registro.
  factory UserProfile.newUser({
    required String id,
    required String email,
    required String displayName,
  }) {
    final now = DateTime.now();
    return UserProfile(
      id: id,
      email: email,
      displayName: displayName,
      createdAt: now,
      updatedAt: now,
      onboardingCompleted: false,
    );
  }

  /// Crea un UserProfile desde un Map (Firestore).
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String? ?? 'Usuario',
      photoUrl: json['photoUrl'] as String?,
      birthDate: json['birthDate'] != null
          ? DateTime.parse(json['birthDate'] as String)
          : null,
      gender: json['gender'] != null
          ? Gender.fromString(json['gender'] as String)
          : null,
      country: json['country'] as String?,
      city: json['city'] as String?,
      weightKg: (json['weightKg'] as num?)?.toDouble(),
      heightCm: (json['heightCm'] as num?)?.toDouble(),
      activityLevel: json['activityLevel'] != null
          ? ActivityLevel.fromString(json['activityLevel'] as String)
          : null,
      nutritionGoal: json['nutritionGoal'] != null
          ? NutritionGoal.fromString(json['nutritionGoal'] as String)
          : null,
      dailyCalorieTarget: json['dailyCalorieTarget'] as int?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
      onboardingCompleted: json['onboardingCompleted'] as bool? ?? false,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PROPIEDADES CALCULADAS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Edad del usuario en años (basada en birthDate).
  int? get age {
    if (birthDate == null) return null;
    final now = DateTime.now();
    int years = now.year - birthDate!.year;
    if (now.month < birthDate!.month ||
        (now.month == birthDate!.month && now.day < birthDate!.day)) {
      years--;
    }
    return years;
  }

  /// Índice de Masa Corporal (IMC).
  /// Fórmula: peso (kg) / altura (m)²
  double? get bmi {
    if (weightKg == null || heightCm == null || heightCm! <= 0) return null;
    final heightM = heightCm! / 100;
    return weightKg! / (heightM * heightM);
  }

  /// Categoría del IMC.
  BmiCategory? get bmiCategory {
    final imc = bmi;
    if (imc == null) return null;
    if (imc < 18.5) return BmiCategory.underweight;
    if (imc < 25) return BmiCategory.normal;
    if (imc < 30) return BmiCategory.overweight;
    return BmiCategory.obese;
  }

  /// Tasa Metabólica Basal (TMB) usando la fórmula Mifflin-St Jeor.
  /// Hombres: TMB = 10*peso + 6.25*altura - 5*edad + 5
  /// Mujeres: TMB = 10*peso + 6.25*altura - 5*edad - 161
  double? get bmr {
    if (weightKg == null || heightCm == null || age == null || gender == null) {
      return null;
    }
    final base = 10 * weightKg! + 6.25 * heightCm! - 5 * age!;
    return gender == Gender.male ? base + 5 : base - 161;
  }

  /// Gasto Energético Total Estimado (TDEE).
  /// TMB × factor de actividad
  double? get tdee {
    final basalRate = bmr;
    if (basalRate == null || activityLevel == null) return null;
    return basalRate * activityLevel!.multiplier;
  }

  /// Calorías recomendadas según la meta nutricional.
  int? get recommendedCalories {
    final totalExpenditure = tdee;
    if (totalExpenditure == null || nutritionGoal == null) return null;

    switch (nutritionGoal!) {
      case NutritionGoal.loseWeight:
        return (totalExpenditure * 0.80).round(); // -20%
      case NutritionGoal.maintain:
        return totalExpenditure.round();
      case NutritionGoal.gainMuscle:
        return (totalExpenditure * 1.15).round(); // +15%
    }
  }

  /// Indica si el perfil tiene datos personales completos.
  bool get hasPersonalData =>
      birthDate != null && gender != null && country != null;

  /// Indica si el perfil tiene datos físicos completos.
  bool get hasPhysicalData =>
      weightKg != null && heightCm != null && activityLevel != null;

  /// Indica si el perfil tiene datos nutricionales configurados.
  bool get hasNutritionData =>
      nutritionGoal != null && dailyCalorieTarget != null;

  /// Indica si el perfil está completo para usar todas las funcionalidades.
  bool get isProfileComplete =>
      hasPersonalData && hasPhysicalData && hasNutritionData;

  /// Porcentaje de completitud del perfil (0-100).
  int get profileCompletionPercent {
    int completed = 0;
    int total = 10; // Total de campos opcionales importantes

    if (photoUrl != null) completed++;
    if (birthDate != null) completed++;
    if (gender != null) completed++;
    if (country != null) completed++;
    if (city != null) completed++;
    if (weightKg != null) completed++;
    if (heightCm != null) completed++;
    if (activityLevel != null) completed++;
    if (nutritionGoal != null) completed++;
    if (dailyCalorieTarget != null) completed++;

    return ((completed / total) * 100).round();
  }

  /// Iniciales del nombre para avatar placeholder.
  String get initials {
    final parts = displayName.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts.last[0]}'.toUpperCase();
  }

  /// Nombre de la ubicación formateado.
  String? get locationFormatted {
    if (city != null && country != null) return '$city, $country';
    return city ?? country;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Crea una copia del perfil con valores modificados.
  UserProfile copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    DateTime? birthDate,
    Gender? gender,
    String? country,
    String? city,
    double? weightKg,
    double? heightCm,
    ActivityLevel? activityLevel,
    NutritionGoal? nutritionGoal,
    int? dailyCalorieTarget,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? onboardingCompleted,
    bool clearPhotoUrl = false,
    bool clearBirthDate = false,
    bool clearGender = false,
    bool clearCountry = false,
    bool clearCity = false,
    bool clearWeightKg = false,
    bool clearHeightCm = false,
    bool clearActivityLevel = false,
    bool clearNutritionGoal = false,
    bool clearDailyCalorieTarget = false,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: clearPhotoUrl ? null : (photoUrl ?? this.photoUrl),
      birthDate: clearBirthDate ? null : (birthDate ?? this.birthDate),
      gender: clearGender ? null : (gender ?? this.gender),
      country: clearCountry ? null : (country ?? this.country),
      city: clearCity ? null : (city ?? this.city),
      weightKg: clearWeightKg ? null : (weightKg ?? this.weightKg),
      heightCm: clearHeightCm ? null : (heightCm ?? this.heightCm),
      activityLevel:
          clearActivityLevel ? null : (activityLevel ?? this.activityLevel),
      nutritionGoal:
          clearNutritionGoal ? null : (nutritionGoal ?? this.nutritionGoal),
      dailyCalorieTarget: clearDailyCalorieTarget
          ? null
          : (dailyCalorieTarget ?? this.dailyCalorieTarget),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    );
  }

  /// Convierte el perfil a un Map para Firestore.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'birthDate': birthDate?.toIso8601String(),
      'gender': gender?.name,
      'country': country,
      'city': city,
      'weightKg': weightKg,
      'heightCm': heightCm,
      'activityLevel': activityLevel?.name,
      'nutritionGoal': nutritionGoal?.name,
      'dailyCalorieTarget': dailyCalorieTarget,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'onboardingCompleted': onboardingCompleted,
    };
  }

  @override
  String toString() {
    return 'UserProfile(id: $id, email: $email, displayName: $displayName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProfile && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// ═══════════════════════════════════════════════════════════════════════════════
// ENUMS
// ═══════════════════════════════════════════════════════════════════════════════

/// Género del usuario.
enum Gender {
  /// Masculino
  male,

  /// Femenino
  female,

  /// Otro
  other,

  /// Prefiere no decir
  preferNotToSay;

  /// Nombre para mostrar en español.
  String get displayName {
    switch (this) {
      case Gender.male:
        return 'Masculino';
      case Gender.female:
        return 'Femenino';
      case Gender.other:
        return 'Otro';
      case Gender.preferNotToSay:
        return 'Prefiero no decir';
    }
  }

  /// Crea un Gender desde un string.
  static Gender? fromString(String value) {
    switch (value.toLowerCase()) {
      case 'male':
        return Gender.male;
      case 'female':
        return Gender.female;
      case 'other':
        return Gender.other;
      case 'prefernotosay':
      case 'prefer_not_to_say':
        return Gender.preferNotToSay;
      default:
        return null;
    }
  }
}

/// Meta nutricional del usuario.
enum NutritionGoal {
  /// Perder peso
  loseWeight,

  /// Mantener peso
  maintain,

  /// Ganar masa muscular
  gainMuscle;

  /// Nombre para mostrar en español.
  String get displayName {
    switch (this) {
      case NutritionGoal.loseWeight:
        return 'Perder peso';
      case NutritionGoal.maintain:
        return 'Mantener peso';
      case NutritionGoal.gainMuscle:
        return 'Ganar músculo';
    }
  }

  /// Descripción de la meta.
  String get description {
    switch (this) {
      case NutritionGoal.loseWeight:
        return 'Déficit calórico para reducir grasa corporal';
      case NutritionGoal.maintain:
        return 'Balance calórico para mantener tu peso actual';
      case NutritionGoal.gainMuscle:
        return 'Superávit calórico para aumentar masa muscular';
    }
  }

  /// Crea un NutritionGoal desde un string.
  static NutritionGoal? fromString(String value) {
    switch (value.toLowerCase()) {
      case 'loseweight':
      case 'lose_weight':
        return NutritionGoal.loseWeight;
      case 'maintain':
        return NutritionGoal.maintain;
      case 'gainmuscle':
      case 'gain_muscle':
        return NutritionGoal.gainMuscle;
      default:
        return null;
    }
  }
}

/// Nivel de actividad física.
enum ActivityLevel {
  /// Sedentario (poco o ningún ejercicio)
  sedentary,

  /// Ligeramente activo (ejercicio ligero 1-3 días/semana)
  light,

  /// Moderadamente activo (ejercicio moderado 3-5 días/semana)
  moderate,

  /// Activo (ejercicio intenso 6-7 días/semana)
  active,

  /// Muy activo (ejercicio muy intenso, trabajo físico)
  veryActive;

  /// Nombre para mostrar en español.
  String get displayName {
    switch (this) {
      case ActivityLevel.sedentary:
        return 'Sedentario';
      case ActivityLevel.light:
        return 'Ligeramente activo';
      case ActivityLevel.moderate:
        return 'Moderadamente activo';
      case ActivityLevel.active:
        return 'Activo';
      case ActivityLevel.veryActive:
        return 'Muy activo';
    }
  }

  /// Descripción del nivel de actividad.
  String get description {
    switch (this) {
      case ActivityLevel.sedentary:
        return 'Poco o ningún ejercicio';
      case ActivityLevel.light:
        return 'Ejercicio ligero 1-3 días/semana';
      case ActivityLevel.moderate:
        return 'Ejercicio moderado 3-5 días/semana';
      case ActivityLevel.active:
        return 'Ejercicio intenso 6-7 días/semana';
      case ActivityLevel.veryActive:
        return 'Ejercicio muy intenso o trabajo físico';
    }
  }

  /// Multiplicador para calcular TDEE.
  double get multiplier {
    switch (this) {
      case ActivityLevel.sedentary:
        return 1.2;
      case ActivityLevel.light:
        return 1.375;
      case ActivityLevel.moderate:
        return 1.55;
      case ActivityLevel.active:
        return 1.725;
      case ActivityLevel.veryActive:
        return 1.9;
    }
  }

  /// Crea un ActivityLevel desde un string.
  static ActivityLevel? fromString(String value) {
    switch (value.toLowerCase()) {
      case 'sedentary':
        return ActivityLevel.sedentary;
      case 'light':
        return ActivityLevel.light;
      case 'moderate':
        return ActivityLevel.moderate;
      case 'active':
        return ActivityLevel.active;
      case 'veryactive':
      case 'very_active':
        return ActivityLevel.veryActive;
      default:
        return null;
    }
  }
}

/// Categoría del Índice de Masa Corporal.
enum BmiCategory {
  /// Bajo peso (IMC < 18.5)
  underweight,

  /// Normal (IMC 18.5-24.9)
  normal,

  /// Sobrepeso (IMC 25-29.9)
  overweight,

  /// Obesidad (IMC >= 30)
  obese;

  /// Nombre para mostrar en español.
  String get displayName {
    switch (this) {
      case BmiCategory.underweight:
        return 'Bajo peso';
      case BmiCategory.normal:
        return 'Normal';
      case BmiCategory.overweight:
        return 'Sobrepeso';
      case BmiCategory.obese:
        return 'Obesidad';
    }
  }

  /// Rango de IMC de esta categoría.
  String get range {
    switch (this) {
      case BmiCategory.underweight:
        return '< 18.5';
      case BmiCategory.normal:
        return '18.5 - 24.9';
      case BmiCategory.overweight:
        return '25 - 29.9';
      case BmiCategory.obese:
        return '>= 30';
    }
  }
}

// ╔═══════════════════════════════════════════════════════════════════════════════╗
// ║                         nutrients_per_100g.dart                               ║
// ║                 Modelo de nutrientes por 100g de alimento                     ║
// ╠═══════════════════════════════════════════════════════════════════════════════╣
// ║  Representa los macronutrientes principales basados en USDA FoodData Central. ║
// ║  Incluye operadores para suma y multiplicación de nutrientes.                 ║
// ╚═══════════════════════════════════════════════════════════════════════════════╝

import 'package:flutter/foundation.dart';

/// Nutrientes por 100 gramos de alimento.
///
/// Basado en la estructura de USDA FoodData Central, contiene:
/// - Energía (kcal)
/// - Proteínas (g)
/// - Grasas (g)
/// - Carbohidratos (g)
/// - Fibra (g)
/// - Azúcares (g)
///
/// Ejemplo de uso:
/// ```dart
/// final tomato = NutrientsPer100g(
///   energyKcal: 20.0,
///   proteinG: 0.82,
///   fatG: 0.31,
///   carbohydratesG: 4.04,
///   fiberG: 1.2,
///   sugarsG: 2.63,
/// );
///
/// // Sumar nutrientes de dos ingredientes
/// final combined = tomato + cheese;
///
/// // Calcular para 150g de porción
/// final portion = tomato * 1.5;
/// ```
@immutable
class NutrientsPer100g {
  // ═══════════════════════════════════════════════════════════════════════════
  // PROPIEDADES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Energía en kilocalorías
  final double energyKcal;

  /// Proteínas en gramos
  final double proteinG;

  /// Grasas totales en gramos
  final double fatG;

  /// Carbohidratos totales en gramos
  final double carbohydratesG;

  /// Fibra dietética en gramos
  final double fiberG;

  /// Azúcares totales en gramos
  final double sugarsG;

  // ═══════════════════════════════════════════════════════════════════════════
  // CONSTRUCTORES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Crea una instancia con valores específicos.
  const NutrientsPer100g({
    required this.energyKcal,
    required this.proteinG,
    required this.fatG,
    required this.carbohydratesG,
    required this.fiberG,
    required this.sugarsG,
  });

  /// Crea una instancia con todos los valores en cero.
  ///
  /// Útil como valor inicial para acumulación.
  const NutrientsPer100g.zero()
      : energyKcal = 0,
        proteinG = 0,
        fatG = 0,
        carbohydratesG = 0,
        fiberG = 0,
        sugarsG = 0;

  /// Crea una instancia desde un Map JSON.
  ///
  /// Espera las claves del formato FDC:
  /// - energy_kcal
  /// - protein_g
  /// - fat_g
  /// - carbohydrates_g
  /// - fiber_g
  /// - sugars_g
  factory NutrientsPer100g.fromJson(Map<String, dynamic> json) {
    return NutrientsPer100g(
      energyKcal: (json['energy_kcal'] as num?)?.toDouble() ?? 0,
      proteinG: (json['protein_g'] as num?)?.toDouble() ?? 0,
      fatG: (json['fat_g'] as num?)?.toDouble() ?? 0,
      carbohydratesG: (json['carbohydrates_g'] as num?)?.toDouble() ?? 0,
      fiberG: (json['fiber_g'] as num?)?.toDouble() ?? 0,
      sugarsG: (json['sugars_g'] as num?)?.toDouble() ?? 0,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // OPERADORES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Suma los nutrientes de dos instancias.
  ///
  /// Útil para calcular el total de múltiples ingredientes.
  NutrientsPer100g operator +(NutrientsPer100g other) {
    return NutrientsPer100g(
      energyKcal: energyKcal + other.energyKcal,
      proteinG: proteinG + other.proteinG,
      fatG: fatG + other.fatG,
      carbohydratesG: carbohydratesG + other.carbohydratesG,
      fiberG: fiberG + other.fiberG,
      sugarsG: sugarsG + other.sugarsG,
    );
  }

  /// Multiplica todos los nutrientes por un factor.
  ///
  /// Útil para ajustar por tamaño de porción:
  /// - factor 1.5 = 150g de porción
  /// - factor 0.5 = 50g de porción
  NutrientsPer100g operator *(double factor) {
    return NutrientsPer100g(
      energyKcal: energyKcal * factor,
      proteinG: proteinG * factor,
      fatG: fatG * factor,
      carbohydratesG: carbohydratesG * factor,
      fiberG: fiberG * factor,
      sugarsG: sugarsG * factor,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PROPIEDADES CALCULADAS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Total de macronutrientes (proteínas + grasas + carbohidratos) en gramos.
  double get totalMacros => proteinG + fatG + carbohydratesG;

  /// Porcentaje de calorías provenientes de proteínas.
  ///
  /// Proteínas aportan 4 kcal/g.
  double get proteinCaloriePercent {
    if (energyKcal == 0) return 0;
    return (proteinG * 4 / energyKcal) * 100;
  }

  /// Porcentaje de calorías provenientes de grasas.
  ///
  /// Grasas aportan 9 kcal/g.
  double get fatCaloriePercent {
    if (energyKcal == 0) return 0;
    return (fatG * 9 / energyKcal) * 100;
  }

  /// Porcentaje de calorías provenientes de carbohidratos.
  ///
  /// Carbohidratos aportan 4 kcal/g.
  double get carbsCaloriePercent {
    if (energyKcal == 0) return 0;
    return (carbohydratesG * 4 / energyKcal) * 100;
  }

  /// Indica si todos los valores son cero.
  bool get isEmpty =>
      energyKcal == 0 &&
      proteinG == 0 &&
      fatG == 0 &&
      carbohydratesG == 0 &&
      fiberG == 0 &&
      sugarsG == 0;

  /// Indica si tiene al menos un valor mayor a cero.
  bool get isNotEmpty => !isEmpty;

  // ═══════════════════════════════════════════════════════════════════════════
  // SERIALIZACIÓN
  // ═══════════════════════════════════════════════════════════════════════════

  /// Convierte a Map JSON con formato FDC.
  Map<String, dynamic> toJson() {
    return {
      'energy_kcal': energyKcal,
      'protein_g': proteinG,
      'fat_g': fatG,
      'carbohydrates_g': carbohydratesG,
      'fiber_g': fiberG,
      'sugars_g': sugarsG,
    };
  }

  /// Crea una copia con valores modificados.
  NutrientsPer100g copyWith({
    double? energyKcal,
    double? proteinG,
    double? fatG,
    double? carbohydratesG,
    double? fiberG,
    double? sugarsG,
  }) {
    return NutrientsPer100g(
      energyKcal: energyKcal ?? this.energyKcal,
      proteinG: proteinG ?? this.proteinG,
      fatG: fatG ?? this.fatG,
      carbohydratesG: carbohydratesG ?? this.carbohydratesG,
      fiberG: fiberG ?? this.fiberG,
      sugarsG: sugarsG ?? this.sugarsG,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FORMATEO
  // ═══════════════════════════════════════════════════════════════════════════

  /// Formatea los nutrientes como string legible.
  String toFormattedString() {
    return '''
Calorías: ${energyKcal.toStringAsFixed(0)} kcal
Proteínas: ${proteinG.toStringAsFixed(1)} g
Grasas: ${fatG.toStringAsFixed(1)} g
Carbohidratos: ${carbohydratesG.toStringAsFixed(1)} g
Fibra: ${fiberG.toStringAsFixed(1)} g
Azúcares: ${sugarsG.toStringAsFixed(1)} g''';
  }

  /// Formatea como string compacto (una línea).
  String toCompactString() {
    return '${energyKcal.toStringAsFixed(0)} kcal | '
        'P: ${proteinG.toStringAsFixed(1)}g | '
        'G: ${fatG.toStringAsFixed(1)}g | '
        'C: ${carbohydratesG.toStringAsFixed(1)}g';
  }

  @override
  String toString() => 'NutrientsPer100g(${toCompactString()})';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NutrientsPer100g &&
        other.energyKcal == energyKcal &&
        other.proteinG == proteinG &&
        other.fatG == fatG &&
        other.carbohydratesG == carbohydratesG &&
        other.fiberG == fiberG &&
        other.sugarsG == sugarsG;
  }

  @override
  int get hashCode {
    return Object.hash(
      energyKcal,
      proteinG,
      fatG,
      carbohydratesG,
      fiberG,
      sugarsG,
    );
  }
}

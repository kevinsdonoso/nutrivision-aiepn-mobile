// ╔═══════════════════════════════════════════════════════════════════════════════╗
// ║                           nutrition_info.dart                                 ║
// ║              Modelo de información nutricional de un alimento                 ║
// ╠═══════════════════════════════════════════════════════════════════════════════╣
// ║  Representa la información nutricional completa de un ingrediente o plato.   ║
// ║  Incluye datos de FoodData Central y status de coincidencia.                  ║
// ╚═══════════════════════════════════════════════════════════════════════════════╝

import 'package:flutter/foundation.dart';

import 'nutrients_per_100g.dart';

/// Estado de la información nutricional.
enum NutritionStatus {
  /// Encontrado con alta coincidencia (>= 80%)
  found,

  /// Encontrado con baja coincidencia (< 80%)
  lowScore,

  /// No encontrado en la base de datos
  notFound,
}

/// Extensión para NutritionStatus.
extension NutritionStatusExtension on NutritionStatus {
  /// Nombre legible del estado.
  String get displayName {
    switch (this) {
      case NutritionStatus.found:
        return 'Encontrado';
      case NutritionStatus.lowScore:
        return 'Coincidencia baja';
      case NutritionStatus.notFound:
        return 'No encontrado';
    }
  }

  /// Indica si tiene datos nutricionales disponibles.
  bool get hasData => this != NutritionStatus.notFound;
}

/// Información nutricional completa de un alimento.
///
/// Contiene:
/// - Identificación del alimento (label, fdcId, fdcDescription)
/// - Score de coincidencia con FoodData Central
/// - Estado de búsqueda (found, lowScore, notFound)
/// - Nutrientes por 100g
/// - Componentes (solo para platos)
///
/// Ejemplo de uso:
/// ```dart
/// final tomato = NutritionInfo(
///   label: 'tomate',
///   fdcId: 2709719,
///   fdcDescription: 'Tomatoes, raw',
///   matchScore: 91.7,
///   status: NutritionStatus.found,
///   isDish: false,
///   nutrients: NutrientsPer100g(...),
/// );
///
/// print('${tomato.displayLabel}: ${tomato.matchScoreFormatted}');
/// ```
@immutable
class NutritionInfo {
  // ═══════════════════════════════════════════════════════════════════════════
  // CONSTANTES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Umbral para considerar alta coincidencia
  static const double highMatchThreshold = 80.0;

  /// Umbral para considerar coincidencia media
  static const double mediumMatchThreshold = 60.0;

  // ═══════════════════════════════════════════════════════════════════════════
  // PROPIEDADES DE IDENTIFICACIÓN
  // ═══════════════════════════════════════════════════════════════════════════

  /// Etiqueta original del ingrediente/plato (en español).
  ///
  /// Ejemplo: 'tomate', 'ceviche', 'queso_mozzarella'
  final String label;

  /// ID en USDA FoodData Central.
  ///
  /// Puede ser null si no se encontró coincidencia.
  final int? fdcId;

  /// Descripción en FoodData Central (en inglés).
  ///
  /// Ejemplo: 'Tomatoes, raw'
  final String? fdcDescription;

  // ═══════════════════════════════════════════════════════════════════════════
  // PROPIEDADES DE COINCIDENCIA
  // ═══════════════════════════════════════════════════════════════════════════

  /// Score de coincidencia con la base de datos (0-100).
  ///
  /// - >= 80: Alta coincidencia
  /// - 60-80: Coincidencia media
  /// - < 60: Baja coincidencia
  final double matchScore;

  /// Estado de la búsqueda nutricional.
  final NutritionStatus status;

  // ═══════════════════════════════════════════════════════════════════════════
  // PROPIEDADES DE TIPO
  // ═══════════════════════════════════════════════════════════════════════════

  /// Indica si es un plato compuesto (true) o ingrediente simple (false).
  final bool isDish;

  /// Nutrientes por 100g del alimento.
  final NutrientsPer100g nutrients;

  /// Componentes del plato con sus porcentajes.
  ///
  /// Solo aplica si [isDish] es true.
  /// Ejemplo: {'tomate': 40, 'queso_mozzarella': 35, 'albahaca': 5}
  final Map<String, int>? components;

  /// Componentes faltantes en la base de datos.
  ///
  /// Solo aplica si [isDish] es true.
  final List<String>? missingComponents;

  // ═══════════════════════════════════════════════════════════════════════════
  // CONSTRUCTORES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Crea una instancia con todos los datos.
  const NutritionInfo({
    required this.label,
    this.fdcId,
    this.fdcDescription,
    required this.matchScore,
    required this.status,
    required this.isDish,
    required this.nutrients,
    this.components,
    this.missingComponents,
  });

  /// Crea una instancia para un alimento no encontrado.
  const NutritionInfo.notFound(this.label)
      : fdcId = null,
        fdcDescription = null,
        matchScore = 0,
        status = NutritionStatus.notFound,
        isDish = false,
        nutrients = const NutrientsPer100g.zero(),
        components = null,
        missingComponents = null;

  /// Crea una instancia desde JSON de un ingrediente.
  factory NutritionInfo.fromJsonIngredient(
    String label,
    Map<String, dynamic> json,
  ) {
    final statusStr = json['status'] as String? ?? 'not_found';
    final status = _parseStatus(statusStr);

    return NutritionInfo(
      label: label,
      fdcId: json['fdc_id'] as int?,
      fdcDescription: json['fdc_description'] as String?,
      matchScore: (json['match_score'] as num?)?.toDouble() ?? 0,
      status: status,
      isDish: false,
      nutrients: json['nutrients_per_100g'] != null
          ? NutrientsPer100g.fromJson(
              json['nutrients_per_100g'] as Map<String, dynamic>,
            )
          : const NutrientsPer100g.zero(),
    );
  }

  /// Crea una instancia desde JSON de un plato.
  factory NutritionInfo.fromJsonDish(
    String label,
    Map<String, dynamic> json,
  ) {
    // Parsear componentes
    Map<String, int>? components;
    if (json['components'] != null) {
      final rawComponents = json['components'] as Map<String, dynamic>;
      components = rawComponents.map(
        (key, value) => MapEntry(key, (value as num).toInt()),
      );
    }

    // Parsear componentes faltantes
    List<String>? missingComponents;
    if (json['missing_components'] != null) {
      missingComponents = (json['missing_components'] as List).cast<String>();
    }

    return NutritionInfo(
      label: label,
      fdcId: null,
      fdcDescription: null,
      matchScore: 100, // Platos calculados siempre tienen 100%
      status: NutritionStatus.found,
      isDish: true,
      nutrients: json['nutrients_per_100g'] != null
          ? NutrientsPer100g.fromJson(
              json['nutrients_per_100g'] as Map<String, dynamic>,
            )
          : const NutrientsPer100g.zero(),
      components: components,
      missingComponents: missingComponents,
    );
  }

  /// Parsea el status desde string.
  static NutritionStatus _parseStatus(String status) {
    switch (status.toLowerCase()) {
      case 'found':
        return NutritionStatus.found;
      case 'low_score':
        return NutritionStatus.lowScore;
      case 'not_found':
      default:
        return NutritionStatus.notFound;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PROPIEDADES CALCULADAS - COINCIDENCIA
  // ═══════════════════════════════════════════════════════════════════════════

  /// Indica si tiene alta coincidencia (>= 80%).
  bool get isHighMatch => matchScore >= highMatchThreshold;

  /// Indica si tiene coincidencia media (60% - 80%).
  bool get isMediumMatch =>
      matchScore >= mediumMatchThreshold && matchScore < highMatchThreshold;

  /// Indica si tiene baja coincidencia (< 60%).
  bool get isLowMatch => matchScore < mediumMatchThreshold;

  /// Score de coincidencia formateado.
  String get matchScoreFormatted => '${matchScore.toStringAsFixed(0)}%';

  /// Indica si tiene datos nutricionales disponibles.
  bool get hasNutritionData => status != NutritionStatus.notFound;

  // ═══════════════════════════════════════════════════════════════════════════
  // PROPIEDADES CALCULADAS - DISPLAY
  // ═══════════════════════════════════════════════════════════════════════════

  /// Etiqueta formateada para mostrar en UI.
  ///
  /// Convierte 'queso_mozzarella' a 'Queso Mozzarella'.
  String get displayLabel {
    return label
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
            : '')
        .join(' ');
  }

  /// Tipo de alimento como string.
  String get typeLabel => isDish ? 'Plato' : 'Ingrediente';

  /// Número de componentes (solo para platos).
  int get componentCount => components?.length ?? 0;

  /// Lista de nombres de componentes (solo para platos).
  List<String> get componentNames => components?.keys.toList() ?? [];

  // ═══════════════════════════════════════════════════════════════════════════
  // SERIALIZACIÓN
  // ═══════════════════════════════════════════════════════════════════════════

  /// Convierte a Map JSON.
  Map<String, dynamic> toJson() {
    return {
      'label': label,
      if (fdcId != null) 'fdc_id': fdcId,
      if (fdcDescription != null) 'fdc_description': fdcDescription,
      'match_score': matchScore,
      'status': status.name,
      'is_dish': isDish,
      'nutrients_per_100g': nutrients.toJson(),
      if (components != null) 'components': components,
      if (missingComponents != null) 'missing_components': missingComponents,
    };
  }

  /// Crea una copia con valores modificados.
  NutritionInfo copyWith({
    String? label,
    int? fdcId,
    String? fdcDescription,
    double? matchScore,
    NutritionStatus? status,
    bool? isDish,
    NutrientsPer100g? nutrients,
    Map<String, int>? components,
    List<String>? missingComponents,
  }) {
    return NutritionInfo(
      label: label ?? this.label,
      fdcId: fdcId ?? this.fdcId,
      fdcDescription: fdcDescription ?? this.fdcDescription,
      matchScore: matchScore ?? this.matchScore,
      status: status ?? this.status,
      isDish: isDish ?? this.isDish,
      nutrients: nutrients ?? this.nutrients,
      components: components ?? this.components,
      missingComponents: missingComponents ?? this.missingComponents,
    );
  }

  @override
  String toString() {
    return 'NutritionInfo($label: $matchScoreFormatted, '
        '${nutrients.energyKcal.toStringAsFixed(0)} kcal)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NutritionInfo &&
        other.label == label &&
        other.fdcId == fdcId &&
        other.matchScore == matchScore &&
        other.status == status &&
        other.isDish == isDish;
  }

  @override
  int get hashCode {
    return Object.hash(label, fdcId, matchScore, status, isDish);
  }
}

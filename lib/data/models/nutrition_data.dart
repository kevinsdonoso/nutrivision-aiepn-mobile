// ╔═══════════════════════════════════════════════════════════════════════════════╗
// ║                           nutrition_data.dart                                 ║
// ║             Contenedor de datos nutricionales desde JSON                      ║
// ╠═══════════════════════════════════════════════════════════════════════════════╣
// ║  Contiene todos los datos nutricionales cargados desde el archivo JSON.       ║
// ║  Incluye metadata, ingredientes y platos.                                     ║
// ╚═══════════════════════════════════════════════════════════════════════════════╝

import 'package:flutter/foundation.dart';

import 'nutrition_info.dart';

/// Metadata del archivo de datos nutricionales.
@immutable
class NutritionMetadata {
  /// Versión del formato de datos.
  final String version;

  /// Fecha de generación del archivo.
  final DateTime generated;

  /// Fuente de los datos (e.g., 'USDA FoodData Central').
  final String source;

  /// URL del API de origen.
  final String? apiUrl;

  /// Número de ingredientes en la base de datos.
  final int numIngredients;

  /// Número de platos en la base de datos.
  final int numDishes;

  /// Número total de alimentos.
  final int numTotal;

  /// Lista de nutrientes incluidos.
  final List<String> nutrientsIncluded;

  /// Score promedio de coincidencia.
  final double avgMatchScore;

  /// Número de ingredientes encontrados.
  final int ingredientsFound;

  /// Número de ingredientes no encontrados.
  final int ingredientsNotFound;

  const NutritionMetadata({
    required this.version,
    required this.generated,
    required this.source,
    this.apiUrl,
    required this.numIngredients,
    required this.numDishes,
    required this.numTotal,
    required this.nutrientsIncluded,
    required this.avgMatchScore,
    required this.ingredientsFound,
    required this.ingredientsNotFound,
  });

  /// Crea desde JSON.
  factory NutritionMetadata.fromJson(Map<String, dynamic> json) {
    final stats = json['stats'] as Map<String, dynamic>? ?? {};

    return NutritionMetadata(
      version: json['version'] as String? ?? '1.0',
      generated: DateTime.tryParse(json['generated'] as String? ?? '') ??
          DateTime.now(),
      source: json['source'] as String? ?? 'Unknown',
      apiUrl: json['api_url'] as String?,
      numIngredients: json['num_ingredients'] as int? ?? 0,
      numDishes: json['num_dishes'] as int? ?? 0,
      numTotal: json['num_total'] as int? ?? 0,
      nutrientsIncluded: (json['nutrients_included'] as List?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      avgMatchScore: (stats['avg_match_score'] as num?)?.toDouble() ?? 0,
      ingredientsFound: stats['ingredients_found'] as int? ?? 0,
      ingredientsNotFound: stats['ingredients_not_found'] as int? ?? 0,
    );
  }

  /// Convierte a JSON.
  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'generated': generated.toIso8601String(),
      'source': source,
      if (apiUrl != null) 'api_url': apiUrl,
      'num_ingredients': numIngredients,
      'num_dishes': numDishes,
      'num_total': numTotal,
      'nutrients_included': nutrientsIncluded,
      'stats': {
        'avg_match_score': avgMatchScore,
        'ingredients_found': ingredientsFound,
        'ingredients_not_found': ingredientsNotFound,
      },
    };
  }

  @override
  String toString() {
    return 'NutritionMetadata(v$version: $numIngredients ingredientes, '
        '$numDishes platos)';
  }
}

/// Contenedor de todos los datos nutricionales.
///
/// Carga y almacena toda la información del archivo nutrition_fdc.json.
///
/// Ejemplo de uso:
/// ```dart
/// final data = NutritionData.fromJson(jsonMap);
///
/// // Buscar por etiqueta
/// final tomato = data.getByLabel('tomate');
///
/// // Obtener todos los platos
/// final dishes = data.dishes.values.toList();
/// ```
@immutable
class NutritionData {
  /// Metadata del archivo de datos.
  final NutritionMetadata metadata;

  /// Mapa de ingredientes por etiqueta.
  final Map<String, NutritionInfo> ingredients;

  /// Mapa de platos por etiqueta.
  final Map<String, NutritionInfo> dishes;

  const NutritionData({
    required this.metadata,
    required this.ingredients,
    required this.dishes,
  });

  /// Crea desde JSON.
  factory NutritionData.fromJson(Map<String, dynamic> json) {
    // Parsear metadata
    final metadata = NutritionMetadata.fromJson(
      json['metadata'] as Map<String, dynamic>? ?? {},
    );

    // Parsear foods (estructura unificada con campo 'type')
    final foodsJson = json['foods'] as Map<String, dynamic>? ?? {};

    final ingredients = <String, NutritionInfo>{};
    final dishes = <String, NutritionInfo>{};

    for (final entry in foodsJson.entries) {
      final label = entry.key;
      final data = entry.value as Map<String, dynamic>;
      final type = data['type'] as String?;

      if (type == 'dish') {
        dishes[label] = NutritionInfo.fromJsonDish(label, data);
      } else {
        ingredients[label] = NutritionInfo.fromJsonIngredient(label, data);
      }
    }

    return NutritionData(
      metadata: metadata,
      ingredients: ingredients,
      dishes: dishes,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS DE BÚSQUEDA
  // ═══════════════════════════════════════════════════════════════════════════

  /// Busca información nutricional por etiqueta.
  ///
  /// Busca primero en ingredientes, luego en platos.
  /// Retorna null si no se encuentra.
  NutritionInfo? getByLabel(String label) {
    // Normalizar label
    final normalizedLabel = label.toLowerCase().trim();

    // Buscar en ingredientes
    if (ingredients.containsKey(normalizedLabel)) {
      return ingredients[normalizedLabel];
    }

    // Buscar en platos
    if (dishes.containsKey(normalizedLabel)) {
      return dishes[normalizedLabel];
    }

    return null;
  }

  /// Busca información de un ingrediente específico.
  NutritionInfo? getIngredient(String label) {
    return ingredients[label.toLowerCase().trim()];
  }

  /// Busca información de un plato específico.
  NutritionInfo? getDish(String label) {
    return dishes[label.toLowerCase().trim()];
  }

  /// Busca múltiples etiquetas y retorna las encontradas.
  List<NutritionInfo> getBatch(List<String> labels) {
    return labels
        .map((label) => getByLabel(label))
        .whereType<NutritionInfo>()
        .toList();
  }

  /// Verifica si existe información para una etiqueta.
  bool hasLabel(String label) {
    final normalizedLabel = label.toLowerCase().trim();
    return ingredients.containsKey(normalizedLabel) ||
        dishes.containsKey(normalizedLabel);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PROPIEDADES CALCULADAS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Todas las etiquetas disponibles (ingredientes + platos).
  List<String> get allLabels {
    return [...ingredients.keys, ...dishes.keys];
  }

  /// Número total de alimentos.
  int get totalCount => ingredients.length + dishes.length;

  /// Lista de todos los ingredientes.
  List<NutritionInfo> get allIngredients => ingredients.values.toList();

  /// Lista de todos los platos.
  List<NutritionInfo> get allDishes => dishes.values.toList();

  /// Lista de todos los alimentos.
  List<NutritionInfo> get allFoods => [...allIngredients, ...allDishes];

  /// Ingredientes con alta coincidencia.
  List<NutritionInfo> get highMatchIngredients {
    return ingredients.values.where((i) => i.isHighMatch).toList();
  }

  /// Ingredientes con baja coincidencia.
  List<NutritionInfo> get lowMatchIngredients {
    return ingredients.values.where((i) => i.isLowMatch).toList();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ESTADÍSTICAS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Obtiene estadísticas de los datos.
  NutritionDataStats get stats => NutritionDataStats.fromData(this);

  @override
  String toString() {
    return 'NutritionData(${ingredients.length} ingredientes, '
        '${dishes.length} platos)';
  }
}

/// Estadísticas de los datos nutricionales.
@immutable
class NutritionDataStats {
  final int totalIngredients;
  final int totalDishes;
  final int highMatchCount;
  final int lowMatchCount;
  final int notFoundCount;
  final double averageMatchScore;

  const NutritionDataStats({
    required this.totalIngredients,
    required this.totalDishes,
    required this.highMatchCount,
    required this.lowMatchCount,
    required this.notFoundCount,
    required this.averageMatchScore,
  });

  factory NutritionDataStats.fromData(NutritionData data) {
    final allIngredients = data.ingredients.values.toList();

    int highMatch = 0;
    int lowMatch = 0;
    int notFound = 0;
    double totalScore = 0;

    for (final ingredient in allIngredients) {
      totalScore += ingredient.matchScore;
      if (ingredient.status == NutritionStatus.notFound) {
        notFound++;
      } else if (ingredient.isHighMatch) {
        highMatch++;
      } else {
        lowMatch++;
      }
    }

    return NutritionDataStats(
      totalIngredients: allIngredients.length,
      totalDishes: data.dishes.length,
      highMatchCount: highMatch,
      lowMatchCount: lowMatch,
      notFoundCount: notFound,
      averageMatchScore:
          allIngredients.isNotEmpty ? totalScore / allIngredients.length : 0,
    );
  }

  int get totalFoods => totalIngredients + totalDishes;

  @override
  String toString() {
    return 'NutritionDataStats('
        '$totalIngredients ingredientes, '
        '$totalDishes platos, '
        'avg: ${averageMatchScore.toStringAsFixed(1)}%)';
  }
}

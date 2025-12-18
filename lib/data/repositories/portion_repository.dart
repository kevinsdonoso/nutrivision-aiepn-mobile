// ╔═══════════════════════════════════════════════════════════════════════════════╗
// ║                         portion_repository.dart                               ║
// ║              Repositorio de porciones estándar                                ║
// ╠═══════════════════════════════════════════════════════════════════════════════╣
// ║  Proporciona acceso a las porciones estándar de ingredientes.                 ║
// ║  Cache en memoria para optimizar rendimiento.                                 ║
// ╚═══════════════════════════════════════════════════════════════════════════════╝

import '../datasources/portion_datasource.dart';
import '../models/ingredient_quantity.dart';
import '../models/standard_portion.dart';

/// Repositorio para gestionar porciones estándar de ingredientes.
///
/// Proporciona métodos para obtener porciones disponibles por ingrediente
/// y convertir porciones a gramos.
///
/// Ejemplo de uso:
/// ```dart
/// final repository = PortionRepository();
/// await repository.initialize();
///
/// final portions = repository.getPortionsForIngredient('tomate');
/// print('Porciones disponibles: ${portions.length}');
///
/// final grams = repository.convertPortionToGrams('tomate', '1 unidad mediana');
/// print('1 unidad mediana = $grams g');
/// ```
class PortionRepository {
  // ═══════════════════════════════════════════════════════════════════════════
  // PROPIEDADES
  // ═══════════════════════════════════════════════════════════════════════════

  final PortionDatasource _datasource;

  /// Cache de porciones cargadas
  Map<String, List<StandardPortion>>? _cachedPortions;

  /// Indica si el repositorio ha sido inicializado
  bool _isInitialized = false;

  // ═══════════════════════════════════════════════════════════════════════════
  // CONSTRUCTORES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Crea una instancia del repositorio.
  ///
  /// [datasource] opcional para testing. Por defecto usa PortionDatasource().
  PortionRepository({PortionDatasource? datasource})
      : _datasource = datasource ?? PortionDatasource();

  // ═══════════════════════════════════════════════════════════════════════════
  // INICIALIZACIÓN
  // ═══════════════════════════════════════════════════════════════════════════

  /// Inicializa el repositorio cargando los datos de porciones.
  ///
  /// Debe llamarse antes de usar otros métodos.
  Future<void> initialize() async {
    if (_isInitialized) return;

    _cachedPortions = await _datasource.loadPortionData();
    _isInitialized = true;
  }

  /// Asegura que el repositorio esté inicializado.
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CONSULTAS DE PORCIONES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Obtiene las porciones estándar disponibles para un ingrediente.
  ///
  /// Retorna una lista vacía si el ingrediente no tiene porciones definidas.
  ///
  /// Ejemplo:
  /// ```dart
  /// final portions = repository.getPortionsForIngredient('tomate');
  /// // [StandardPortion(...), StandardPortion(...)]
  /// ```
  Future<List<StandardPortion>> getPortionsForIngredient(String label) async {
    await _ensureInitialized();
    return _cachedPortions?[label] ?? [];
  }

  /// Verifica si un ingrediente tiene porciones estándar definidas.
  Future<bool> hasPortions(String label) async {
    await _ensureInitialized();
    final portions = _cachedPortions?[label];
    return portions != null && portions.isNotEmpty;
  }

  /// Obtiene el número de porciones disponibles para un ingrediente.
  Future<int> getPortionCount(String label) async {
    await _ensureInitialized();
    return _cachedPortions?[label]?.length ?? 0;
  }

  /// Obtiene todos los ingredientes que tienen porciones definidas.
  Future<List<String>> getAvailableIngredients() async {
    await _ensureInitialized();
    return _cachedPortions?.keys.toList() ?? [];
  }

  /// Obtiene el total de ingredientes con porciones.
  Future<int> getTotalIngredientsWithPortions() async {
    await _ensureInitialized();
    return _cachedPortions?.length ?? 0;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CONVERSIÓN DE PORCIONES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Convierte una porción estándar a gramos.
  ///
  /// Retorna null si el ingrediente o la porción no existen.
  ///
  /// Ejemplo:
  /// ```dart
  /// final grams = repository.convertPortionToGrams(
  ///   'tomate',
  ///   '1 unidad mediana',
  /// );
  /// print(grams); // 150.0
  /// ```
  Future<double?> convertPortionToGrams(
    String ingredientLabel,
    String portionName,
  ) async {
    await _ensureInitialized();

    final portions = _cachedPortions?[ingredientLabel];
    if (portions == null) return null;

    try {
      final portion = portions.firstWhere((p) => p.name == portionName);
      return portion.grams;
    } catch (_) {
      return null;
    }
  }

  /// Busca una porción específica por nombre.
  ///
  /// Retorna null si no se encuentra.
  Future<StandardPortion?> findPortion(
    String ingredientLabel,
    String portionName,
  ) async {
    await _ensureInitialized();

    final portions = _cachedPortions?[ingredientLabel];
    if (portions == null) return null;

    try {
      return portions.firstWhere((p) => p.name == portionName);
    } catch (_) {
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CREACIÓN DE CANTIDADES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Crea un IngredientQuantity desde una porción seleccionada.
  ///
  /// Retorna null si la porción no existe.
  Future<IngredientQuantity?> createQuantityFromPortion(
    String ingredientLabel,
    String portionName,
  ) async {
    final portion = await findPortion(ingredientLabel, portionName);
    if (portion == null) return null;

    return IngredientQuantity.fromPortion(
      label: ingredientLabel,
      portion: portion,
    );
  }

  /// Crea cantidades por defecto (100g) para una lista de ingredientes.
  Future<Map<String, IngredientQuantity>> createDefaultQuantities(
    List<String> ingredientLabels,
  ) async {
    final result = <String, IngredientQuantity>{};

    for (final label in ingredientLabels) {
      result[label] = IngredientQuantity.defaultValue(label);
    }

    return result;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UTILIDADES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Obtiene estadísticas de las porciones cargadas.
  Future<PortionStats> getStats() async {
    await _ensureInitialized();

    if (_cachedPortions == null) {
      return PortionStats(
        totalIngredients: 0,
        totalPortions: 0,
        avgPortionsPerIngredient: 0,
      );
    }

    final totalIngredients = _cachedPortions!.length;
    final totalPortions =
        _cachedPortions!.values.fold<int>(0, (sum, portions) => sum + portions.length);
    final avgPortionsPerIngredient =
        totalIngredients > 0 ? (totalPortions / totalIngredients).toDouble() : 0.0;

    return PortionStats(
      totalIngredients: totalIngredients,
      totalPortions: totalPortions,
      avgPortionsPerIngredient: avgPortionsPerIngredient,
    );
  }

  /// Limpia el cache y marca el repositorio como no inicializado.
  ///
  /// Útil para testing o para forzar recarga de datos.
  void reset() {
    _cachedPortions = null;
    _isInitialized = false;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ACCESO A DATOS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Indica si el repositorio está inicializado.
  bool get isInitialized => _isInitialized;

  /// Total de ingredientes con porciones (solo si está inicializado).
  int get totalIngredients => _cachedPortions?.length ?? 0;
}

/// Estadísticas de porciones estándar.
class PortionStats {
  /// Total de ingredientes con porciones definidas
  final int totalIngredients;

  /// Total de porciones en la base de datos
  final int totalPortions;

  /// Promedio de porciones por ingrediente
  final double avgPortionsPerIngredient;

  const PortionStats({
    required this.totalIngredients,
    required this.totalPortions,
    required this.avgPortionsPerIngredient,
  });

  @override
  String toString() {
    return 'PortionStats('
        'ingredientes: $totalIngredients, '
        'porciones: $totalPortions, '
        'promedio: ${avgPortionsPerIngredient.toStringAsFixed(1)}'
        ')';
  }
}

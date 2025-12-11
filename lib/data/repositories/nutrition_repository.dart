// ╔═══════════════════════════════════════════════════════════════════════════════╗
// ║                         nutrition_repository.dart                             ║
// ║              Repositorio para acceso a datos nutricionales                    ║
// ╠═══════════════════════════════════════════════════════════════════════════════╣
// ║  Proporciona métodos de alto nivel para consultar información nutricional.   ║
// ║  Implementa caching y lazy loading para optimizar rendimiento.                ║
// ╚═══════════════════════════════════════════════════════════════════════════════╝

import '../../core/logging/app_logger.dart';
import '../datasources/nutrition_datasource.dart';
import '../models/detection.dart';
import '../models/nutrition_data.dart';
import '../models/nutrition_info.dart';
import '../models/nutrients_per_100g.dart';

/// Repositorio para acceso a datos nutricionales.
///
/// Implementa lazy loading: los datos se cargan solo cuando se necesitan
/// por primera vez y se mantienen en caché.
///
/// Ejemplo de uso:
/// ```dart
/// final repo = NutritionRepository(NutritionDatasource());
/// await repo.initialize();
///
/// final tomato = await repo.getNutrition('tomate');
/// print('Calorías: ${tomato?.nutrients.energyKcal}');
/// ```
class NutritionRepository {
  // ═══════════════════════════════════════════════════════════════════════════
  // PROPIEDADES
  // ═══════════════════════════════════════════════════════════════════════════

  final NutritionDatasource _datasource;

  /// Datos cacheados (null si no han sido cargados).
  NutritionData? _cachedData;

  /// Indica si está inicializado.
  bool _initialized = false;

  // ═══════════════════════════════════════════════════════════════════════════
  // CONSTRUCTOR
  // ═══════════════════════════════════════════════════════════════════════════

  NutritionRepository(this._datasource);

  // ═══════════════════════════════════════════════════════════════════════════
  // INICIALIZACIÓN
  // ═══════════════════════════════════════════════════════════════════════════

  /// Indica si el repositorio está inicializado.
  bool get isInitialized => _initialized;

  /// Inicializa el repositorio cargando los datos.
  ///
  /// Es seguro llamar múltiples veces (no-op si ya está inicializado).
  Future<void> initialize() async {
    if (_initialized) return;

    AppLogger.debug('Inicializando NutritionRepository...', tag: 'NutritionRepo');

    _cachedData = await _datasource.loadNutritionData();
    _initialized = true;

    AppLogger.info(
      'NutritionRepository inicializado: '
      '${_cachedData!.ingredients.length} ingredientes, '
      '${_cachedData!.dishes.length} platos',
      tag: 'NutritionRepo',
    );
  }

  /// Asegura que el repositorio esté inicializado.
  ///
  /// Llama a [initialize] si es necesario.
  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await initialize();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CONSULTAS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Obtiene información nutricional por etiqueta.
  ///
  /// Busca en ingredientes y platos.
  /// Retorna null si no se encuentra.
  Future<NutritionInfo?> getNutrition(String label) async {
    await _ensureInitialized();
    return _cachedData?.getByLabel(label);
  }

  /// Obtiene información nutricional de múltiples etiquetas.
  ///
  /// Solo retorna las que se encontraron.
  Future<List<NutritionInfo>> getNutritionBatch(List<String> labels) async {
    await _ensureInitialized();
    return _cachedData?.getBatch(labels) ?? [];
  }

  /// Obtiene información nutricional de un ingrediente específico.
  Future<NutritionInfo?> getIngredient(String label) async {
    await _ensureInitialized();
    return _cachedData?.getIngredient(label);
  }

  /// Obtiene información nutricional de un plato específico.
  Future<NutritionInfo?> getDish(String label) async {
    await _ensureInitialized();
    return _cachedData?.getDish(label);
  }

  /// Verifica si existe información para una etiqueta.
  Future<bool> hasNutrition(String label) async {
    await _ensureInitialized();
    return _cachedData?.hasLabel(label) ?? false;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CÁLCULOS CON DETECCIONES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Calcula el total de nutrientes de una lista de detecciones.
  ///
  /// Suma los nutrientes de todos los ingredientes detectados.
  /// Los ingredientes no encontrados se ignoran.
  Future<NutrientsPer100g> calculateTotalNutrients(
    List<Detection> detections,
  ) async {
    await _ensureInitialized();

    var total = const NutrientsPer100g.zero();

    for (final detection in detections) {
      final nutrition = _cachedData?.getByLabel(detection.label);
      if (nutrition != null && nutrition.hasNutritionData) {
        total = total + nutrition.nutrients;
      }
    }

    return total;
  }

  /// Obtiene información nutricional para cada detección.
  ///
  /// Retorna una lista de tuplas (Detection, NutritionInfo?).
  /// NutritionInfo es null si no se encontró.
  Future<List<(Detection, NutritionInfo?)>> getDetectionsWithNutrition(
    List<Detection> detections,
  ) async {
    await _ensureInitialized();

    return detections.map((detection) {
      final nutrition = _cachedData?.getByLabel(detection.label);
      return (detection, nutrition);
    }).toList();
  }

  /// Cuenta cuántas detecciones tienen información nutricional.
  Future<int> countDetectionsWithNutrition(List<Detection> detections) async {
    await _ensureInitialized();

    return detections.where((d) {
      final nutrition = _cachedData?.getByLabel(d.label);
      return nutrition != null && nutrition.hasNutritionData;
    }).length;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ACCESO A DATOS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Metadata de los datos cargados.
  NutritionMetadata? get metadata => _cachedData?.metadata;

  /// Todas las etiquetas disponibles.
  List<String> get availableLabels => _cachedData?.allLabels ?? [];

  /// Todos los ingredientes.
  List<NutritionInfo> get allIngredients => _cachedData?.allIngredients ?? [];

  /// Todos los platos.
  List<NutritionInfo> get allDishes => _cachedData?.allDishes ?? [];

  /// Estadísticas de los datos.
  NutritionDataStats? get stats => _cachedData?.stats;

  /// Número total de alimentos.
  int get totalCount => _cachedData?.totalCount ?? 0;

  // ═══════════════════════════════════════════════════════════════════════════
  // UTILIDADES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Libera los datos cacheados.
  ///
  /// Útil para liberar memoria si no se necesitan más los datos.
  void dispose() {
    _cachedData = null;
    _initialized = false;
    AppLogger.debug('NutritionRepository disposed', tag: 'NutritionRepo');
  }

  /// Recarga los datos desde el datasource.
  ///
  /// Útil si el archivo JSON ha sido actualizado.
  Future<void> reload() async {
    _initialized = false;
    _cachedData = null;
    await initialize();
  }
}

// ╔═══════════════════════════════════════════════════════════════════════════════╗
// ║                          nutrition_service.dart                               ║
// ║                 Servicio singleton para datos nutricionales                   ║
// ╠═══════════════════════════════════════════════════════════════════════════════╣
// ║  Proporciona acceso global a información nutricional con lazy loading.        ║
// ║  Wrapper conveniente sobre NutritionRepository.                               ║
// ╚═══════════════════════════════════════════════════════════════════════════════╝

import '../../../core/logging/app_logger.dart';
import '../../../data/datasources/nutrition_datasource.dart';
import '../../../data/models/detection.dart';
import '../../../data/models/nutrition_data.dart';
import '../../../data/models/nutrition_info.dart';
import '../../../data/models/nutrients_per_100g.dart';
import '../../../data/repositories/nutrition_repository.dart';

/// Servicio singleton para acceso a datos nutricionales.
///
/// Proporciona métodos convenientes para consultar información nutricional
/// de ingredientes y platos detectados.
///
/// Ejemplo de uso:
/// ```dart
/// final service = NutritionService.instance;
/// await service.initialize();
///
/// final nutrition = await service.getNutrition('tomate');
/// print('Calorías: ${nutrition?.nutrients.energyKcal}');
/// ```
class NutritionService {
  // ═══════════════════════════════════════════════════════════════════════════
  // SINGLETON
  // ═══════════════════════════════════════════════════════════════════════════

  static NutritionService? _instance;

  /// Obtiene la instancia singleton del servicio.
  static NutritionService get instance {
    _instance ??= NutritionService._internal(
      NutritionRepository(NutritionDatasource()),
    );
    return _instance!;
  }

  /// Constructor privado para singleton.
  NutritionService._internal(this._repository);

  /// Para testing: permite inyectar un repositorio mock.
  static void setInstance(NutritionService service) {
    _instance = service;
  }

  /// Para testing: resetea la instancia singleton.
  static void resetInstance() {
    _instance?.dispose();
    _instance = null;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PROPIEDADES
  // ═══════════════════════════════════════════════════════════════════════════

  final NutritionRepository _repository;

  /// Indica si el servicio está inicializado.
  bool get isInitialized => _repository.isInitialized;

  // ═══════════════════════════════════════════════════════════════════════════
  // INICIALIZACIÓN
  // ═══════════════════════════════════════════════════════════════════════════

  /// Inicializa el servicio.
  ///
  /// Es seguro llamar múltiples veces (no-op si ya está inicializado).
  Future<void> initialize() async {
    if (isInitialized) return;

    AppLogger.info('Inicializando NutritionService...', tag: 'NutritionService');
    await _repository.initialize();
    AppLogger.info('NutritionService listo', tag: 'NutritionService');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CONSULTAS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Obtiene información nutricional por etiqueta.
  Future<NutritionInfo?> getNutrition(String label) async {
    await initialize();
    return _repository.getNutrition(label);
  }

  /// Obtiene información de múltiples etiquetas.
  Future<List<NutritionInfo>> getNutritionBatch(List<String> labels) async {
    await initialize();
    return _repository.getNutritionBatch(labels);
  }

  /// Verifica si existe información para una etiqueta.
  Future<bool> hasNutrition(String label) async {
    await initialize();
    return _repository.hasNutrition(label);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CÁLCULOS CON DETECCIONES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Calcula el total de nutrientes de detecciones.
  Future<NutrientsPer100g> calculateTotal(List<Detection> detections) async {
    await initialize();
    return _repository.calculateTotalNutrients(detections);
  }

  /// Obtiene información nutricional para cada detección.
  Future<List<(Detection, NutritionInfo?)>> getDetectionsWithNutrition(
    List<Detection> detections,
  ) async {
    await initialize();
    return _repository.getDetectionsWithNutrition(detections);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ACCESO A DATOS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Metadata de los datos cargados.
  NutritionMetadata? get metadata => _repository.metadata;

  /// Todas las etiquetas disponibles.
  List<String> get availableLabels => _repository.availableLabels;

  /// Estadísticas de los datos.
  NutritionDataStats? get stats => _repository.stats;

  /// Número total de alimentos.
  int get totalCount => _repository.totalCount;

  // ═══════════════════════════════════════════════════════════════════════════
  // CLEANUP
  // ═══════════════════════════════════════════════════════════════════════════

  /// Libera recursos.
  void dispose() {
    _repository.dispose();
  }
}

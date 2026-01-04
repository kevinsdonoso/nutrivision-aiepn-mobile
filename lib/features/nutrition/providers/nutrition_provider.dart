// ╔═══════════════════════════════════════════════════════════════════════════════╗
// ║                         nutrition_provider.dart                               ║
// ║                  Providers Riverpod para datos nutricionales                  ║
// ╠═══════════════════════════════════════════════════════════════════════════════╣
// ║  Define providers para acceder a información nutricional de forma reactiva.   ║
// ║  Integración con el sistema de detección YOLO.                                ║
// ╚═══════════════════════════════════════════════════════════════════════════════╝

// Exportar providers de cantidades para facilitar imports
export 'quantity_provider.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/datasources/nutrition_datasource.dart';
import '../../../data/models/detection.dart';
import '../../../data/models/nutrition_data.dart';
import '../../../data/models/nutrition_info.dart';
import '../../../data/models/nutrients_per_100g.dart';
import '../../../data/repositories/nutrition_repository.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// PROVIDERS BASE
// ═══════════════════════════════════════════════════════════════════════════════

/// Provider del datasource de nutrición.
final nutritionDatasourceProvider = Provider<NutritionDatasource>((ref) {
  return NutritionDatasource();
});

/// Provider del repositorio de nutrición.
final nutritionRepositoryProvider = Provider<NutritionRepository>((ref) {
  final datasource = ref.watch(nutritionDatasourceProvider);
  return NutritionRepository(datasource);
});

/// Provider para inicialización del repositorio.
///
/// Carga los datos nutricionales de forma lazy.
final nutritionInitProvider = FutureProvider<void>((ref) async {
  final repository = ref.watch(nutritionRepositoryProvider);
  await repository.initialize();
});

// ═══════════════════════════════════════════════════════════════════════════════
// PROVIDERS DE CONSULTA
// ═══════════════════════════════════════════════════════════════════════════════

/// Provider para obtener información nutricional por etiqueta.
///
/// Ejemplo:
/// ```dart
/// final nutritionAsync = ref.watch(nutritionByLabelProvider('tomate'));
/// nutritionAsync.when(
///   data: (nutrition) => ...,
///   loading: () => ...,
///   error: (e, _) => ...,
/// );
/// ```
final nutritionByLabelProvider =
    FutureProvider.family<NutritionInfo?, String>((ref, label) async {
  // Esperar inicialización
  await ref.watch(nutritionInitProvider.future);

  final repository = ref.watch(nutritionRepositoryProvider);
  return repository.getNutrition(label);
});

/// Provider para verificar si existe información nutricional.
final hasNutritionProvider =
    FutureProvider.family<bool, String>((ref, label) async {
  await ref.watch(nutritionInitProvider.future);

  final repository = ref.watch(nutritionRepositoryProvider);
  return repository.hasNutrition(label);
});

/// Provider para obtener múltiples informaciones nutricionales.
final nutritionBatchProvider =
    FutureProvider.family<List<NutritionInfo>, List<String>>(
        (ref, labels) async {
  await ref.watch(nutritionInitProvider.future);

  final repository = ref.watch(nutritionRepositoryProvider);
  return repository.getNutritionBatch(labels);
});

// ═══════════════════════════════════════════════════════════════════════════════
// PROVIDERS PARA DETECCIONES
// ═══════════════════════════════════════════════════════════════════════════════

/// Provider para calcular total de nutrientes de detecciones.
///
/// Recibe una lista de detecciones y retorna el total de nutrientes.
final totalNutrientsProvider =
    FutureProvider.family<NutrientsPer100g, List<Detection>>(
        (ref, detections) async {
  if (detections.isEmpty) {
    return const NutrientsPer100g.zero();
  }

  await ref.watch(nutritionInitProvider.future);

  final repository = ref.watch(nutritionRepositoryProvider);
  return repository.calculateTotalNutrients(detections);
});

/// Provider para obtener detecciones con su información nutricional.
final detectionsWithNutritionProvider =
    FutureProvider.family<List<(Detection, NutritionInfo?)>, List<Detection>>(
        (ref, detections) async {
  if (detections.isEmpty) {
    return [];
  }

  await ref.watch(nutritionInitProvider.future);

  final repository = ref.watch(nutritionRepositoryProvider);
  return repository.getDetectionsWithNutrition(detections);
});

/// Provider para contar detecciones con información nutricional disponible.
final detectionsWithNutritionCountProvider =
    FutureProvider.family<int, List<Detection>>((ref, detections) async {
  if (detections.isEmpty) {
    return 0;
  }

  await ref.watch(nutritionInitProvider.future);

  final repository = ref.watch(nutritionRepositoryProvider);
  return repository.countDetectionsWithNutrition(detections);
});

// ═══════════════════════════════════════════════════════════════════════════════
// PROVIDERS DE METADATA
// ═══════════════════════════════════════════════════════════════════════════════

/// Provider para obtener metadata de los datos nutricionales.
final nutritionMetadataProvider =
    FutureProvider<NutritionMetadata?>((ref) async {
  await ref.watch(nutritionInitProvider.future);

  final repository = ref.watch(nutritionRepositoryProvider);
  return repository.metadata;
});

/// Provider para obtener estadísticas de los datos.
final nutritionStatsProvider = FutureProvider<NutritionDataStats?>((ref) async {
  await ref.watch(nutritionInitProvider.future);

  final repository = ref.watch(nutritionRepositoryProvider);
  return repository.stats;
});

/// Provider para obtener todas las etiquetas disponibles.
final availableLabelsProvider = FutureProvider<List<String>>((ref) async {
  await ref.watch(nutritionInitProvider.future);

  final repository = ref.watch(nutritionRepositoryProvider);
  return repository.availableLabels;
});

/// Provider para obtener el conteo total de alimentos.
final nutritionTotalCountProvider = FutureProvider<int>((ref) async {
  await ref.watch(nutritionInitProvider.future);

  final repository = ref.watch(nutritionRepositoryProvider);
  return repository.totalCount;
});

// ═══════════════════════════════════════════════════════════════════════════════
// PROVIDERS DE LISTAS
// ═══════════════════════════════════════════════════════════════════════════════

/// Provider para obtener todos los ingredientes.
final allIngredientsProvider = FutureProvider<List<NutritionInfo>>((ref) async {
  await ref.watch(nutritionInitProvider.future);

  final repository = ref.watch(nutritionRepositoryProvider);
  return repository.allIngredients;
});

/// Provider para obtener todos los platos.
final allDishesProvider = FutureProvider<List<NutritionInfo>>((ref) async {
  await ref.watch(nutritionInitProvider.future);

  final repository = ref.watch(nutritionRepositoryProvider);
  return repository.allDishes;
});

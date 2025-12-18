// ═══════════════════════════════════════════════════════════════════════════════════════════════════════════════
// ║                              quantity_provider.dart                                                         ║
// ║                   Providers Riverpod para sistema de cantidades                                             ║
// ═══════════════════════════════════════════════════════════════════════════════════════════════════════════════
// ║  Define providers para gestionar cantidades de ingredientes y porciones.                                    ║
// ║  Incluye providers para repositorio de porciones, estado de cantidades y calculo de nutrientes.             ║
// ═══════════════════════════════════════════════════════════════════════════════════════════════════════════════

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/datasources/portion_datasource.dart';
import '../../../data/models/ingredient_quantity.dart';
import '../../../data/models/nutrients_per_100g.dart';
import '../../../data/models/standard_portion.dart';
import '../../../data/repositories/portion_repository.dart';
import '../state/ingredient_quantities_notifier.dart';
import 'nutrition_provider.dart';

// ═══════════════════════════════════════════════════════════════════════════
// PROVIDERS DE PORCIONES
// ═══════════════════════════════════════════════════════════════════════════

/// Provider del datasource de porciones.
///
/// Proporciona acceso al PortionDatasource para cargar datos de porciones.
final portionDatasourceProvider = Provider<PortionDatasource>((ref) {
  return PortionDatasource();
});

/// Provider del repositorio de porciones.
///
/// Proporciona acceso al PortionRepository para consultas de porciones.
final portionRepositoryProvider = Provider<PortionRepository>((ref) {
  final datasource = ref.watch(portionDatasourceProvider);
  return PortionRepository(datasource: datasource);
});

/// Provider de inicializacion del repositorio de porciones.
///
/// Carga los datos de porciones de forma lazy.
/// Debe esperarse antes de usar otros providers de porciones.
///
/// Ejemplo:
/// ```dart
/// final _ = await ref.watch(portionInitProvider.future);
/// final portions = await ref.watch(availablePortionsProvider('tomate').future);
/// ```
final portionInitProvider = FutureProvider<void>((ref) async {
  final repository = ref.watch(portionRepositoryProvider);
  await repository.initialize();
});

// ═══════════════════════════════════════════════════════════════════════════
// PROVIDERS DE CONSULTA DE PORCIONES
// ═══════════════════════════════════════════════════════════════════════════

/// Provider para obtener porciones disponibles de un ingrediente.
///
/// Retorna una lista de [StandardPortion] para el ingrediente especificado.
/// Retorna lista vacia si no hay porciones definidas.
///
/// Ejemplo:
/// ```dart
/// final portionsAsync = ref.watch(availablePortionsProvider('tomate'));
/// portionsAsync.when(
///   data: (portions) => ListView.builder(
///     itemCount: portions.length,
///     itemBuilder: (_, i) => Text(portions[i].displayName),
///   ),
///   loading: () => CircularProgressIndicator(),
///   error: (e, _) => Text('Error: $e'),
/// );
/// ```
final availablePortionsProvider =
    FutureProvider.family<List<StandardPortion>, String>((ref, label) async {
  // Esperar inicializacion
  await ref.watch(portionInitProvider.future);

  final repository = ref.watch(portionRepositoryProvider);
  return repository.getPortionsForIngredient(label);
});

/// Provider para verificar si un ingrediente tiene porciones disponibles.
///
/// Util para mostrar/ocultar selector de porciones en la UI.
final hasPortionsProvider =
    FutureProvider.family<bool, String>((ref, label) async {
  await ref.watch(portionInitProvider.future);

  final repository = ref.watch(portionRepositoryProvider);
  return repository.hasPortions(label);
});

/// Provider para obtener una porcion especifica.
///
/// [args] Tupla (ingredientLabel, portionName).
final findPortionProvider =
    FutureProvider.family<StandardPortion?, (String, String)>((ref, args) async {
  await ref.watch(portionInitProvider.future);

  final (ingredientLabel, portionName) = args;
  final repository = ref.watch(portionRepositoryProvider);
  return repository.findPortion(ingredientLabel, portionName);
});

/// Provider para obtener lista de ingredientes con porciones definidas.
final ingredientsWithPortionsProvider = FutureProvider<List<String>>((ref) async {
  await ref.watch(portionInitProvider.future);

  final repository = ref.watch(portionRepositoryProvider);
  return repository.getAvailableIngredients();
});

/// Provider para obtener estadisticas de porciones.
final portionStatsProvider = FutureProvider<PortionStats>((ref) async {
  await ref.watch(portionInitProvider.future);

  final repository = ref.watch(portionRepositoryProvider);
  return repository.getStats();
});

// ═══════════════════════════════════════════════════════════════════════════
// PROVIDERS DE ESTADO DE CANTIDADES
// ═══════════════════════════════════════════════════════════════════════════

/// Provider del StateNotifier para gestionar cantidades de ingredientes.
///
/// Este es el provider principal para el estado de cantidades.
/// Usa el notifier para actualizar cantidades.
///
/// Ejemplo - Leer estado:
/// ```dart
/// final state = ref.watch(ingredientQuantitiesProvider);
/// final tomatoQuantity = state.getQuantity('tomate');
/// ```
///
/// Ejemplo - Actualizar estado:
/// ```dart
/// final notifier = ref.read(ingredientQuantitiesProvider.notifier);
/// notifier.updateQuantityGrams('tomate', 150);
/// ```
final ingredientQuantitiesProvider =
    StateNotifierProvider<IngredientQuantitiesNotifier, IngredientQuantitiesState>(
  (ref) => IngredientQuantitiesNotifier(),
);

/// Provider para obtener la cantidad de un ingrediente especifico.
///
/// Retorna null si el ingrediente no tiene cantidad registrada.
///
/// Ejemplo:
/// ```dart
/// final quantity = ref.watch(singleIngredientQuantityProvider('tomate'));
/// if (quantity != null) {
///   print('Tomate: ${quantity.grams}g');
/// }
/// ```
final singleIngredientQuantityProvider =
    Provider.family<IngredientQuantity?, String>((ref, label) {
  final state = ref.watch(ingredientQuantitiesProvider);
  return state.getQuantity(label);
});

/// Provider para obtener todas las cantidades como lista.
///
/// Util para iterar sobre todas las cantidades.
final allQuantitiesListProvider = Provider<List<IngredientQuantity>>((ref) {
  final state = ref.watch(ingredientQuantitiesProvider);
  return state.allQuantities;
});

/// Provider para obtener el total de gramos de todos los ingredientes.
final totalGramsProvider = Provider<double>((ref) {
  final state = ref.watch(ingredientQuantitiesProvider);
  return state.totalGrams;
});

/// Provider para obtener el numero de ingredientes con cantidad.
final quantitiesCountProvider = Provider<int>((ref) {
  final state = ref.watch(ingredientQuantitiesProvider);
  return state.count;
});

// ═══════════════════════════════════════════════════════════════════════════
// PROVIDERS DE CALCULO DE NUTRIENTES CON CANTIDADES
// ═══════════════════════════════════════════════════════════════════════════

/// Provider para calcular el total de nutrientes usando las cantidades actuales.
///
/// Este provider combina el estado de cantidades con el repositorio de nutricion
/// para calcular el total de nutrientes considerando las cantidades especificadas.
///
/// Diferencia con [totalNutrientsProvider]:
/// - [totalNutrientsProvider] asume 100g por cada deteccion
/// - [totalNutrientsWithQuantitiesProvider] usa las cantidades reales del estado
///
/// Ejemplo:
/// ```dart
/// final nutrientsAsync = ref.watch(totalNutrientsWithQuantitiesProvider);
/// nutrientsAsync.when(
///   data: (nutrients) => Column(
///     children: [
///       Text('Calorias: ${nutrients.energyKcal.toStringAsFixed(0)} kcal'),
///       Text('Proteinas: ${nutrients.proteinG.toStringAsFixed(1)} g'),
///     ],
///   ),
///   loading: () => CircularProgressIndicator(),
///   error: (e, _) => Text('Error: $e'),
/// );
/// ```
final totalNutrientsWithQuantitiesProvider =
    FutureProvider<NutrientsPer100g>((ref) async {
  // Obtener estado actual de cantidades
  final state = ref.watch(ingredientQuantitiesProvider);

  // Si no hay cantidades, retornar cero
  if (state.isEmpty) {
    return const NutrientsPer100g.zero();
  }

  // Esperar inicializacion de nutricion
  await ref.watch(nutritionInitProvider.future);

  // Obtener repositorio y calcular
  final repository = ref.watch(nutritionRepositoryProvider);
  return repository.calculateTotalNutrientsWithQuantities(state.allQuantities);
});

/// Provider para calcular nutrientes de cantidades especificas.
///
/// A diferencia de [totalNutrientsWithQuantitiesProvider], este provider
/// permite especificar una lista arbitraria de cantidades.
///
/// [quantities] Lista de cantidades a calcular.
final nutrientsForQuantitiesProvider =
    FutureProvider.family<NutrientsPer100g, List<IngredientQuantity>>(
        (ref, quantities) async {
  if (quantities.isEmpty) {
    return const NutrientsPer100g.zero();
  }

  await ref.watch(nutritionInitProvider.future);

  final repository = ref.watch(nutritionRepositoryProvider);
  return repository.calculateTotalNutrientsWithQuantities(quantities);
});

/// Provider para calcular nutrientes de un solo ingrediente con cantidad.
///
/// Util para mostrar nutrientes individuales ajustados por cantidad.
///
/// Ejemplo:
/// ```dart
/// final quantity = IngredientQuantity.fromGrams(label: 'tomate', grams: 150);
/// final nutrientsAsync = ref.watch(singleIngredientNutrientsProvider(quantity));
/// ```
final singleIngredientNutrientsProvider =
    FutureProvider.family<NutrientsPer100g, IngredientQuantity>(
        (ref, quantity) async {
  await ref.watch(nutritionInitProvider.future);

  final repository = ref.watch(nutritionRepositoryProvider);
  return repository.calculateTotalNutrientsWithQuantities([quantity]);
});

// ═══════════════════════════════════════════════════════════════════════════
// PROVIDERS DE UTILIDAD
// ═══════════════════════════════════════════════════════════════════════════

/// Provider que combina la inicializacion de nutricion y porciones.
///
/// Util para asegurar que ambos estan listos antes de usar.
final quantitySystemInitProvider = FutureProvider<void>((ref) async {
  await Future.wait([
    ref.watch(nutritionInitProvider.future),
    ref.watch(portionInitProvider.future),
  ]);
});

/// Provider para verificar si el sistema de cantidades esta listo.
final isQuantitySystemReadyProvider = Provider<bool>((ref) {
  final nutritionState = ref.watch(nutritionInitProvider);
  final portionState = ref.watch(portionInitProvider);

  return nutritionState.hasValue && portionState.hasValue;
});

/// Provider para obtener errores de inicializacion del sistema.
final quantitySystemErrorProvider = Provider<Object?>((ref) {
  final nutritionState = ref.watch(nutritionInitProvider);
  final portionState = ref.watch(portionInitProvider);

  if (nutritionState.hasError) return nutritionState.error;
  if (portionState.hasError) return portionState.error;
  return null;
});

// ═══════════════════════════════════════════════════════════════════════════════════════════════════════════════
// ║                         ingredient_quantities_notifier.dart                                                 ║
// ║               StateNotifier para gestionar cantidades de ingredientes                                       ║
// ═══════════════════════════════════════════════════════════════════════════════════════════════════════════════
// ║  Gestiona el estado de las cantidades de ingredientes detectados.                                           ║
// ║  Soporta actualización, validación y reset de cantidades.                                                   ║
// ═══════════════════════════════════════════════════════════════════════════════════════════════════════════════

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/detection.dart';
import '../../../data/models/ingredient_quantity.dart';
import '../../../data/models/quantity_enums.dart';
import '../../../data/models/standard_portion.dart';

// ═══════════════════════════════════════════════════════════════════════════
// ESTADO INMUTABLE
// ═══════════════════════════════════════════════════════════════════════════

/// Estado inmutable que contiene las cantidades de todos los ingredientes.
///
/// Usa un Map donde la clave es la etiqueta del ingrediente (label)
/// y el valor es el IngredientQuantity correspondiente.
class IngredientQuantitiesState {
  /// Mapa de cantidades por etiqueta de ingrediente.
  final Map<String, IngredientQuantity> quantities;

  const IngredientQuantitiesState({
    this.quantities = const {},
  });

  /// Estado inicial vacio.
  const IngredientQuantitiesState.initial() : quantities = const {};

  /// Crea una copia con cantidades modificadas.
  IngredientQuantitiesState copyWith({
    Map<String, IngredientQuantity>? quantities,
  }) {
    return IngredientQuantitiesState(
      quantities: quantities ?? this.quantities,
    );
  }

  /// Obtiene la cantidad para un ingrediente especifico.
  IngredientQuantity? getQuantity(String label) => quantities[label];

  /// Indica si hay cantidades registradas.
  bool get isEmpty => quantities.isEmpty;

  /// Indica si hay cantidades registradas.
  bool get isNotEmpty => quantities.isNotEmpty;

  /// Numero de ingredientes con cantidad registrada.
  int get count => quantities.length;

  /// Lista de todas las cantidades.
  List<IngredientQuantity> get allQuantities => quantities.values.toList();

  /// Lista de etiquetas de ingredientes.
  List<String> get labels => quantities.keys.toList();

  /// Total de gramos de todos los ingredientes.
  double get totalGrams {
    return quantities.values.fold(0.0, (sum, q) => sum + q.grams);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! IngredientQuantitiesState) return false;

    if (quantities.length != other.quantities.length) return false;

    for (final key in quantities.keys) {
      if (quantities[key] != other.quantities[key]) return false;
    }

    return true;
  }

  @override
  int get hashCode => Object.hashAll(quantities.entries);

  @override
  String toString() {
    return 'IngredientQuantitiesState(count: $count, total: ${totalGrams.toStringAsFixed(0)}g)';
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// STATE NOTIFIER
// ═══════════════════════════════════════════════════════════════════════════

/// Notifier para gestionar el estado de cantidades de ingredientes.
///
/// Proporciona metodos para:
/// - Actualizar cantidades individuales
/// - Establecer cantidades desde detecciones
/// - Resetear a valores por defecto
/// - Remover ingredientes
///
/// Ejemplo de uso:
/// ```dart
/// final notifier = ref.read(ingredientQuantitiesProvider.notifier);
///
/// // Actualizar cantidad en gramos
/// notifier.updateQuantityGrams('tomate', 150);
///
/// // Actualizar desde porcion
/// notifier.updateQuantityFromPortion('tomate', portion);
///
/// // Establecer desde detecciones
/// notifier.setFromDetections(detections);
/// ```
class IngredientQuantitiesNotifier
    extends StateNotifier<IngredientQuantitiesState> {
  IngredientQuantitiesNotifier() : super(const IngredientQuantitiesState.initial());

  // ═══════════════════════════════════════════════════════════════════════════
  // METODOS DE ACTUALIZACION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Actualiza la cantidad de un ingrediente en gramos.
  ///
  /// [label] Etiqueta del ingrediente.
  /// [grams] Cantidad en gramos (debe estar entre 1g y 10kg).
  ///
  /// Throws [ArgumentError] si los gramos estan fuera del rango permitido.
  void updateQuantityGrams(String label, double grams) {
    _validateGrams(grams);

    final newQuantity = IngredientQuantity.fromGrams(
      label: label,
      grams: grams,
      source: QuantitySource.manual,
    );

    final newQuantities = Map<String, IngredientQuantity>.from(state.quantities);
    newQuantities[label] = newQuantity;

    state = state.copyWith(quantities: newQuantities);
  }

  /// Actualiza la cantidad de un ingrediente desde una porcion estandar.
  ///
  /// [label] Etiqueta del ingrediente.
  /// [portion] Porcion estandar seleccionada.
  void updateQuantityFromPortion(String label, StandardPortion portion) {
    final newQuantity = IngredientQuantity.fromPortion(
      label: label,
      portion: portion,
      source: QuantitySource.manual,
    );

    final newQuantities = Map<String, IngredientQuantity>.from(state.quantities);
    newQuantities[label] = newQuantity;

    state = state.copyWith(quantities: newQuantities);
  }

  /// Actualiza la cantidad de un ingrediente con un IngredientQuantity completo.
  ///
  /// Util cuando se necesita especificar todos los parametros.
  void updateQuantity(IngredientQuantity quantity) {
    final newQuantities = Map<String, IngredientQuantity>.from(state.quantities);
    newQuantities[quantity.label] = quantity;

    state = state.copyWith(quantities: newQuantities);
  }

  /// Actualiza multiples cantidades a la vez.
  ///
  /// [quantities] Mapa de etiqueta a cantidad.
  void updateMultiple(Map<String, IngredientQuantity> quantities) {
    final newQuantities = Map<String, IngredientQuantity>.from(state.quantities);
    newQuantities.addAll(quantities);

    state = state.copyWith(quantities: newQuantities);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // METODOS DE INICIALIZACION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Establece cantidades por defecto (100g) desde una lista de detecciones.
  ///
  /// Crea un IngredientQuantity con valor por defecto para cada deteccion unica.
  /// Si ya existe una cantidad para un ingrediente, no se sobrescribe.
  ///
  /// [detections] Lista de detecciones del modelo YOLO.
  /// [overwrite] Si es true, sobrescribe cantidades existentes.
  void setFromDetections(List<Detection> detections, {bool overwrite = false}) {
    if (detections.isEmpty) return;

    // Obtener etiquetas unicas
    final uniqueLabels = detections.map((d) => d.label).toSet();

    final newQuantities = Map<String, IngredientQuantity>.from(state.quantities);

    for (final label in uniqueLabels) {
      if (overwrite || !newQuantities.containsKey(label)) {
        newQuantities[label] = IngredientQuantity.defaultValue(label);
      }
    }

    state = state.copyWith(quantities: newQuantities);
  }

  /// Establece cantidades desde una lista de etiquetas.
  ///
  /// Crea un IngredientQuantity con valor por defecto para cada etiqueta.
  ///
  /// [labels] Lista de etiquetas de ingredientes.
  /// [overwrite] Si es true, sobrescribe cantidades existentes.
  void setFromLabels(List<String> labels, {bool overwrite = false}) {
    if (labels.isEmpty) return;

    final uniqueLabels = labels.toSet();
    final newQuantities = Map<String, IngredientQuantity>.from(state.quantities);

    for (final label in uniqueLabels) {
      if (overwrite || !newQuantities.containsKey(label)) {
        newQuantities[label] = IngredientQuantity.defaultValue(label);
      }
    }

    state = state.copyWith(quantities: newQuantities);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // METODOS DE RESET Y ELIMINACION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Resetea la cantidad de un ingrediente al valor por defecto (100g).
  ///
  /// [label] Etiqueta del ingrediente a resetear.
  void resetToDefault(String label) {
    if (!state.quantities.containsKey(label)) return;

    final newQuantities = Map<String, IngredientQuantity>.from(state.quantities);
    newQuantities[label] = IngredientQuantity.defaultValue(label);

    state = state.copyWith(quantities: newQuantities);
  }

  /// Resetea todas las cantidades al valor por defecto (100g).
  void resetAllToDefaults() {
    if (state.isEmpty) return;

    final newQuantities = <String, IngredientQuantity>{};
    for (final label in state.labels) {
      newQuantities[label] = IngredientQuantity.defaultValue(label);
    }

    state = state.copyWith(quantities: newQuantities);
  }

  /// Remueve un ingrediente del estado.
  ///
  /// [label] Etiqueta del ingrediente a remover.
  void removeIngredient(String label) {
    if (!state.quantities.containsKey(label)) return;

    final newQuantities = Map<String, IngredientQuantity>.from(state.quantities);
    newQuantities.remove(label);

    state = state.copyWith(quantities: newQuantities);
  }

  /// Remueve multiples ingredientes del estado.
  ///
  /// [labels] Lista de etiquetas a remover.
  void removeIngredients(List<String> labels) {
    if (labels.isEmpty) return;

    final newQuantities = Map<String, IngredientQuantity>.from(state.quantities);
    for (final label in labels) {
      newQuantities.remove(label);
    }

    state = state.copyWith(quantities: newQuantities);
  }

  /// Limpia todas las cantidades.
  void clear() {
    if (state.isEmpty) return;
    state = const IngredientQuantitiesState.initial();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // VALIDACION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Valida que los gramos esten dentro del rango permitido.
  void _validateGrams(double grams) {
    if (grams < IngredientQuantity.minGrams ||
        grams > IngredientQuantity.maxGrams) {
      throw ArgumentError(
        'Cantidad fuera de rango: $grams g. '
        'Rango permitido: ${IngredientQuantity.minGrams} - ${IngredientQuantity.maxGrams} g',
      );
    }
  }

  /// Verifica si una cantidad de gramos es valida.
  ///
  /// Retorna true si esta dentro del rango permitido.
  static bool isValidGrams(double grams) {
    return grams >= IngredientQuantity.minGrams &&
        grams <= IngredientQuantity.maxGrams;
  }
}

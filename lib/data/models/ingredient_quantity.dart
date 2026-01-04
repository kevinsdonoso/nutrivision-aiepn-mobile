// ╔═══════════════════════════════════════════════════════════════════════════════╗
// ║                         ingredient_quantity.dart                              ║
// ║                   Modelo de cantidad de ingrediente                           ║
// ╠═══════════════════════════════════════════════════════════════════════════════╣
// ║  Representa la cantidad de un ingrediente detectado, normalizada en gramos.   ║
// ║  Soporta entrada manual, estimación automática y valor por defecto.          ║
// ╚═══════════════════════════════════════════════════════════════════════════════╝

import 'quantity_enums.dart';
import 'standard_portion.dart';

/// Representa la cantidad de un ingrediente detectado.
///
/// La cantidad siempre se normaliza a gramos internamente, pero puede
/// haber sido ingresada como gramos o como porción estándar.
///
/// Ejemplo de uso:
/// ```dart
/// // Desde gramos directamente
/// final quantity1 = IngredientQuantity(
///   label: 'tomate',
///   grams: 150,
///   unit: QuantityUnit.grams,
///   source: QuantitySource.manual,
/// );
///
/// // Desde porción estándar
/// final portion = StandardPortion(
///   ingredientLabel: 'tomate',
///   name: '1 unidad mediana',
///   grams: 150,
/// );
/// final quantity2 = IngredientQuantity.fromPortion(
///   label: 'tomate',
///   portion: portion,
/// );
///
/// // Valor por defecto (100g)
/// final quantity3 = IngredientQuantity.defaultValue('tomate');
/// ```
class IngredientQuantity {
  // ═══════════════════════════════════════════════════════════════════════════
  // CONSTANTES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Cantidad mínima permitida en gramos
  static const double minGrams = 1.0;

  /// Cantidad máxima permitida en gramos (10kg)
  static const double maxGrams = 10000.0;

  /// Cantidad por defecto cuando no se especifica (100g)
  static const double defaultGrams = 100.0;

  // ═══════════════════════════════════════════════════════════════════════════
  // PROPIEDADES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Etiqueta del ingrediente (debe coincidir con labels de detección)
  final String label;

  /// Cantidad normalizada en gramos
  final double grams;

  /// Unidad original de entrada
  final QuantityUnit unit;

  /// Nombre de la porción si se usó porción estándar
  /// Ejemplo: "1 taza rallado", "1 unidad mediana"
  final String? portionLabel;

  /// Fuente de origen de esta cantidad
  final QuantitySource source;

  // ═══════════════════════════════════════════════════════════════════════════
  // CONSTRUCTORES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Crea una cantidad de ingrediente.
  ///
  /// Throws [ArgumentError] si los gramos están fuera del rango permitido.
  IngredientQuantity({
    required this.label,
    required this.grams,
    required this.unit,
    this.portionLabel,
    required this.source,
  }) {
    _validateGrams(grams);
    if (label.isEmpty) {
      throw ArgumentError('La etiqueta del ingrediente no puede estar vacía');
    }
  }

  /// Crea una cantidad desde una porción estándar.
  ///
  /// La cantidad se normaliza a los gramos especificados en la porción.
  factory IngredientQuantity.fromPortion({
    required String label,
    required StandardPortion portion,
    QuantitySource source = QuantitySource.manual,
  }) {
    return IngredientQuantity(
      label: label,
      grams: portion.grams,
      unit: QuantityUnit.portion,
      portionLabel: portion.name,
      source: source,
    );
  }

  /// Crea una cantidad con el valor por defecto (100g).
  ///
  /// Se usa cuando el usuario no especifica una cantidad.
  factory IngredientQuantity.defaultValue(String label) {
    return IngredientQuantity(
      label: label,
      grams: defaultGrams,
      unit: QuantityUnit.grams,
      source: QuantitySource.defaultValue,
    );
  }

  /// Crea una cantidad desde gramos directamente.
  factory IngredientQuantity.fromGrams({
    required String label,
    required double grams,
    QuantitySource source = QuantitySource.manual,
  }) {
    return IngredientQuantity(
      label: label,
      grams: grams,
      unit: QuantityUnit.grams,
      source: source,
    );
  }

  /// Crea una cantidad estimada automáticamente.
  factory IngredientQuantity.estimated({
    required String label,
    required double grams,
  }) {
    return IngredientQuantity(
      label: label,
      grams: grams,
      unit: QuantityUnit.grams,
      source: QuantitySource.estimated,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // VALIDACIÓN
  // ═══════════════════════════════════════════════════════════════════════════

  /// Valida que la cantidad en gramos esté dentro del rango permitido.
  static void _validateGrams(double grams) {
    if (grams < minGrams || grams > maxGrams) {
      throw ArgumentError(
        'Cantidad fuera de rango: $grams g. '
        'Rango permitido: $minGrams - $maxGrams g',
      );
    }
  }

  /// Indica si esta cantidad es válida.
  bool get isValid {
    return label.isNotEmpty &&
        grams >= minGrams &&
        grams <= maxGrams &&
        (unit != QuantityUnit.portion || portionLabel != null);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PROPIEDADES CALCULADAS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Factor multiplicador para nutrientes por 100g.
  ///
  /// Ejemplo: 150g → factor = 1.5
  double get nutrientFactor => grams / 100.0;

  /// Indica si esta es la cantidad por defecto.
  bool get isDefault => source == QuantitySource.defaultValue;

  /// Indica si fue ingresada manualmente.
  bool get isManual => source == QuantitySource.manual;

  /// Indica si fue estimada automáticamente.
  bool get isEstimated => source == QuantitySource.estimated;

  /// Texto descriptivo de la cantidad.
  ///
  /// Ejemplos:
  /// - "150g" (si unit = grams)
  /// - "1 taza rallado (110g)" (si unit = portion)
  String get displayText {
    if (unit == QuantityUnit.portion && portionLabel != null) {
      return '$portionLabel (${grams.toStringAsFixed(0)}g)';
    }
    return '${grams.toStringAsFixed(0)}g';
  }

  /// Texto breve de la cantidad.
  ///
  /// Ejemplo: "150g"
  String get shortDisplayText => '${grams.toStringAsFixed(0)}g';

  // ═══════════════════════════════════════════════════════════════════════════
  // SERIALIZACIÓN JSON
  // ═══════════════════════════════════════════════════════════════════════════

  /// Crea una instancia desde JSON.
  factory IngredientQuantity.fromJson(Map<String, dynamic> json) {
    return IngredientQuantity(
      label: json['label'] as String,
      grams: (json['grams'] as num).toDouble(),
      unit: QuantityUnit.values.firstWhere(
        (e) => e.name == json['unit'],
        orElse: () => QuantityUnit.grams,
      ),
      portionLabel: json['portionLabel'] as String?,
      source: QuantitySource.values.firstWhere(
        (e) => e.name == json['source'],
        orElse: () => QuantitySource.defaultValue,
      ),
    );
  }

  /// Convierte la instancia a JSON.
  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'grams': grams,
      'unit': unit.name,
      if (portionLabel != null) 'portionLabel': portionLabel,
      'source': source.name,
    };
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // OPERADORES DE COMPARACIÓN
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is IngredientQuantity &&
        other.label == label &&
        other.grams == grams &&
        other.unit == unit &&
        other.portionLabel == portionLabel &&
        other.source == source;
  }

  @override
  int get hashCode {
    return Object.hash(
      label,
      grams,
      unit,
      portionLabel,
      source,
    );
  }

  @override
  String toString() {
    return 'IngredientQuantity('
        'label: $label, '
        'grams: $grams, '
        'unit: ${unit.name}, '
        'source: ${source.name}'
        ')';
  }

  /// Crea una copia con valores modificados.
  IngredientQuantity copyWith({
    String? label,
    double? grams,
    QuantityUnit? unit,
    String? portionLabel,
    QuantitySource? source,
  }) {
    return IngredientQuantity(
      label: label ?? this.label,
      grams: grams ?? this.grams,
      unit: unit ?? this.unit,
      portionLabel: portionLabel ?? this.portionLabel,
      source: source ?? this.source,
    );
  }
}

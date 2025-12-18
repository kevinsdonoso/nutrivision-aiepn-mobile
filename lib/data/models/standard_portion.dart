// ╔═══════════════════════════════════════════════════════════════════════════════╗
// ║                         standard_portion.dart                                 ║
// ║                   Modelo de porción estándar de ingredientes                 ║
// ╠═══════════════════════════════════════════════════════════════════════════════╣
// ║  Define porciones comunes con su equivalencia en gramos para facilitar       ║
// ║  el ingreso de cantidades por parte del usuario.                             ║
// ╚═══════════════════════════════════════════════════════════════════════════════╝

/// Representa una porción estándar de un ingrediente.
///
/// Ejemplo:
/// ```dart
/// final portion = StandardPortion(
///   ingredientLabel: 'tomate',
///   name: '1 unidad mediana',
///   grams: 150,
///   description: 'Un tomate de tamaño mediano',
/// );
/// ```
class StandardPortion {
  /// Etiqueta del ingrediente (debe coincidir con labels de detección)
  final String ingredientLabel;

  /// Nombre descriptivo de la porción (ej: "1 taza rallado", "1 unidad mediana")
  final String name;

  /// Equivalencia en gramos de esta porción
  final double grams;

  /// Descripción opcional adicional
  final String? description;

  const StandardPortion({
    required this.ingredientLabel,
    required this.name,
    required this.grams,
    this.description,
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // SERIALIZACIÓN JSON
  // ═══════════════════════════════════════════════════════════════════════════

  /// Crea una instancia desde JSON.
  ///
  /// Formato esperado:
  /// ```json
  /// {
  ///   "name": "1 unidad mediana",
  ///   "grams": 150,
  ///   "description": "Opcional"
  /// }
  /// ```
  factory StandardPortion.fromJson(
    Map<String, dynamic> json,
    String ingredientLabel,
  ) {
    return StandardPortion(
      ingredientLabel: ingredientLabel,
      name: json['name'] as String,
      grams: (json['grams'] as num).toDouble(),
      description: json['description'] as String?,
    );
  }

  /// Convierte la instancia a JSON.
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'grams': grams,
      if (description != null) 'description': description,
    };
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS DE UTILIDAD
  // ═══════════════════════════════════════════════════════════════════════════

  /// Retorna una representación en texto de la porción.
  ///
  /// Ejemplo: "1 unidad mediana (150g)"
  String get displayName => '$name (${grams.toStringAsFixed(0)}g)';

  /// Valida que los valores sean correctos.
  bool get isValid {
    return ingredientLabel.isNotEmpty && name.isNotEmpty && grams > 0;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // OPERADORES DE COMPARACIÓN
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is StandardPortion &&
        other.ingredientLabel == ingredientLabel &&
        other.name == name &&
        other.grams == grams &&
        other.description == description;
  }

  @override
  int get hashCode {
    return Object.hash(
      ingredientLabel,
      name,
      grams,
      description,
    );
  }

  @override
  String toString() {
    return 'StandardPortion(ingredient: $ingredientLabel, '
        'name: $name, grams: $grams)';
  }

  /// Crea una copia con valores modificados.
  StandardPortion copyWith({
    String? ingredientLabel,
    String? name,
    double? grams,
    String? description,
  }) {
    return StandardPortion(
      ingredientLabel: ingredientLabel ?? this.ingredientLabel,
      name: name ?? this.name,
      grams: grams ?? this.grams,
      description: description ?? this.description,
    );
  }
}

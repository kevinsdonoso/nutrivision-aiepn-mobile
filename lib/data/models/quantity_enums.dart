// ╔═══════════════════════════════════════════════════════════════════════════════╗
// ║                         quantity_enums.dart                                   ║
// ║                    Enumeraciones para sistema de cantidades                  ║
// ╠═══════════════════════════════════════════════════════════════════════════════╣
// ║  Define tipos enumerados para unidades de cantidad y fuentes de datos.       ║
// ╚═══════════════════════════════════════════════════════════════════════════════╝

/// Unidad de medida para cantidad de ingredientes.
///
/// - [grams]: Cantidad especificada en gramos
/// - [portion]: Cantidad especificada como porción estándar
enum QuantityUnit {
  /// Cantidad en gramos (ej: 150g)
  grams('gramos'),

  /// Porción estándar (ej: "1 taza", "1 unidad mediana")
  portion('porción');

  const QuantityUnit(this.displayName);

  /// Nombre para mostrar al usuario
  final String displayName;
}

/// Fuente de origen de la cantidad del ingrediente.
///
/// Indica si la cantidad fue ingresada manualmente, estimada automáticamente
/// o es el valor por defecto del sistema.
enum QuantitySource {
  /// Cantidad ingresada manualmente por el usuario
  manual('Manual'),

  /// Cantidad estimada automáticamente por el sistema
  estimated('Estimada'),

  /// Valor por defecto (100g) cuando no se especifica cantidad
  defaultValue('Por defecto');

  const QuantitySource(this.displayName);

  /// Nombre para mostrar al usuario
  final String displayName;

  /// Indica si esta fuente requiere confirmación del usuario
  bool get requiresConfirmation => this == estimated;

  /// Indica si es un valor confiable
  bool get isReliable => this == manual;
}

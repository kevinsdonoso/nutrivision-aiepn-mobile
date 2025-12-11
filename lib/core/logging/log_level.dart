// ╔═══════════════════════════════════════════════════════════════════════════════╗
// ║                              log_level.dart                                   ║
// ║                    Niveles de logging para NutriVision                        ║
// ╠═══════════════════════════════════════════════════════════════════════════════╣
// ║  Define los niveles de severidad para el sistema de logging centralizado.     ║
// ║  Permite filtrar mensajes según su importancia en diferentes ambientes.       ║
// ╚═══════════════════════════════════════════════════════════════════════════════╝

/// Niveles de severidad para el sistema de logging.
///
/// Los niveles están ordenados de menor a mayor severidad:
/// - [debug]: Información detallada para desarrollo
/// - [info]: Información general de operaciones normales
/// - [warning]: Situaciones inesperadas pero manejables
/// - [error]: Errores que afectan funcionalidad
/// - [none]: Desactiva todo el logging
///
/// Ejemplo de uso:
/// ```dart
/// LogConfig.minLevel = LogLevel.warning; // Solo warning y error
/// ```
enum LogLevel {
  /// Información detallada para desarrollo y debugging.
  /// Incluye valores de variables, flujo de ejecución, etc.
  debug,

  /// Información general sobre operaciones normales.
  /// Eventos importantes del ciclo de vida de la aplicación.
  info,

  /// Situaciones inesperadas pero que no impiden el funcionamiento.
  /// La aplicación puede continuar pero algo no es ideal.
  warning,

  /// Errores que afectan la funcionalidad.
  /// Requieren atención pero la aplicación puede continuar.
  error,

  /// Desactiva todo el logging.
  /// Útil para builds de producción donde no se necesitan logs.
  none,
}

/// Extensión para comparar niveles de logging.
extension LogLevelExtension on LogLevel {
  /// Retorna `true` si este nivel es igual o mayor que [other].
  ///
  /// Útil para filtrar mensajes según el nivel mínimo configurado.
  bool isAtLeast(LogLevel other) {
    return index >= other.index;
  }

  /// Retorna el prefijo emoji para este nivel.
  String get emoji {
    switch (this) {
      case LogLevel.debug:
        return '🔍';
      case LogLevel.info:
        return 'ℹ️';
      case LogLevel.warning:
        return '⚠️';
      case LogLevel.error:
        return '❌';
      case LogLevel.none:
        return '';
    }
  }

  /// Retorna el nombre en mayúsculas para el log.
  String get label {
    switch (this) {
      case LogLevel.debug:
        return 'DEBUG';
      case LogLevel.info:
        return 'INFO';
      case LogLevel.warning:
        return 'WARN';
      case LogLevel.error:
        return 'ERROR';
      case LogLevel.none:
        return '';
    }
  }
}

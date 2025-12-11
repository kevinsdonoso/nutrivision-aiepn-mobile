// ╔═══════════════════════════════════════════════════════════════════════════════╗
// ║                              app_logger.dart                                  ║
// ║                    Logger centralizado para NutriVision                       ║
// ╠═══════════════════════════════════════════════════════════════════════════════╣
// ║  Proporciona métodos estáticos para logging estructurado en toda la app.      ║
// ║  Respeta la configuración de LogConfig para filtrar y formatear mensajes.     ║
// ╚═══════════════════════════════════════════════════════════════════════════════╝

import 'package:flutter/foundation.dart';

import 'log_config.dart';
import 'log_level.dart';

/// Logger centralizado para NutriVision.
///
/// Proporciona métodos estáticos para diferentes niveles de logging:
/// - [debug]: Información detallada para desarrollo
/// - [info]: Información general de operaciones
/// - [warning]: Situaciones inesperadas pero manejables
/// - [error]: Errores que afectan funcionalidad
///
/// Características:
/// - Respeta nivel mínimo configurado en [LogConfig]
/// - Formatea mensajes con timestamp, tag y emoji
/// - Trunca mensajes largos
/// - Solo imprime en modo debug (producción silencioso por defecto)
///
/// Ejemplo de uso:
/// ```dart
/// AppLogger.debug('Inicializando detector', tag: 'YoloDetector');
/// AppLogger.info('Modelo cargado exitosamente');
/// AppLogger.warning('Usando fallback para nutrientes');
/// AppLogger.error('Error en inferencia', error: e, stackTrace: s);
/// ```
class AppLogger {
  AppLogger._(); // Constructor privado para prevenir instanciación

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS PÚBLICOS DE LOGGING
  // ═══════════════════════════════════════════════════════════════════════════

  /// Log de nivel DEBUG.
  ///
  /// Para información detallada útil durante desarrollo.
  /// Incluye valores de variables, flujo de ejecución, etc.
  ///
  /// [message] - Mensaje a mostrar
  /// [tag] - Componente/clase que origina el log (opcional)
  /// [error] - Objeto de error asociado (opcional)
  static void debug(
    String message, {
    String? tag,
    Object? error,
  }) {
    _log(LogLevel.debug, message, tag: tag, error: error);
  }

  /// Log de nivel INFO.
  ///
  /// Para información general sobre operaciones normales.
  /// Eventos importantes del ciclo de vida de la aplicación.
  ///
  /// [message] - Mensaje a mostrar
  /// [tag] - Componente/clase que origina el log (opcional)
  static void info(
    String message, {
    String? tag,
  }) {
    _log(LogLevel.info, message, tag: tag);
  }

  /// Log de nivel WARNING.
  ///
  /// Para situaciones inesperadas pero que no impiden el funcionamiento.
  /// La aplicación puede continuar pero algo no es ideal.
  ///
  /// [message] - Mensaje a mostrar
  /// [tag] - Componente/clase que origina el log (opcional)
  /// [error] - Objeto de error asociado (opcional)
  static void warning(
    String message, {
    String? tag,
    Object? error,
  }) {
    _log(LogLevel.warning, message, tag: tag, error: error);
  }

  /// Log de nivel ERROR.
  ///
  /// Para errores que afectan la funcionalidad.
  /// Requieren atención pero la aplicación puede continuar.
  ///
  /// [message] - Mensaje a mostrar
  /// [tag] - Componente/clase que origina el log (opcional)
  /// [error] - Objeto de error asociado (opcional)
  /// [stackTrace] - Stack trace del error (opcional)
  static void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(LogLevel.error, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS INTERNOS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Método interno que realiza el logging.
  static void _log(
    LogLevel level,
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    // Verificar si el nivel está habilitado
    if (!_shouldLog(level)) return;

    // Solo imprimir en modo debug (assert se elimina en release)
    assert(() {
      final formattedMessage = _formatMessage(level, message, tag: tag);
      debugPrint(formattedMessage);

      // Imprimir error si existe
      if (error != null) {
        debugPrint('  └─ Error: $error');
      }

      // Imprimir stack trace si existe
      if (stackTrace != null) {
        final truncatedStack = _truncateStackTrace(stackTrace);
        debugPrint('  └─ Stack:\n$truncatedStack');
      }

      return true;
    }());
  }

  /// Verifica si un nivel de log debe ser mostrado.
  static bool _shouldLog(LogLevel level) {
    if (LogConfig.minLevel == LogLevel.none) return false;
    return level.isAtLeast(LogConfig.minLevel);
  }

  /// Formatea el mensaje de log según la configuración.
  static String _formatMessage(
    LogLevel level,
    String message, {
    String? tag,
  }) {
    final buffer = StringBuffer();

    // Emoji
    if (LogConfig.showEmoji) {
      buffer.write('${level.emoji} ');
    }

    // Timestamp
    if (LogConfig.showTimestamp) {
      final now = DateTime.now();
      final timestamp = '${_pad(now.hour)}:${_pad(now.minute)}:${_pad(now.second)}.${_pad(now.millisecond, 3)}';
      buffer.write('[$timestamp] ');
    }

    // Level
    buffer.write('[${level.label}]');

    // Tag
    if (LogConfig.showTag && tag != null) {
      buffer.write(' [$tag]');
    }

    buffer.write(' ');

    // Message (truncado si es necesario)
    final truncatedMessage = _truncateMessage(message);
    buffer.write(truncatedMessage);

    return buffer.toString();
  }

  /// Trunca el mensaje si excede la longitud máxima.
  static String _truncateMessage(String message) {
    if (message.length <= LogConfig.maxMessageLength) {
      return message;
    }
    return '${message.substring(0, LogConfig.maxMessageLength - 3)}...';
  }

  /// Trunca el stack trace al número máximo de líneas.
  static String _truncateStackTrace(StackTrace stackTrace) {
    final lines = stackTrace.toString().split('\n');
    final maxLines = LogConfig.maxStackTraceLines;

    if (lines.length <= maxLines) {
      return lines.map((line) => '      $line').join('\n');
    }

    final truncated = lines.take(maxLines).toList();
    truncated.add('      ... (${lines.length - maxLines} more lines)');
    return truncated.map((line) => line.startsWith('      ') ? line : '      $line').join('\n');
  }

  /// Agrega ceros a la izquierda para formatear números.
  static String _pad(int number, [int width = 2]) {
    return number.toString().padLeft(width, '0');
  }
}

// ╔═══════════════════════════════════════════════════════════════════════════════╗
// ║                              app_logger.dart                                  ║
// ║                    Logger centralizado para NutriVision                       ║
// ╠═══════════════════════════════════════════════════════════════════════════════╣
// ║  Proporciona métodos estáticos para logging estructurado en toda la app.      ║
// ║  Respeta la configuración de LogConfig para filtrar y formatear mensajes.     ║
// ╚═══════════════════════════════════════════════════════════════════════════════╝

import 'package:flutter/foundation.dart';

import 'log_colors.dart';
import 'log_config.dart';
import 'log_level.dart';

/// Logger centralizado para NutriVision.
///
/// Proporciona métodos estáticos para diferentes niveles de logging:
/// - [debug]: Información detallada para desarrollo
/// - [info]: Información general de operaciones
/// - [warning]: Situaciones inesperadas pero manejables
/// - [error]: Errores que afectan funcionalidad
/// - [tree]: Formato de árbol visual para información estructurada
///
/// Características:
/// - Respeta nivel mínimo configurado en [LogConfig]
/// - Formatea mensajes con timestamp, tag y emoji
/// - Soporte de colores ANSI para terminal
/// - Filtrado por tags (ocultar/mostrar específicos)
/// - Modo silencioso para tests
/// - Trunca mensajes largos
/// - Solo imprime en modo debug (producción silencioso por defecto)
///
/// Ejemplo de uso:
/// ```dart
/// AppLogger.debug('Inicializando detector', tag: 'YoloDetector');
/// AppLogger.info('Modelo cargado exitosamente');
/// AppLogger.warning('Usando fallback para nutrientes');
/// AppLogger.error('Error en inferencia', error: e, stackTrace: s);
///
/// // Formato de árbol visual
/// AppLogger.tree(
///   'YoloDetector inicializado',
///   ['Config: 4 threads', 'Modelo: yolov11n.tflite', 'Labels: 83 clases'],
///   tag: 'YoloDetector',
/// );
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
  // MÉTODOS DE FORMATO ESTRUCTURADO
  // ═══════════════════════════════════════════════════════════════════════════

  /// Log con formato de árbol visual.
  ///
  /// Útil para mostrar información estructurada de forma legible.
  /// Cada item se muestra con prefijo de árbol (├─ o └─).
  ///
  /// [header] - Línea principal del árbol
  /// [items] - Lista de items hijos
  /// [tag] - Componente/clase que origina el log (opcional)
  /// [level] - Nivel de log (por defecto DEBUG)
  ///
  /// Ejemplo:
  /// ```dart
  /// AppLogger.tree(
  ///   'Inicializando YoloDetector',
  ///   [
  ///     'Config: 4 threads + XNNPack',
  ///     'Modelo: yolov11n_float32.tflite',
  ///     'Labels: 83 clases',
  ///   ],
  ///   tag: 'YoloDetector',
  /// );
  /// // Output:
  /// // 🔍 [DEBUG] [YoloDetector] Inicializando YoloDetector
  /// //    ├─ Config: 4 threads + XNNPack
  /// //    ├─ Modelo: yolov11n_float32.tflite
  /// //    └─ Labels: 83 clases
  /// ```
  static void tree(
    String header,
    List<String> items, {
    String? tag,
    LogLevel level = LogLevel.debug,
  }) {
    if (!_shouldLog(level, tag)) return;

    assert(() {
      // Header principal
      final formattedHeader = _formatMessage(level, header, tag: tag);
      debugPrint(formattedHeader);

      // Items con formato de árbol
      final color = LogConfig.enableColors ? LogColors.forLevel(level) : '';
      final reset = LogConfig.enableColors ? LogColors.reset : '';

      for (int i = 0; i < items.length; i++) {
        final isLast = i == items.length - 1;
        final prefix = isLast ? '└─' : '├─';
        debugPrint('$color   $prefix ${items[i]}$reset');
      }

      return true;
    }());
  }

  /// Log con formato de subárbol (secciones anidadas).
  ///
  /// Útil para mostrar información con subsecciones.
  ///
  /// [header] - Línea principal
  /// [sections] - Mapa de sección → lista de items
  /// [tag] - Componente/clase que origina el log (opcional)
  /// [level] - Nivel de log (por defecto DEBUG)
  ///
  /// Ejemplo:
  /// ```dart
  /// AppLogger.subtree(
  ///   'Modelo cargado',
  ///   {
  ///     'Input shape': ['[1, 640, 640, 3]', 'RGB normalizado'],
  ///     'Output shape': ['[1, 87, 8400]', '83 clases + 4 coords'],
  ///   },
  ///   tag: 'YoloDetector',
  /// );
  /// ```
  static void subtree(
    String header,
    Map<String, List<String>> sections, {
    String? tag,
    LogLevel level = LogLevel.debug,
  }) {
    if (!_shouldLog(level, tag)) return;

    assert(() {
      // Header principal
      final formattedHeader = _formatMessage(level, header, tag: tag);
      debugPrint(formattedHeader);

      final color = LogConfig.enableColors ? LogColors.forLevel(level) : '';
      final reset = LogConfig.enableColors ? LogColors.reset : '';

      final keys = sections.keys.toList();
      for (int i = 0; i < keys.length; i++) {
        final isLastSection = i == keys.length - 1;
        final sectionPrefix = isLastSection ? '└─' : '├─';
        debugPrint('$color   $sectionPrefix ${keys[i]}$reset');

        final items = sections[keys[i]]!;
        for (int j = 0; j < items.length; j++) {
          final isLastItem = j == items.length - 1;
          final connector = isLastSection ? '   ' : '│  ';
          final itemPrefix = isLastItem ? '└─' : '├─';
          debugPrint('$color   $connector $itemPrefix ${items[j]}$reset');
        }
      }

      return true;
    }());
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
    // Verificar si debe mostrarse (nivel, quietMode, filtros de tag)
    if (!_shouldLog(level, tag)) return;

    // Solo imprimir en modo debug (assert se elimina en release)
    assert(() {
      final formattedMessage = _formatMessage(level, message, tag: tag);
      debugPrint(formattedMessage);

      // Colores para error y stack trace
      final color = LogConfig.enableColors ? LogColors.forLevel(level) : '';
      final reset = LogConfig.enableColors ? LogColors.reset : '';

      // Imprimir error si existe
      if (error != null) {
        debugPrint('$color  └─ Error: $error$reset');
      }

      // Imprimir stack trace si existe
      if (stackTrace != null) {
        final truncatedStack = _truncateStackTrace(stackTrace, color, reset);
        debugPrint('$color  └─ Stack:$reset\n$truncatedStack');
      }

      return true;
    }());
  }

  /// Verifica si un log debe ser mostrado.
  ///
  /// Considera:
  /// - Modo silencioso (quietMode)
  /// - Nivel mínimo de log
  /// - Filtros de tags
  static bool _shouldLog(LogLevel level, [String? tag]) {
    // Modo silencioso suprime todo
    if (LogConfig.quietMode) return false;

    // Verificar nivel mínimo
    if (LogConfig.minLevel == LogLevel.none) return false;
    if (!level.isAtLeast(LogConfig.minLevel)) return false;

    // Verificar filtros de tag
    if (!LogConfig.shouldShowTag(tag)) return false;

    return true;
  }

  /// Formatea el mensaje de log según la configuración.
  static String _formatMessage(
    LogLevel level,
    String message, {
    String? tag,
  }) {
    final buffer = StringBuffer();

    // Obtener colores
    final color = LogConfig.enableColors ? LogColors.forLevel(level) : '';
    final bold = LogConfig.enableColors ? LogColors.bold : '';
    final reset = LogConfig.enableColors ? LogColors.reset : '';

    // Emoji
    if (LogConfig.showEmoji) {
      buffer.write('${level.emoji} ');
    }

    // Timestamp
    if (LogConfig.showTimestamp) {
      final now = DateTime.now();
      final timestamp =
          '${_pad(now.hour)}:${_pad(now.minute)}:${_pad(now.second)}.${_pad(now.millisecond, 3)}';
      buffer.write('$color[$timestamp]$reset ');
    }

    // Level (en negrita y con color)
    buffer.write('$bold$color[${level.label}]$reset');

    // Tag (solo color, sin negrita)
    if (LogConfig.showTag && tag != null) {
      buffer.write('$color [$tag]$reset');
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
  static String _truncateStackTrace(
    StackTrace stackTrace, [
    String color = '',
    String reset = '',
  ]) {
    final lines = stackTrace.toString().split('\n');
    final maxLines = LogConfig.maxStackTraceLines;

    if (lines.length <= maxLines) {
      return lines.map((line) => '$color      $line$reset').join('\n');
    }

    final truncated = lines.take(maxLines).toList();
    truncated.add('... (${lines.length - maxLines} more lines)');
    return truncated.map((line) => '$color      $line$reset').join('\n');
  }

  /// Agrega ceros a la izquierda para formatear números.
  static String _pad(int number, [int width = 2]) {
    return number.toString().padLeft(width, '0');
  }
}

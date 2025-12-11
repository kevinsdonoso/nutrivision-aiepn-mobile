// ╔═══════════════════════════════════════════════════════════════════════════════╗
// ║                              log_config.dart                                  ║
// ║                   Configuración del sistema de logging                        ║
// ╠═══════════════════════════════════════════════════════════════════════════════╣
// ║  Define parámetros configurables para el sistema de logging.                  ║
// ║  Permite ajustar el comportamiento según el ambiente de ejecución.            ║
// ╚═══════════════════════════════════════════════════════════════════════════════╝

import 'package:flutter/foundation.dart';

import 'log_level.dart';

/// Configuración global del sistema de logging.
///
/// Permite ajustar:
/// - Nivel mínimo de logs a mostrar
/// - Formato de los mensajes (timestamp, tags)
/// - Longitud máxima de mensajes
///
/// Por defecto, en modo debug muestra todos los logs,
/// y en release solo muestra errores.
///
/// Ejemplo de uso:
/// ```dart
/// // Configurar para producción
/// LogConfig.minLevel = LogLevel.error;
/// LogConfig.showTimestamp = false;
///
/// // Configurar para desarrollo
/// LogConfig.minLevel = LogLevel.debug;
/// LogConfig.showTimestamp = true;
/// ```
class LogConfig {
  LogConfig._(); // Constructor privado para prevenir instanciación

  // ═══════════════════════════════════════════════════════════════════════════
  // CONFIGURACIÓN DE NIVEL
  // ═══════════════════════════════════════════════════════════════════════════

  /// Nivel mínimo de logs a mostrar.
  ///
  /// Solo se mostrarán logs con nivel igual o superior a este.
  /// Por defecto: [LogLevel.debug] en debug, [LogLevel.error] en release.
  static LogLevel minLevel = kDebugMode ? LogLevel.debug : LogLevel.error;

  // ═══════════════════════════════════════════════════════════════════════════
  // CONFIGURACIÓN DE FORMATO
  // ═══════════════════════════════════════════════════════════════════════════

  /// Si se debe mostrar timestamp en los logs.
  ///
  /// Formato: `HH:mm:ss.SSS`
  /// Por defecto: `true` en debug, `false` en release.
  static bool showTimestamp = kDebugMode;

  /// Si se debe mostrar el tag/componente en los logs.
  ///
  /// Por defecto: `true`
  static bool showTag = true;

  /// Si se debe mostrar emoji de nivel en los logs.
  ///
  /// Por defecto: `true`
  static bool showEmoji = true;

  // ═══════════════════════════════════════════════════════════════════════════
  // CONFIGURACIÓN DE LÍMITES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Longitud máxima del mensaje antes de truncar.
  ///
  /// Los mensajes más largos se truncarán con "..." al final.
  /// Por defecto: 1000 caracteres.
  static int maxMessageLength = 1000;

  /// Longitud máxima del stack trace a mostrar.
  ///
  /// Por defecto: 10 líneas.
  static int maxStackTraceLines = 10;

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS DE CONFIGURACIÓN
  // ═══════════════════════════════════════════════════════════════════════════

  /// Configura el logging para ambiente de desarrollo.
  ///
  /// - Muestra todos los niveles (debug y superiores)
  /// - Incluye timestamps y tags
  /// - Sin límite práctico de longitud
  static void configureForDevelopment() {
    minLevel = LogLevel.debug;
    showTimestamp = true;
    showTag = true;
    showEmoji = true;
    maxMessageLength = 2000;
    maxStackTraceLines = 20;
  }

  /// Configura el logging para ambiente de producción.
  ///
  /// - Solo muestra errores
  /// - Sin timestamps ni emojis
  /// - Mensajes más cortos
  static void configureForProduction() {
    minLevel = LogLevel.error;
    showTimestamp = false;
    showTag = true;
    showEmoji = false;
    maxMessageLength = 500;
    maxStackTraceLines = 5;
  }

  /// Desactiva completamente el logging.
  static void disable() {
    minLevel = LogLevel.none;
  }

  /// Restaura la configuración por defecto.
  static void reset() {
    minLevel = kDebugMode ? LogLevel.debug : LogLevel.error;
    showTimestamp = kDebugMode;
    showTag = true;
    showEmoji = true;
    maxMessageLength = 1000;
    maxStackTraceLines = 10;
  }
}

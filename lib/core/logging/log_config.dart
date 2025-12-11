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
/// - Filtrado por tags (ocultar/mostrar específicos)
/// - Modo silencioso para tests
/// - Colores ANSI para terminal
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
///
/// // Silenciar tests
/// LogConfig.configureForTests();
///
/// // Filtrar por tag
/// LogConfig.hideTag('YoloDetector');
/// LogConfig.showOnlyTags({'CameraProcessor'});
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

  /// Modo silencioso - suprime todos los logs.
  ///
  /// Útil para tests donde no se quiere ver output de debug.
  /// Por defecto: `false`.
  static bool quietMode = false;

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

  /// Si se deben usar colores ANSI en la terminal.
  ///
  /// Mejora la legibilidad en terminales compatibles.
  /// Por defecto: `true` en debug, `false` en release.
  static bool enableColors = kDebugMode;

  // ═══════════════════════════════════════════════════════════════════════════
  // CONFIGURACIÓN DE FILTRADO POR TAGS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Tags que serán ocultados (no se mostrarán sus logs).
  ///
  /// Útil para silenciar componentes específicos durante debugging.
  static final Set<String> _hiddenTags = {};

  /// Tags que serán los únicos mostrados.
  ///
  /// Si está vacío, se muestran todos los tags (excepto los de [_hiddenTags]).
  /// Si tiene elementos, SOLO se mostrarán logs de esos tags.
  static final Set<String> _onlyTags = {};

  /// Retorna una vista inmutable de los tags ocultos.
  static Set<String> get hiddenTags => Set.unmodifiable(_hiddenTags);

  /// Retorna una vista inmutable de los tags permitidos.
  static Set<String> get onlyTags => Set.unmodifiable(_onlyTags);

  /// Oculta logs de un tag específico.
  static void hideTag(String tag) => _hiddenTags.add(tag);

  /// Muestra solo logs de los tags especificados.
  ///
  /// Si se llama múltiples veces, agrega al conjunto existente.
  static void showOnlyTag(String tag) => _onlyTags.add(tag);

  /// Muestra solo logs de los tags especificados.
  static void showOnlyTags(Set<String> tags) => _onlyTags.addAll(tags);

  /// Limpia todos los filtros de tags.
  static void clearTagFilters() {
    _hiddenTags.clear();
    _onlyTags.clear();
  }

  /// Verifica si un tag debe ser mostrado según los filtros actuales.
  static bool shouldShowTag(String? tag) {
    if (tag == null) return true;
    if (_hiddenTags.contains(tag)) return false;
    if (_onlyTags.isNotEmpty && !_onlyTags.contains(tag)) return false;
    return true;
  }

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
  /// - Colores habilitados
  /// - Sin límite práctico de longitud
  static void configureForDevelopment() {
    quietMode = false;
    minLevel = LogLevel.debug;
    showTimestamp = true;
    showTag = true;
    showEmoji = true;
    enableColors = true;
    maxMessageLength = 2000;
    maxStackTraceLines = 20;
    clearTagFilters();
  }

  /// Configura el logging para ambiente de producción.
  ///
  /// - Solo muestra errores
  /// - Sin timestamps ni emojis
  /// - Sin colores
  /// - Mensajes más cortos
  static void configureForProduction() {
    quietMode = false;
    minLevel = LogLevel.error;
    showTimestamp = false;
    showTag = true;
    showEmoji = false;
    enableColors = false;
    maxMessageLength = 500;
    maxStackTraceLines = 5;
    clearTagFilters();
  }

  /// Configura el logging para tests (modo silencioso).
  ///
  /// - Solo muestra errores críticos
  /// - Sin timestamps ni colores
  /// - Ideal para `flutter test` donde los logs verbosos distraen
  ///
  /// Ejemplo:
  /// ```dart
  /// setUpAll(() {
  ///   LogConfig.configureForTests();
  /// });
  ///
  /// tearDownAll(() {
  ///   LogConfig.reset();
  /// });
  /// ```
  static void configureForTests() {
    quietMode = true;
    minLevel = LogLevel.error;
    showTimestamp = false;
    showTag = true;
    showEmoji = false;
    enableColors = false;
    clearTagFilters();
  }

  /// Configura el logging para tests verbose (debugging de tests).
  ///
  /// - Muestra todos los niveles
  /// - Incluye timestamps y colores
  /// - Útil cuando se necesita debuggear un test específico
  ///
  /// Ejemplo:
  /// ```dart
  /// test('debugging específico', () {
  ///   LogConfig.configureVerboseTests();
  ///   // ... código del test
  ///   LogConfig.configureForTests(); // Volver a silencioso
  /// });
  /// ```
  static void configureVerboseTests() {
    quietMode = false;
    minLevel = LogLevel.debug;
    showTimestamp = true;
    showTag = true;
    showEmoji = true;
    enableColors = true;
    clearTagFilters();
  }

  /// Desactiva completamente el logging.
  static void disable() {
    minLevel = LogLevel.none;
    quietMode = true;
  }

  /// Restaura la configuración por defecto.
  static void reset() {
    quietMode = false;
    minLevel = kDebugMode ? LogLevel.debug : LogLevel.error;
    showTimestamp = kDebugMode;
    showTag = true;
    showEmoji = true;
    enableColors = kDebugMode;
    maxMessageLength = 1000;
    maxStackTraceLines = 10;
    clearTagFilters();
  }
}

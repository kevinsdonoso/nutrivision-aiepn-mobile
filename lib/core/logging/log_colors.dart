// ╔═══════════════════════════════════════════════════════════════════════════════╗
// ║                              log_colors.dart                                  ║
// ║                    Colores ANSI para terminal de NutriVision                  ║
// ╠═══════════════════════════════════════════════════════════════════════════════╣
// ║  Define códigos de escape ANSI para colorear logs en la terminal.             ║
// ║  Mejora la legibilidad visual al diferenciar niveles de severidad.            ║
// ╚═══════════════════════════════════════════════════════════════════════════════╝

import 'log_level.dart';

/// Colores ANSI para formatear logs en terminal.
///
/// Los códigos ANSI son secuencias de escape que permiten colorear texto
/// en terminales compatibles (la mayoría de terminales modernas).
///
/// Ejemplo de uso:
/// ```dart
/// print('${LogColors.red}Error!${LogColors.reset}');
/// print('${LogColors.green}Success!${LogColors.reset}');
/// ```
///
/// IMPORTANTE: Siempre usar [reset] después del texto coloreado
/// para restaurar el color normal de la terminal.
abstract class LogColors {
  LogColors._(); // Constructor privado para prevenir instanciación

  // ═══════════════════════════════════════════════════════════════════════════
  // RESET
  // ═══════════════════════════════════════════════════════════════════════════

  /// Restaura el color y estilo por defecto de la terminal.
  static const String reset = '\x1B[0m';

  // ═══════════════════════════════════════════════════════════════════════════
  // COLORES DE TEXTO
  // ═══════════════════════════════════════════════════════════════════════════

  /// Texto negro.
  static const String black = '\x1B[30m';

  /// Texto rojo - usado para errores.
  static const String red = '\x1B[31m';

  /// Texto verde - usado para éxito.
  static const String green = '\x1B[32m';

  /// Texto amarillo - usado para warnings.
  static const String yellow = '\x1B[33m';

  /// Texto azul - usado para información destacada.
  static const String blue = '\x1B[34m';

  /// Texto magenta - usado para tags.
  static const String magenta = '\x1B[35m';

  /// Texto cyan - usado para info.
  static const String cyan = '\x1B[36m';

  /// Texto blanco.
  static const String white = '\x1B[37m';

  /// Texto gris - usado para debug.
  static const String gray = '\x1B[90m';

  // ═══════════════════════════════════════════════════════════════════════════
  // ESTILOS DE TEXTO
  // ═══════════════════════════════════════════════════════════════════════════

  /// Texto en negrita.
  static const String bold = '\x1B[1m';

  /// Texto atenuado/dim.
  static const String dim = '\x1B[2m';

  /// Texto subrayado.
  static const String underline = '\x1B[4m';

  // ═══════════════════════════════════════════════════════════════════════════
  // COLORES POR NIVEL DE LOG
  // ═══════════════════════════════════════════════════════════════════════════

  /// Retorna el color ANSI correspondiente a un nivel de log.
  ///
  /// - [LogLevel.debug]: Gris (información secundaria)
  /// - [LogLevel.info]: Cyan (información normal)
  /// - [LogLevel.warning]: Amarillo (advertencias)
  /// - [LogLevel.error]: Rojo (errores)
  /// - [LogLevel.none]: Sin color
  static String forLevel(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return gray;
      case LogLevel.info:
        return cyan;
      case LogLevel.warning:
        return yellow;
      case LogLevel.error:
        return red;
      case LogLevel.none:
        return reset;
    }
  }

  /// Retorna el color de fondo ANSI correspondiente a un nivel de log.
  ///
  /// Útil para resaltar mensajes importantes.
  static String backgroundForLevel(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return '\x1B[100m'; // Fondo gris
      case LogLevel.info:
        return '\x1B[46m'; // Fondo cyan
      case LogLevel.warning:
        return '\x1B[43m'; // Fondo amarillo
      case LogLevel.error:
        return '\x1B[41m'; // Fondo rojo
      case LogLevel.none:
        return reset;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Colorea un texto con el color especificado.
  ///
  /// Automáticamente agrega [reset] al final.
  /// Si [enableColors] es false, retorna el texto sin modificar.
  static String colorize(
    String text,
    String color, {
    bool enableColors = true,
  }) {
    if (!enableColors) return text;
    return '$color$text$reset';
  }

  /// Colorea un texto según el nivel de log.
  static String colorizeForLevel(
    String text,
    LogLevel level, {
    bool enableColors = true,
  }) {
    return colorize(text, forLevel(level), enableColors: enableColors);
  }
}

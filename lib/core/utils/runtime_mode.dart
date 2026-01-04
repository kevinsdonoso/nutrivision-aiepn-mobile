// ╔═══════════════════════════════════════════════════════════════════════════════╗
// ║                         runtime_mode.dart                                     ║
// ║              Utilidad para detectar modo de ejecución de Flutter              ║
// ╠═══════════════════════════════════════════════════════════════════════════════╣
// ║  Detecta si la app está corriendo en modo DEBUG, PROFILE o RELEASE.           ║
// ║  Útil para mostrar indicadores visuales y ajustar configuraciones.            ║
// ╚═══════════════════════════════════════════════════════════════════════════════╝

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Modos de ejecución de Flutter.
///
/// - **DEBUG**: Desarrollo con hot reload, sin optimizaciones.
/// - **PROFILE**: Build AOT con perfilado habilitado.
/// - **RELEASE**: Build final optimizado para producción.
enum RuntimeMode {
  /// Modo debug (flutter run)
  debug,

  /// Modo profile (flutter run --profile)
  profile,

  /// Modo release (flutter run --release o APK final)
  release;

  // ═══════════════════════════════════════════════════════════════════════════
  // DETECCIÓN DEL MODO ACTUAL
  // ═══════════════════════════════════════════════════════════════════════════

  /// Detecta el modo de ejecución actual usando las constantes de Flutter.
  static RuntimeMode get current {
    if (kDebugMode) return RuntimeMode.debug;
    if (kProfileMode) return RuntimeMode.profile;
    return RuntimeMode.release;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PROPIEDADES DE UI
  // ═══════════════════════════════════════════════════════════════════════════

  /// Nombre para mostrar en la UI.
  String get displayName {
    switch (this) {
      case RuntimeMode.debug:
        return 'DEBUG';
      case RuntimeMode.profile:
        return 'PROFILE';
      case RuntimeMode.release:
        return 'RELEASE';
    }
  }

  /// Color representativo del modo.
  Color get color {
    switch (this) {
      case RuntimeMode.debug:
        return Colors.orange; // Naranja para desarrollo
      case RuntimeMode.profile:
        return Colors.blue; // Azul para medición
      case RuntimeMode.release:
        return Colors.green; // Verde para producción
    }
  }

  /// Icono representativo del modo.
  IconData get icon {
    switch (this) {
      case RuntimeMode.debug:
        return Icons.bug_report;
      case RuntimeMode.profile:
        return Icons.speed;
      case RuntimeMode.release:
        return Icons.check_circle;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // INFORMACIÓN Y RECOMENDACIONES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Descripción del modo para el usuario.
  String get description {
    switch (this) {
      case RuntimeMode.debug:
        return 'Modo de desarrollo con hot reload.\n'
            'Rendimiento más lento. No usar para mediciones.';
      case RuntimeMode.profile:
        return 'Modo de perfilado con optimizaciones AOT.\n'
            'Usar este modo para medir rendimiento real.';
      case RuntimeMode.release:
        return 'Modo de producción completamente optimizado.\n'
            'Máximo rendimiento sin logs ni asserts.';
    }
  }

  /// Indica si el modo permite mediciones confiables de rendimiento.
  bool get isGoodForProfiling {
    switch (this) {
      case RuntimeMode.debug:
        return false; // Debug es muy lento
      case RuntimeMode.profile:
        return true; // Profile es ideal para mediciones
      case RuntimeMode.release:
        return true; // Release también es válido
    }
  }

  /// Indica si el modo permite debugging.
  bool get isDebuggable {
    switch (this) {
      case RuntimeMode.debug:
        return true;
      case RuntimeMode.profile:
        return false;
      case RuntimeMode.release:
        return false;
    }
  }
}

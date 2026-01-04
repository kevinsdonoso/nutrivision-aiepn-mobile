// ╔═══════════════════════════════════════════════════════════════════════════════╗
// ║                      runtime_mode_indicator.dart                              ║
// ║              Widget para mostrar el modo de ejecución actual                  ║
// ╠═══════════════════════════════════════════════════════════════════════════════╣
// ║  Muestra un chip visual indicando si la app está en DEBUG, PROFILE o RELEASE. ║
// ║  Útil durante desarrollo y mediciones de rendimiento.                         ║
// ╚═══════════════════════════════════════════════════════════════════════════════╝

import 'package:flutter/material.dart';

import '../../core/utils/runtime_mode.dart';

/// Widget que muestra el modo de ejecución actual (DEBUG/PROFILE/RELEASE).
///
/// Útil para:
/// - Saber en qué modo está corriendo la app durante desarrollo
/// - Recordar al usuario que use --profile para mediciones reales
/// - Validar que el APK release esté corriendo en modo release
///
/// Ejemplo de uso:
/// ```dart
/// // En AppBar
/// actions: [
///   const RuntimeModeIndicator(),
///   // ... otros actions
/// ],
/// ```
class RuntimeModeIndicator extends StatelessWidget {
  /// Si debe mostrarse o no el indicador.
  final bool show;

  /// Tamaño del texto del modo.
  final double fontSize;

  /// Si debe mostrar el ícono además del texto.
  final bool showIcon;

  const RuntimeModeIndicator({
    super.key,
    this.show = true,
    this.fontSize = 10,
    this.showIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!show) return const SizedBox.shrink();

    final mode = RuntimeMode.current;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: mode.color.withAlpha(40),
        border: Border.all(color: mode.color, width: 1.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              mode.icon,
              color: mode.color,
              size: fontSize + 2,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            'MODE: ${mode.displayName}',
            style: TextStyle(
              color: mode.color,
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Badge del modo de ejecución para usar en overlays.
///
/// Similar a RuntimeModeIndicator pero optimizado para mostrar
/// sobre la cámara o en posiciones fijas con fondo semitransparente.
class RuntimeModeBadge extends StatelessWidget {
  /// Si debe mostrarse o no el badge.
  final bool show;

  const RuntimeModeBadge({
    super.key,
    this.show = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!show) return const SizedBox.shrink();

    final mode = RuntimeMode.current;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: mode.color.withAlpha(200),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(50),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            mode.icon,
            color: Colors.white,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            mode.displayName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
//                            loading_overlay.dart
//                   Overlay de carga con feedback visual
// ============================================================================
//  Widget que muestra un overlay de carga sobre el contenido actual.
//  Incluye animaciones suaves y mensajes personalizables.
// ============================================================================

import 'package:flutter/material.dart';

/// Tipo de indicador de carga.
enum LoadingIndicatorType {
  /// Indicador circular estandar.
  circular,

  /// Indicador lineal (barra de progreso).
  linear,

  /// Indicador de puntos animados.
  dots,
}

/// Overlay de carga que se muestra sobre el contenido.
///
/// Proporciona feedback visual durante operaciones asincronas.
///
/// Ejemplo de uso:
/// ```dart
/// Stack(
///   children: [
///     // Contenido principal
///     MyContent(),
///     // Overlay de carga
///     if (isLoading)
///       LoadingOverlay(
///         message: 'Procesando imagen...',
///       ),
///   ],
/// )
/// ```
class LoadingOverlay extends StatelessWidget {
  /// Mensaje a mostrar debajo del indicador.
  final String? message;

  /// Tipo de indicador de carga.
  final LoadingIndicatorType indicatorType;

  /// Color del indicador.
  final Color? indicatorColor;

  /// Color de fondo del overlay.
  final Color? backgroundColor;

  /// Opacidad del fondo.
  final double backgroundOpacity;

  /// Si el overlay debe bloquear la interaccion.
  final bool dismissible;

  /// Callback cuando el usuario intenta cerrar el overlay.
  final VoidCallback? onDismiss;

  /// Progreso actual (0.0 - 1.0) para indicador lineal.
  final double? progress;

  const LoadingOverlay({
    super.key,
    this.message,
    this.indicatorType = LoadingIndicatorType.circular,
    this.indicatorColor,
    this.backgroundColor,
    this.backgroundOpacity = 0.7,
    this.dismissible = false,
    this.onDismiss,
    this.progress,
  });

  /// Constructor para carga simple.
  factory LoadingOverlay.simple({String? message}) {
    return LoadingOverlay(message: message);
  }

  /// Constructor para procesamiento de imagen.
  factory LoadingOverlay.imageProcessing() {
    return const LoadingOverlay(
      message: 'Procesando imagen...',
      indicatorType: LoadingIndicatorType.circular,
    );
  }

  /// Constructor para deteccion de ingredientes.
  factory LoadingOverlay.detecting() {
    return const LoadingOverlay(
      message: 'Detectando ingredientes...',
      indicatorType: LoadingIndicatorType.circular,
    );
  }

  /// Constructor para carga de datos.
  factory LoadingOverlay.loadingData() {
    return const LoadingOverlay(
      message: 'Cargando datos...',
      indicatorType: LoadingIndicatorType.circular,
    );
  }

  /// Constructor con progreso.
  factory LoadingOverlay.withProgress({
    required double progress,
    String? message,
  }) {
    return LoadingOverlay(
      message: message,
      indicatorType: LoadingIndicatorType.linear,
      progress: progress,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveIndicatorColor =
        indicatorColor ?? theme.colorScheme.primary;
    final effectiveBackgroundColor =
        backgroundColor ?? theme.colorScheme.surface;

    return GestureDetector(
      onTap: dismissible ? onDismiss : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        color: Colors.black.withAlpha((backgroundOpacity * 255).round()),
        child: Center(
          child: Card(
            elevation: 8,
            color: effectiveBackgroundColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildIndicator(effectiveIndicatorColor),
                  if (message != null) ...[
                    const SizedBox(height: 20),
                    Text(
                      message!,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIndicator(Color color) {
    switch (indicatorType) {
      case LoadingIndicatorType.circular:
        return SizedBox(
          width: 48,
          height: 48,
          child: CircularProgressIndicator(
            color: color,
            strokeWidth: 4,
          ),
        );

      case LoadingIndicatorType.linear:
        return SizedBox(
          width: 200,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  color: color,
                  backgroundColor: color.withAlpha(50),
                  minHeight: 8,
                ),
              ),
              if (progress != null) ...[
                const SizedBox(height: 8),
                Text(
                  '${(progress! * 100).toInt()}%',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        );

      case LoadingIndicatorType.dots:
        return const _AnimatedDotsIndicator();
    }
  }
}

/// Indicador de puntos animados.
class _AnimatedDotsIndicator extends StatefulWidget {
  const _AnimatedDotsIndicator();

  @override
  State<_AnimatedDotsIndicator> createState() => _AnimatedDotsIndicatorState();
}

class _AnimatedDotsIndicatorState extends State<_AnimatedDotsIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final animValue =
                ((_controller.value - delay) % 1.0).clamp(0.0, 1.0);
            final scale = 0.5 + (0.5 * _bounceValue(animValue));

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color.withAlpha((scale * 255).round()),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  double _bounceValue(double value) {
    if (value < 0.5) {
      return value * 2;
    } else {
      return 2 - (value * 2);
    }
  }
}

/// Widget que envuelve contenido con un overlay de carga condicional.
///
/// Ejemplo de uso:
/// ```dart
/// LoadingWrapper(
///   isLoading: _isProcessing,
///   message: 'Procesando...',
///   child: MyContent(),
/// )
/// ```
class LoadingWrapper extends StatelessWidget {
  /// Contenido principal.
  final Widget child;

  /// Si mostrar el overlay de carga.
  final bool isLoading;

  /// Mensaje del overlay.
  final String? message;

  /// Tipo de indicador.
  final LoadingIndicatorType indicatorType;

  /// Progreso actual.
  final double? progress;

  const LoadingWrapper({
    super.key,
    required this.child,
    required this.isLoading,
    this.message,
    this.indicatorType = LoadingIndicatorType.circular,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          LoadingOverlay(
            message: message,
            indicatorType: indicatorType,
            progress: progress,
          ),
      ],
    );
  }
}

/// Boton con estado de carga integrado.
///
/// Ejemplo de uso:
/// ```dart
/// LoadingButton(
///   text: 'Guardar',
///   isLoading: _isSaving,
///   onPressed: _handleSave,
/// )
/// ```
class LoadingButton extends StatelessWidget {
  /// Texto del boton.
  final String text;

  /// Icono opcional.
  final IconData? icon;

  /// Si esta cargando.
  final bool isLoading;

  /// Callback cuando se presiona.
  final VoidCallback? onPressed;

  /// Texto alternativo durante carga.
  final String? loadingText;

  /// Estilo del boton.
  final ButtonStyle? style;

  /// Si es un boton de texto.
  final bool isTextButton;

  /// Si es un boton outlined.
  final bool isOutlined;

  const LoadingButton({
    super.key,
    required this.text,
    this.icon,
    required this.isLoading,
    this.onPressed,
    this.loadingText,
    this.style,
    this.isTextButton = false,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = isLoading ? null : onPressed;

    final child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
        else if (icon != null)
          Icon(icon, size: 20),
        if (icon != null || isLoading) const SizedBox(width: 8),
        Text(isLoading ? (loadingText ?? text) : text),
      ],
    );

    if (isTextButton) {
      return TextButton(
        onPressed: effectiveOnPressed,
        style: style,
        child: child,
      );
    }

    if (isOutlined) {
      return OutlinedButton(
        onPressed: effectiveOnPressed,
        style: style,
        child: child,
      );
    }

    return ElevatedButton(
      onPressed: effectiveOnPressed,
      style: style,
      child: child,
    );
  }
}

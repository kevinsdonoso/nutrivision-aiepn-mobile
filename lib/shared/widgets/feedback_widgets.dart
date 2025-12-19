// ============================================================================
//                           feedback_widgets.dart
//                 Widgets de feedback visual para el usuario
// ============================================================================
//  Coleccion de widgets para proporcionar feedback visual consistente
//  incluyendo animaciones de exito, error, advertencia e informacion.
// ============================================================================

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Tipo de feedback visual.
enum FeedbackType {
  /// Operacion exitosa.
  success,

  /// Error en la operacion.
  error,

  /// Advertencia.
  warning,

  /// Informacion.
  info,
}

/// Extension para obtener propiedades visuales de cada tipo de feedback.
extension FeedbackTypeExtension on FeedbackType {
  /// Color principal del feedback.
  Color get color {
    switch (this) {
      case FeedbackType.success:
        return AppColors.success;
      case FeedbackType.error:
        return AppColors.error;
      case FeedbackType.warning:
        return AppColors.warning;
      case FeedbackType.info:
        return AppColors.info;
    }
  }

  /// Icono por defecto del feedback.
  IconData get icon {
    switch (this) {
      case FeedbackType.success:
        return Icons.check_circle;
      case FeedbackType.error:
        return Icons.error;
      case FeedbackType.warning:
        return Icons.warning_amber_rounded;
      case FeedbackType.info:
        return Icons.info;
    }
  }

  /// Titulo por defecto del feedback.
  String get defaultTitle {
    switch (this) {
      case FeedbackType.success:
        return 'Exito';
      case FeedbackType.error:
        return 'Error';
      case FeedbackType.warning:
        return 'Advertencia';
      case FeedbackType.info:
        return 'Informacion';
    }
  }
}

/// Animacion de feedback con icono y mensaje.
///
/// Muestra una animacion de entrada suave con un icono
/// que representa el estado de la operacion.
///
/// Ejemplo de uso:
/// ```dart
/// FeedbackAnimation.success(
///   message: 'Perfil guardado correctamente',
///   onComplete: () => Navigator.pop(context),
/// )
/// ```
class FeedbackAnimation extends StatefulWidget {
  /// Tipo de feedback.
  final FeedbackType type;

  /// Mensaje a mostrar.
  final String? message;

  /// Titulo opcional.
  final String? title;

  /// Callback cuando la animacion termina.
  final VoidCallback? onComplete;

  /// Duracion de la animacion.
  final Duration animationDuration;

  /// Duracion que se muestra el feedback antes de llamar onComplete.
  final Duration displayDuration;

  /// Tamano del icono.
  final double iconSize;

  /// Si mostrar como overlay.
  final bool asOverlay;

  const FeedbackAnimation({
    super.key,
    required this.type,
    this.message,
    this.title,
    this.onComplete,
    this.animationDuration = const Duration(milliseconds: 600),
    this.displayDuration = const Duration(seconds: 2),
    this.iconSize = 72,
    this.asOverlay = false,
  });

  /// Constructor para exito.
  factory FeedbackAnimation.success({
    String? message,
    String? title,
    VoidCallback? onComplete,
  }) {
    return FeedbackAnimation(
      type: FeedbackType.success,
      message: message,
      title: title ?? 'Exito',
      onComplete: onComplete,
    );
  }

  /// Constructor para error.
  factory FeedbackAnimation.error({
    String? message,
    String? title,
    VoidCallback? onComplete,
  }) {
    return FeedbackAnimation(
      type: FeedbackType.error,
      message: message,
      title: title ?? 'Error',
      onComplete: onComplete,
    );
  }

  /// Constructor para advertencia.
  factory FeedbackAnimation.warning({
    String? message,
    String? title,
    VoidCallback? onComplete,
  }) {
    return FeedbackAnimation(
      type: FeedbackType.warning,
      message: message,
      title: title ?? 'Advertencia',
      onComplete: onComplete,
    );
  }

  /// Constructor para informacion.
  factory FeedbackAnimation.info({
    String? message,
    String? title,
    VoidCallback? onComplete,
  }) {
    return FeedbackAnimation(
      type: FeedbackType.info,
      message: message,
      title: title ?? 'Informacion',
      onComplete: onComplete,
    );
  }

  @override
  State<FeedbackAnimation> createState() => _FeedbackAnimationState();
}

class _FeedbackAnimationState extends State<FeedbackAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _checkAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.2)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 40,
      ),
    ]).animate(_controller);

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _checkAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward().then((_) {
      if (widget.onComplete != null) {
        Future.delayed(widget.displayDuration, () {
          if (mounted) {
            widget.onComplete!();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = widget.type.color;

    final content = AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icono animado
              Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  width: widget.iconSize + 24,
                  height: widget.iconSize + 24,
                  decoration: BoxDecoration(
                    color: color.withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: _buildAnimatedIcon(color),
                  ),
                ),
              ),

              if (widget.title != null) ...[
                const SizedBox(height: 20),
                Text(
                  widget.title!,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],

              if (widget.message != null) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    widget.message!,
                    style: theme.textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );

    if (widget.asOverlay) {
      return Container(
        color: theme.colorScheme.surface.withAlpha(240),
        child: Center(child: content),
      );
    }

    return content;
  }

  Widget _buildAnimatedIcon(Color color) {
    if (widget.type == FeedbackType.success) {
      return CustomPaint(
        size: Size(widget.iconSize, widget.iconSize),
        painter: _CheckmarkPainter(
          progress: _checkAnimation.value,
          color: color,
          strokeWidth: 6,
        ),
      );
    }

    return Icon(
      widget.type.icon,
      size: widget.iconSize,
      color: color,
    );
  }
}

/// Painter para dibujar un checkmark animado.
class _CheckmarkPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _CheckmarkPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();

    // Punto inicial (izquierda del check)
    final start = Offset(size.width * 0.2, size.height * 0.5);
    // Punto medio (parte baja del check)
    final middle = Offset(size.width * 0.4, size.height * 0.7);
    // Punto final (derecha arriba del check)
    final end = Offset(size.width * 0.8, size.height * 0.3);

    if (progress <= 0.5) {
      // Primera parte del check (de start a middle)
      final t = progress * 2;
      path.moveTo(start.dx, start.dy);
      path.lineTo(
        start.dx + (middle.dx - start.dx) * t,
        start.dy + (middle.dy - start.dy) * t,
      );
    } else {
      // Check completo
      path.moveTo(start.dx, start.dy);
      path.lineTo(middle.dx, middle.dy);

      // Segunda parte del check (de middle a end)
      final t = (progress - 0.5) * 2;
      path.lineTo(
        middle.dx + (end.dx - middle.dx) * t,
        middle.dy + (end.dy - middle.dy) * t,
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CheckmarkPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Snackbar personalizado con feedback visual.
///
/// Proporciona una manera consistente de mostrar mensajes temporales.
///
/// Ejemplo de uso:
/// ```dart
/// FeedbackSnackbar.success(
///   context,
///   message: 'Cambios guardados',
/// );
/// ```
class FeedbackSnackbar {
  FeedbackSnackbar._();

  /// Muestra un snackbar de exito.
  static void success(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    _show(
      context,
      type: FeedbackType.success,
      message: message,
      duration: duration,
      onAction: onAction,
      actionLabel: actionLabel,
    );
  }

  /// Muestra un snackbar de error.
  static void error(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    _show(
      context,
      type: FeedbackType.error,
      message: message,
      duration: duration,
      onAction: onAction,
      actionLabel: actionLabel,
    );
  }

  /// Muestra un snackbar de advertencia.
  static void warning(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    _show(
      context,
      type: FeedbackType.warning,
      message: message,
      duration: duration,
      onAction: onAction,
      actionLabel: actionLabel,
    );
  }

  /// Muestra un snackbar informativo.
  static void info(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    _show(
      context,
      type: FeedbackType.info,
      message: message,
      duration: duration,
      onAction: onAction,
      actionLabel: actionLabel,
    );
  }

  static void _show(
    BuildContext context, {
    required FeedbackType type,
    required String message,
    required Duration duration,
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(
            type.icon,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      backgroundColor: type.color,
      duration: duration,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      action: onAction != null
          ? SnackBarAction(
              label: actionLabel ?? 'Ver',
              textColor: Colors.white,
              onPressed: onAction,
            )
          : null,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}

/// Banner de estado para mostrar informacion persistente.
///
/// Ejemplo de uso:
/// ```dart
/// StatusBanner.offline()
/// ```
class StatusBanner extends StatelessWidget {
  /// Tipo de feedback.
  final FeedbackType type;

  /// Mensaje a mostrar.
  final String message;

  /// Icono opcional.
  final IconData? icon;

  /// Callback para accion.
  final VoidCallback? onAction;

  /// Etiqueta de la accion.
  final String? actionLabel;

  /// Si se puede descartar.
  final bool dismissible;

  /// Callback cuando se descarta.
  final VoidCallback? onDismiss;

  const StatusBanner({
    super.key,
    required this.type,
    required this.message,
    this.icon,
    this.onAction,
    this.actionLabel,
    this.dismissible = false,
    this.onDismiss,
  });

  /// Banner de conexion offline.
  factory StatusBanner.offline() {
    return const StatusBanner(
      type: FeedbackType.warning,
      message: 'Sin conexion a internet',
      icon: Icons.wifi_off,
    );
  }

  /// Banner de sincronizacion en progreso.
  factory StatusBanner.syncing() {
    return const StatusBanner(
      type: FeedbackType.info,
      message: 'Sincronizando datos...',
      icon: Icons.sync,
    );
  }

  /// Banner de error de conexion.
  factory StatusBanner.connectionError({VoidCallback? onRetry}) {
    return StatusBanner(
      type: FeedbackType.error,
      message: 'Error de conexion',
      icon: Icons.error_outline,
      onAction: onRetry,
      actionLabel: 'Reintentar',
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveIcon = icon ?? type.icon;

    return Material(
      color: type.color,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(
                effectiveIcon,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (onAction != null)
                TextButton(
                  onPressed: onAction,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: Text(actionLabel ?? 'Accion'),
                ),
              if (dismissible)
                IconButton(
                  onPressed: onDismiss,
                  icon: const Icon(Icons.close, color: Colors.white, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dialogo de confirmacion con feedback visual.
///
/// Ejemplo de uso:
/// ```dart
/// final result = await FeedbackDialog.confirm(
///   context,
///   title: 'Eliminar foto',
///   message: 'Esta seguro de eliminar esta foto?',
///   confirmText: 'Eliminar',
///   isDestructive: true,
/// );
/// ```
class FeedbackDialog {
  FeedbackDialog._();

  /// Muestra un dialogo de confirmacion.
  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirmar',
    String cancelText = 'Cancelar',
    bool isDestructive = false,
    IconData? icon,
  }) async {
    final theme = Theme.of(context);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: icon != null
            ? Icon(
                icon,
                color: isDestructive ? AppColors.error : theme.colorScheme.primary,
                size: 48,
              )
            : null,
        title: Text(title),
        content: Text(message),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: isDestructive
                ? ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                  )
                : null,
            child: Text(confirmText),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  /// Muestra un dialogo de exito.
  static Future<void> success(
    BuildContext context, {
    required String title,
    String? message,
    String buttonText = 'Aceptar',
    VoidCallback? onDismiss,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: FeedbackAnimation.success(
          title: title,
          message: message,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onDismiss?.call();
              },
              child: Text(buttonText),
            ),
          ),
        ],
      ),
    );
  }

  /// Muestra un dialogo de error.
  static Future<void> error(
    BuildContext context, {
    required String title,
    String? message,
    String buttonText = 'Entendido',
    VoidCallback? onRetry,
    String retryText = 'Reintentar',
  }) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.error_outline,
          color: AppColors.error,
          size: 48,
        ),
        title: Text(title),
        content: message != null ? Text(message) : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          if (onRetry != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              child: Text(retryText),
            ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }
}

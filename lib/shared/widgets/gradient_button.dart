// ╔═══════════════════════════════════════════════════════════════════════════════╗
// ║                          gradient_button.dart                                 ║
// ║                    Botón con gradiente personalizable                         ║
// ╠═══════════════════════════════════════════════════════════════════════════════╣
// ║  Widget de botón reutilizable con gradiente, iconos y animaciones.           ║
// ║  Parte del sistema de diseño de NutriVision.                                  ║
// ╚═══════════════════════════════════════════════════════════════════════════════╝

import 'package:flutter/material.dart';

/// Botón con gradiente personalizable.
///
/// Soporta texto, icono, loading state y diferentes tamaños.
///
/// Ejemplo de uso:
/// ```dart
/// GradientButton(
///   text: 'Detectar',
///   icon: Icons.camera_alt,
///   gradient: LinearGradient(...),
///   onPressed: () => print('Pressed'),
/// )
/// ```
class GradientButton extends StatefulWidget {
  /// Texto del botón.
  final String text;

  /// Icono opcional.
  final IconData? icon;

  /// Gradiente de fondo.
  final Gradient gradient;

  /// Callback cuando se presiona.
  final VoidCallback? onPressed;

  /// Si está en estado de carga.
  final bool isLoading;

  /// Tamaño del botón.
  final GradientButtonSize size;

  /// Radio de las esquinas.
  final double? borderRadius;

  /// Elevación del botón.
  final double elevation;

  const GradientButton({
    super.key,
    required this.text,
    required this.gradient,
    this.icon,
    this.onPressed,
    this.isLoading = false,
    this.size = GradientButtonSize.medium,
    this.borderRadius,
    this.elevation = 4,
  });

  /// Constructor para botón primario (verde).
  factory GradientButton.primary({
    required String text,
    IconData? icon,
    VoidCallback? onPressed,
    bool isLoading = false,
    GradientButtonSize size = GradientButtonSize.medium,
  }) {
    return GradientButton(
      text: text,
      icon: icon,
      onPressed: onPressed,
      isLoading: isLoading,
      size: size,
      gradient: const LinearGradient(
        colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    );
  }

  /// Constructor para botón secundario (naranja).
  factory GradientButton.secondary({
    required String text,
    IconData? icon,
    VoidCallback? onPressed,
    bool isLoading = false,
    GradientButtonSize size = GradientButtonSize.medium,
  }) {
    return GradientButton(
      text: text,
      icon: icon,
      onPressed: onPressed,
      isLoading: isLoading,
      size: size,
      gradient: const LinearGradient(
        colors: [Color(0xFFFF9800), Color(0xFFE65100)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    );
  }

  /// Constructor para botón de acento (azul).
  factory GradientButton.accent({
    required String text,
    IconData? icon,
    VoidCallback? onPressed,
    bool isLoading = false,
    GradientButtonSize size = GradientButtonSize.medium,
  }) {
    return GradientButton(
      text: text,
      icon: icon,
      onPressed: onPressed,
      isLoading: isLoading,
      size: size,
      gradient: const LinearGradient(
        colors: [Color(0xFF2196F3), Color(0xFF0D47A1)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    );
  }

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      setState(() => _isPressed = true);
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null && !widget.isLoading;
    final dimensions = widget.size.dimensions;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: isEnabled ? widget.onPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: dimensions.height,
          decoration: BoxDecoration(
            gradient: isEnabled
                ? widget.gradient
                : LinearGradient(
                    colors: [Colors.grey.shade400, Colors.grey.shade500],
                  ),
            borderRadius: BorderRadius.circular(
              widget.borderRadius ?? dimensions.borderRadius,
            ),
            boxShadow: isEnabled && !_isPressed
                ? [
                    BoxShadow(
                      color: Colors.black.withAlpha(51), // 0.2 * 255 ≈ 51
                      blurRadius: widget.elevation * 2,
                      offset: Offset(0, widget.elevation),
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isEnabled ? widget.onPressed : null,
              borderRadius: BorderRadius.circular(
                widget.borderRadius ?? dimensions.borderRadius,
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: dimensions.horizontalPadding,
                  vertical: dimensions.verticalPadding,
                ),
                child: _buildContent(dimensions),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(ButtonDimensions dimensions) {
    if (widget.isLoading) {
      return Center(
        child: SizedBox(
          width: dimensions.iconSize,
          height: dimensions.iconSize,
          child: const CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        ),
      );
    }

    final hasIcon = widget.icon != null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (hasIcon) ...[
          Icon(
            widget.icon,
            color: Colors.white,
            size: dimensions.iconSize,
          ),
          SizedBox(width: dimensions.spacing),
        ],
        Text(
          widget.text,
          style: TextStyle(
            color: Colors.white,
            fontSize: dimensions.fontSize,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

/// Tamaños predefinidos para el botón.
enum GradientButtonSize {
  small,
  medium,
  large;

  ButtonDimensions get dimensions {
    switch (this) {
      case GradientButtonSize.small:
        return const ButtonDimensions(
          height: 40,
          horizontalPadding: 16,
          verticalPadding: 8,
          fontSize: 14,
          iconSize: 18,
          spacing: 6,
          borderRadius: 8,
        );
      case GradientButtonSize.medium:
        return const ButtonDimensions(
          height: 48,
          horizontalPadding: 24,
          verticalPadding: 12,
          fontSize: 16,
          iconSize: 20,
          spacing: 8,
          borderRadius: 12,
        );
      case GradientButtonSize.large:
        return const ButtonDimensions(
          height: 56,
          horizontalPadding: 32,
          verticalPadding: 16,
          fontSize: 18,
          iconSize: 24,
          spacing: 10,
          borderRadius: 16,
        );
    }
  }
}

/// Dimensiones del botón.
class ButtonDimensions {
  final double height;
  final double horizontalPadding;
  final double verticalPadding;
  final double fontSize;
  final double iconSize;
  final double spacing;
  final double borderRadius;

  const ButtonDimensions({
    required this.height,
    required this.horizontalPadding,
    required this.verticalPadding,
    required this.fontSize,
    required this.iconSize,
    required this.spacing,
    required this.borderRadius,
  });
}

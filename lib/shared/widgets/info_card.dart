// ╔═══════════════════════════════════════════════════════════════════════════════╗
// ║                             info_card.dart                                    ║
// ║                   Card informativa reutilizable                               ║
// ╠═══════════════════════════════════════════════════════════════════════════════╣
// ║  Widget de card genérica para mostrar información con estilo consistente.     ║
// ║  Soporta íconos, colores personalizados y animaciones.                        ║
// ╚═══════════════════════════════════════════════════════════════════════════════╝

import 'package:flutter/material.dart';

/// Card informativa con estilo personalizable.
///
/// Diseñada para mostrar información de manera consistente
/// a través de toda la aplicación.
///
/// Ejemplo de uso:
/// ```dart
/// InfoCard(
///   icon: Icons.info,
///   title: 'Información',
///   subtitle: 'Detalles adicionales',
///   color: Colors.blue,
///   onTap: () => print('Tapped'),
/// )
/// ```
class InfoCard extends StatefulWidget {
  /// Icono a mostrar.
  final IconData icon;

  /// Título principal.
  final String title;

  /// Subtítulo opcional.
  final String? subtitle;

  /// Widget personalizado para el contenido (opcional).
  final Widget? content;

  /// Color principal de la card.
  final Color color;

  /// Callback cuando se presiona la card.
  final VoidCallback? onTap;

  /// Si mostrar la flecha de navegación.
  final bool showChevron;

  /// Elevación de la card.
  final double elevation;

  /// Estilo de la card.
  final InfoCardStyle style;

  const InfoCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.content,
    this.color = const Color(0xFF4CAF50),
    this.onTap,
    this.showChevron = true,
    this.elevation = 2,
    this.style = InfoCardStyle.elevated,
  });

  /// Constructor para card de información.
  factory InfoCard.info({
    required String title,
    String? subtitle,
    Widget? content,
    VoidCallback? onTap,
  }) {
    return InfoCard(
      icon: Icons.info_outline,
      title: title,
      subtitle: subtitle,
      content: content,
      color: const Color(0xFF2196F3),
      onTap: onTap,
    );
  }

  /// Constructor para card de éxito.
  factory InfoCard.success({
    required String title,
    String? subtitle,
    Widget? content,
    VoidCallback? onTap,
  }) {
    return InfoCard(
      icon: Icons.check_circle_outline,
      title: title,
      subtitle: subtitle,
      content: content,
      color: const Color(0xFF4CAF50),
      onTap: onTap,
    );
  }

  /// Constructor para card de advertencia.
  factory InfoCard.warning({
    required String title,
    String? subtitle,
    Widget? content,
    VoidCallback? onTap,
  }) {
    return InfoCard(
      icon: Icons.warning_amber_rounded,
      title: title,
      subtitle: subtitle,
      content: content,
      color: const Color(0xFFFF9800),
      onTap: onTap,
    );
  }

  /// Constructor para card de error.
  factory InfoCard.error({
    required String title,
    String? subtitle,
    Widget? content,
    VoidCallback? onTap,
  }) {
    return InfoCard(
      icon: Icons.error_outline,
      title: title,
      subtitle: subtitle,
      content: content,
      color: const Color(0xFFE53935),
      onTap: onTap,
    );
  }

  @override
  State<InfoCard> createState() => _InfoCardState();
}

class _InfoCardState extends State<InfoCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap != null) {
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: widget.onTap,
        child: Card(
          elevation: widget.style == InfoCardStyle.elevated
              ? widget.elevation
              : 0,
          color: widget.style == InfoCardStyle.filled
              ? widget.color.withAlpha(26) // 0.1 * 255 ≈ 26
              : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: widget.style == InfoCardStyle.outlined
                ? BorderSide(color: widget.color, width: 2)
                : BorderSide.none,
          ),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Icono
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: widget.color.withAlpha(26), // 0.1 * 255 ≈ 26
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          widget.icon,
                          color: widget.color,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Textos
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: widget.style == InfoCardStyle.filled
                                    ? widget.color
                                    : null,
                              ),
                            ),
                            if (widget.subtitle != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                widget.subtitle!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Chevron
                      if (widget.onTap != null && widget.showChevron)
                        Icon(
                          Icons.chevron_right,
                          color: widget.color,
                        ),
                    ],
                  ),
                  // Contenido adicional
                  if (widget.content != null) ...[
                    const SizedBox(height: 12),
                    widget.content!,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Estilos disponibles para InfoCard.
enum InfoCardStyle {
  /// Card elevada (con sombra).
  elevated,

  /// Card con borde.
  outlined,

  /// Card con fondo de color.
  filled,
}

/// Card compacta para listas.
class InfoCardCompact extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? value;
  final Color color;
  final VoidCallback? onTap;

  const InfoCardCompact({
    super.key,
    required this.icon,
    required this.title,
    this.value,
    this.color = const Color(0xFF4CAF50),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              if (value != null)
                Text(
                  value!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              if (onTap != null) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey[400],
                  size: 20,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Card estadística con número grande.
class StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? unit;
  final Color color;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.unit,
    this.color = const Color(0xFF4CAF50),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icono
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withAlpha(26), // 0.1 * 255 ≈ 26
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(height: 12),
              // Label
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              // Valor
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    value,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  if (unit != null) ...[
                    const SizedBox(width: 4),
                    Text(
                      unit!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

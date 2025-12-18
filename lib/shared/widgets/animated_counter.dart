// ╔═══════════════════════════════════════════════════════════════════════════════╗
// ║                         animated_counter.dart                                 ║
// ║                 Contador animado para valores numéricos                       ║
// ╠═══════════════════════════════════════════════════════════════════════════════╣
// ║  Widget que anima transiciones entre valores numéricos.                       ║
// ║  Ideal para mostrar calorías, nutrientes y estadísticas.                      ║
// ╚═══════════════════════════════════════════════════════════════════════════════╝

import 'package:flutter/material.dart';

/// Contador animado que transiciona entre valores.
///
/// Anima el cambio de un valor numérico a otro con una
/// animación suave y personalizable.
///
/// Ejemplo de uso:
/// ```dart
/// AnimatedCounter(
///   value: 250.5,
///   unit: 'kcal',
///   decimals: 1,
///   style: TextStyle(fontSize: 32),
/// )
/// ```
class AnimatedCounter extends StatefulWidget {
  /// Valor a mostrar.
  final double value;

  /// Unidad del valor (ej: 'kcal', 'g').
  final String? unit;

  /// Número de decimales a mostrar.
  final int decimals;

  /// Duración de la animación.
  final Duration duration;

  /// Curva de animación.
  final Curve curve;

  /// Estilo del texto.
  final TextStyle? style;

  /// Estilo de la unidad.
  final TextStyle? unitStyle;

  /// Color del texto.
  final Color? color;

  /// Si mostrar separador de miles.
  final bool useThousandsSeparator;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.unit,
    this.decimals = 0,
    this.duration = const Duration(milliseconds: 800),
    this.curve = Curves.easeOutCubic,
    this.style,
    this.unitStyle,
    this.color,
    this.useThousandsSeparator = false,
  });

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _previousValue = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _animation = Tween<double>(
      begin: _previousValue,
      end: widget.value,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.value != widget.value) {
      _previousValue = oldWidget.value;
      _animation = Tween<double>(
        begin: _previousValue,
        end: widget.value,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: widget.curve,
      ));

      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatNumber(double value) {
    final formatted = value.toStringAsFixed(widget.decimals);

    if (widget.useThousandsSeparator) {
      final parts = formatted.split('.');
      final intPart = parts[0];
      final decPart = parts.length > 1 ? '.${parts[1]}' : '';

      // Agregar separadores de miles
      final regex = RegExp(r'\B(?=(\d{3})+(?!\d))');
      final withSeparators = intPart.replaceAllMapped(
        regex,
        (match) => ',',
      );

      return '$withSeparators$decPart';
    }

    return formatted;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultStyle = widget.style ??
        theme.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: widget.color,
        );

    final defaultUnitStyle = widget.unitStyle ??
        theme.textTheme.bodyLarge?.copyWith(
          color: widget.color?.withAlpha(179) ?? Colors.grey[600], // 0.7 * 255 ≈ 179
        );

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              _formatNumber(_animation.value),
              style: defaultStyle,
            ),
            if (widget.unit != null) ...[
              const SizedBox(width: 4),
              Text(
                widget.unit!,
                style: defaultUnitStyle,
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Contador animado con icono y etiqueta.
class AnimatedCounterWithLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final double value;
  final String? unit;
  final int decimals;
  final Color color;
  final Duration duration;

  const AnimatedCounterWithLabel({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.unit,
    this.decimals = 0,
    this.color = const Color(0xFF4CAF50),
    this.duration = const Duration(milliseconds: 800),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Icono
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withAlpha(26), // 0.1 * 255 ≈ 26
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        // Label
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        // Counter
        AnimatedCounter(
          value: value,
          unit: unit,
          decimals: decimals,
          duration: duration,
          color: color,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// Contador compacto horizontal.
class AnimatedCounterCompact extends StatelessWidget {
  final IconData icon;
  final double value;
  final String? unit;
  final int decimals;
  final Color color;
  final Duration duration;

  const AnimatedCounterCompact({
    super.key,
    required this.icon,
    required this.value,
    this.unit,
    this.decimals = 0,
    this.color = const Color(0xFF4CAF50),
    this.duration = const Duration(milliseconds: 800),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(26), // 0.1 * 255 ≈ 26
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 6),
          AnimatedCounter(
            value: value,
            unit: unit,
            decimals: decimals,
            duration: duration,
            color: color,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }
}

/// Grid de contadores para nutrientes.
class NutrientCountersGrid extends StatelessWidget {
  final double calories;
  final double protein;
  final double fat;
  final double carbs;
  final Duration duration;

  const NutrientCountersGrid({
    super.key,
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
    this.duration = const Duration(milliseconds: 1000),
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AnimatedCounterWithLabel(
            icon: Icons.local_fire_department,
            label: 'Calorías',
            value: calories,
            unit: 'kcal',
            color: const Color(0xFFFF9800),
            duration: duration,
          ),
        ),
        Expanded(
          child: AnimatedCounterWithLabel(
            icon: Icons.fitness_center,
            label: 'Proteínas',
            value: protein,
            unit: 'g',
            decimals: 1,
            color: const Color(0xFFE53935),
            duration: duration,
          ),
        ),
        Expanded(
          child: AnimatedCounterWithLabel(
            icon: Icons.water_drop,
            label: 'Grasas',
            value: fat,
            unit: 'g',
            decimals: 1,
            color: const Color(0xFFFFA726),
            duration: duration,
          ),
        ),
        Expanded(
          child: AnimatedCounterWithLabel(
            icon: Icons.grain,
            label: 'Carbohidratos',
            value: carbs,
            unit: 'g',
            decimals: 1,
            color: const Color(0xFF2196F3),
            duration: duration,
          ),
        ),
      ],
    );
  }
}

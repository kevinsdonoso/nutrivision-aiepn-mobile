// ╔═══════════════════════════════════════════════════════════════════════════════╗
// ║                            nutrient_bar.dart                                  ║
// ║                   Barra de progreso para nutrientes                           ║
// ╠═══════════════════════════════════════════════════════════════════════════════╣
// ║  Widget que muestra un nutriente con barra de progreso visual.                ║
// ║  Incluye etiqueta, valor y porcentaje del máximo.                             ║
// ╚═══════════════════════════════════════════════════════════════════════════════╝

import 'package:flutter/material.dart';

/// Barra de progreso para visualizar un nutriente.
///
/// Muestra el nombre del nutriente, su valor con unidad,
/// y una barra de progreso proporcional al valor máximo.
///
/// Ejemplo de uso:
/// ```dart
/// NutrientBar(
///   label: 'Calorías',
///   value: 200,
///   maxValue: 500,
///   unit: 'kcal',
///   color: Colors.orange,
/// )
/// ```
class NutrientBar extends StatelessWidget {
  /// Nombre del nutriente.
  final String label;

  /// Valor actual del nutriente.
  final double value;

  /// Valor máximo para calcular el porcentaje de la barra.
  final double maxValue;

  /// Unidad de medida (e.g., 'g', 'kcal').
  final String unit;

  /// Color de la barra de progreso.
  final Color color;

  /// Si mostrar decimales en el valor.
  final bool showDecimals;

  const NutrientBar({
    super.key,
    required this.label,
    required this.value,
    required this.maxValue,
    required this.unit,
    required this.color,
    this.showDecimals = true,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = maxValue > 0 ? (value / maxValue).clamp(0.0, 1.0) : 0.0;
    final valueText = showDecimals
        ? value.toStringAsFixed(1)
        : value.toStringAsFixed(0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header con label y valor
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            Text(
              '$valueText $unit',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // Barra de progreso
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage,
            backgroundColor: color.withAlpha(38), // 0.15 * 255 ≈ 38
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}

/// Barra compacta para nutriente (sin header separado).
class NutrientBarCompact extends StatelessWidget {
  final String label;
  final double value;
  final String unit;
  final Color color;
  final double maxValue;

  const NutrientBarCompact({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    this.maxValue = 100,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = maxValue > 0 ? (value / maxValue).clamp(0.0, 1.0) : 0.0;

    return Row(
      children: [
        // Label
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        // Barra
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: color.withAlpha(38), // 0.15 * 255 ≈ 38
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Valor
        SizedBox(
          width: 60,
          child: Text(
            '${value.toStringAsFixed(1)} $unit',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

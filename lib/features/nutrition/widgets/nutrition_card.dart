// ╔═══════════════════════════════════════════════════════════════════════════════╗
// ║                           nutrition_card.dart                                 ║
// ║              Card para mostrar información nutricional                        ║
// ╠═══════════════════════════════════════════════════════════════════════════════╣
// ║  Widget que muestra información nutricional de un alimento detectado.         ║
// ║  Incluye nombre, match score, y barras de nutrientes.                         ║
// ╚═══════════════════════════════════════════════════════════════════════════════╝

import 'package:flutter/material.dart';

import '../../../data/models/nutrition_info.dart';
import 'nutrient_bar.dart';

/// Card que muestra información nutricional completa.
///
/// Presenta el nombre del alimento, su match score con la base de datos,
/// y barras de progreso para los principales macronutrientes.
///
/// Ejemplo de uso:
/// ```dart
/// NutritionCard(
///   nutrition: nutritionInfo,
///   confidence: 0.85,
/// )
/// ```
class NutritionCard extends StatelessWidget {
  /// Información nutricional a mostrar.
  final NutritionInfo nutrition;

  /// Confianza de la detección (opcional, 0-1).
  final double? confidence;

  /// Si expandir los detalles por defecto.
  final bool initiallyExpanded;

  const NutritionCard({
    super.key,
    required this.nutrition,
    this.confidence,
    this.initiallyExpanded = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nutrients = nutrition.nutrients;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: nombre + badges
            _buildHeader(context, theme),

            // Descripción FDC (si existe)
            if (nutrition.fdcDescription != null) ...[
              const SizedBox(height: 4),
              Text(
                nutrition.fdcDescription!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],

            const Divider(height: 24),

            // Barras de nutrientes
            NutrientBar(
              label: 'Calorías',
              value: nutrients.energyKcal,
              maxValue: 500,
              unit: 'kcal',
              color: Colors.orange,
              showDecimals: false,
            ),
            const SizedBox(height: 12),
            NutrientBar(
              label: 'Proteínas',
              value: nutrients.proteinG,
              maxValue: 50,
              unit: 'g',
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 12),
            NutrientBar(
              label: 'Grasas',
              value: nutrients.fatG,
              maxValue: 50,
              unit: 'g',
              color: Colors.amber,
            ),
            const SizedBox(height: 12),
            NutrientBar(
              label: 'Carbohidratos',
              value: nutrients.carbohydratesG,
              maxValue: 100,
              unit: 'g',
              color: Colors.blue,
            ),

            // Fibra y azúcares (compactos)
            if (nutrients.fiberG > 0 || nutrients.sugarsG > 0) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (nutrients.fiberG > 0)
                    Expanded(
                      child: _MiniNutrient(
                        label: 'Fibra',
                        value: nutrients.fiberG,
                        unit: 'g',
                        color: Colors.green,
                      ),
                    ),
                  if (nutrients.fiberG > 0 && nutrients.sugarsG > 0)
                    const SizedBox(width: 16),
                  if (nutrients.sugarsG > 0)
                    Expanded(
                      child: _MiniNutrient(
                        label: 'Azúcares',
                        value: nutrients.sugarsG,
                        unit: 'g',
                        color: Colors.pink,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Row(
      children: [
        // Icono según tipo
        Icon(
          nutrition.isDish ? Icons.restaurant : Icons.eco,
          color: nutrition.isDish ? Colors.orange : Colors.green,
          size: 20,
        ),
        const SizedBox(width: 8),
        // Nombre
        Expanded(
          child: Text(
            nutrition.displayLabel,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        // Badge de match score
        _MatchScoreBadge(score: nutrition.matchScore),
      ],
    );
  }
}

/// Badge que muestra el match score.
class _MatchScoreBadge extends StatelessWidget {
  final double score;

  const _MatchScoreBadge({required this.score});

  @override
  Widget build(BuildContext context) {
    final Color color;
    if (score >= 80) {
      color = Colors.green;
    } else if (score >= 60) {
      color = Colors.orange;
    } else {
      color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(26), // 0.1 * 255 ≈ 26
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(77)), // 0.3 * 255 ≈ 77
      ),
      child: Text(
        '${score.toStringAsFixed(0)}%',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Widget compacto para nutriente pequeño.
class _MiniNutrient extends StatelessWidget {
  final String label;
  final double value;
  final String unit;
  final Color color;

  const _MiniNutrient({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$label: ${value.toStringAsFixed(1)} $unit',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[700],
              ),
        ),
      ],
    );
  }
}

/// Card compacta para mostrar nutrición en lista.
class NutritionCardCompact extends StatelessWidget {
  final NutritionInfo nutrition;
  final VoidCallback? onTap;

  const NutritionCardCompact({
    super.key,
    required this.nutrition,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final nutrients = nutrition.nutrients;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Icono
              Icon(
                nutrition.isDish ? Icons.restaurant : Icons.eco,
                color: nutrition.isDish ? Colors.orange : Colors.green,
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nutrition.displayLabel,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      '${nutrients.energyKcal.toStringAsFixed(0)} kcal | '
                      'P: ${nutrients.proteinG.toStringAsFixed(1)}g | '
                      'G: ${nutrients.fatG.toStringAsFixed(1)}g | '
                      'C: ${nutrients.carbohydratesG.toStringAsFixed(1)}g',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),
              // Match score
              _MatchScoreBadge(score: nutrition.matchScore),
            ],
          ),
        ),
      ),
    );
  }
}

/// Placeholder para cuando no hay información nutricional.
class NutritionNotFoundCard extends StatelessWidget {
  final String label;

  const NutritionNotFoundCard({
    super.key,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[100],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Colors.grey[500],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.replaceAll('_', ' '),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.grey[700],
                        ),
                  ),
                  Text(
                    'Información nutricional no disponible',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[500],
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

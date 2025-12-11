// ╔═══════════════════════════════════════════════════════════════════════════════╗
// ║                          nutrition_summary.dart                               ║
// ║                  Resumen total de nutrientes detectados                       ║
// ╠═══════════════════════════════════════════════════════════════════════════════╣
// ║  Widget que muestra el resumen total de nutrientes de todas las detecciones.  ║
// ║  Integración con Riverpod para datos reactivos.                               ║
// ╚═══════════════════════════════════════════════════════════════════════════════╝

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/detection.dart';
import '../../../data/models/nutrients_per_100g.dart';
import '../providers/nutrition_provider.dart';

/// Widget que muestra resumen total de nutrientes.
///
/// Calcula y muestra el total de nutrientes de todas las detecciones
/// usando Riverpod para reactividad.
///
/// Ejemplo de uso:
/// ```dart
/// NutritionSummary(detections: detections)
/// ```
class NutritionSummary extends ConsumerWidget {
  /// Lista de detecciones para calcular el total.
  final List<Detection> detections;

  const NutritionSummary({
    super.key,
    required this.detections,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (detections.isEmpty) {
      return const SizedBox.shrink();
    }

    final totalAsync = ref.watch(totalNutrientsProvider(detections));

    return totalAsync.when(
      loading: () => const _SummaryLoading(),
      error: (e, _) => _SummaryError(error: e.toString()),
      data: (total) => _SummaryCard(total: total, itemCount: detections.length),
    );
  }
}

/// Card del resumen de nutrientes.
class _SummaryCard extends StatelessWidget {
  final NutrientsPer100g total;
  final int itemCount;

  const _SummaryCard({
    required this.total,
    required this.itemCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 3,
      color: Colors.green.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.green.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.analytics_outlined,
                  color: Colors.green.shade700,
                ),
                const SizedBox(width: 8),
                Text(
                  'TOTAL ESTIMADO',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                Text(
                  '$itemCount items',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.green.shade600,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            // Nutrientes en grid
            Row(
              children: [
                Expanded(
                  child: _NutrientSummaryItem(
                    icon: Icons.local_fire_department,
                    label: 'Calorías',
                    value: total.energyKcal.toStringAsFixed(0),
                    unit: 'kcal',
                    color: Colors.orange,
                  ),
                ),
                Expanded(
                  child: _NutrientSummaryItem(
                    icon: Icons.fitness_center,
                    label: 'Proteínas',
                    value: total.proteinG.toStringAsFixed(1),
                    unit: 'g',
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _NutrientSummaryItem(
                    icon: Icons.water_drop,
                    label: 'Grasas',
                    value: total.fatG.toStringAsFixed(1),
                    unit: 'g',
                    color: Colors.amber,
                  ),
                ),
                Expanded(
                  child: _NutrientSummaryItem(
                    icon: Icons.grain,
                    label: 'Carbohidratos',
                    value: total.carbohydratesG.toStringAsFixed(1),
                    unit: 'g',
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            // Nota de aproximación
            const SizedBox(height: 12),
            Text(
              'Valores aproximados por 100g de cada ingrediente',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Item individual del resumen.
class _NutrientSummaryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _NutrientSummaryItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withAlpha(26), // 0.1 * 255 ≈ 26
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            Text(
              '$value $unit',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Estado de carga del resumen.
class _SummaryLoading extends StatelessWidget {
  const _SummaryLoading();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[100],
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const CircularProgressIndicator(strokeWidth: 2),
            const SizedBox(height: 12),
            Text(
              'Calculando nutrientes...',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Estado de error del resumen.
class _SummaryError extends StatelessWidget {
  final String error;

  const _SummaryError({required this.error});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red[400],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Error calculando nutrientes',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.red[700],
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget compacto de resumen (solo calorías).
class NutritionSummaryCompact extends ConsumerWidget {
  final List<Detection> detections;

  const NutritionSummaryCompact({
    super.key,
    required this.detections,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (detections.isEmpty) {
      return const SizedBox.shrink();
    }

    final totalAsync = ref.watch(totalNutrientsProvider(detections));

    return totalAsync.when(
      loading: () => const SizedBox(
        height: 24,
        width: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (_, __) => const Icon(Icons.error_outline, color: Colors.red),
      data: (total) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.orange.withAlpha(26), // 0.1 * 255 ≈ 26
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.local_fire_department,
              size: 18,
              color: Colors.orange,
            ),
            const SizedBox(width: 4),
            Text(
              '${total.energyKcal.toStringAsFixed(0)} kcal',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

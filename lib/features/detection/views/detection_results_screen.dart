// =====================================================================================
// ║                       detection_results_screen.dart                              ║
// ║            Pantalla de resultados de deteccion reutilizable                      ║
// =====================================================================================
// ║  Muestra resultados de deteccion YOLO con informacion nutricional.               ║
// ║  Reutilizable para deteccion desde camara o galeria.                             ║
// =====================================================================================

import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/detection.dart';
import '../../nutrition/providers/nutrition_provider.dart';
import '../../nutrition/widgets/nutrition_card.dart';
import '../../nutrition/widgets/quantity_adjustment_dialog.dart';

/// Pantalla de resultados de deteccion reutilizable.
///
/// Muestra:
/// - Imagen con bounding boxes
/// - Lista de ingredientes detectados con nivel de confianza
/// - Informacion nutricional por ingrediente
/// - Preview de nutrientes totales
/// - Opciones para ajustar cantidades
///
/// Ejemplo de uso:
/// ```dart
/// Navigator.push(
///   context,
///   MaterialPageRoute(
///     builder: (_) => DetectionResultsScreen(
///       imageFile: capturedFile,
///       detections: detectionsList,
///       imageWidth: 1920,
///       imageHeight: 1080,
///       title: 'Resultados de Captura',
///       onRetakePressed: () => Navigator.pop(context),
///     ),
///   ),
/// );
/// ```
class DetectionResultsScreen extends ConsumerStatefulWidget {
  /// Archivo de imagen a mostrar.
  final File imageFile;

  /// Lista de detecciones YOLO.
  final List<Detection> detections;

  /// Ancho original de la imagen en pixeles.
  final int imageWidth;

  /// Alto original de la imagen en pixeles.
  final int imageHeight;

  /// Titulo de la pantalla (opcional).
  final String title;

  /// Callback cuando se presiona "Volver a capturar" o similar.
  final VoidCallback? onRetakePressed;

  /// Texto del boton de retomar (opcional).
  final String retakeButtonText;

  /// Mostrar boton de compartir (futuro).
  final bool showShareButton;

  const DetectionResultsScreen({
    super.key,
    required this.imageFile,
    required this.detections,
    required this.imageWidth,
    required this.imageHeight,
    this.title = 'Resultados de Deteccion',
    this.onRetakePressed,
    this.retakeButtonText = 'Nueva Captura',
    this.showShareButton = false,
  });

  @override
  ConsumerState<DetectionResultsScreen> createState() =>
      _DetectionResultsScreenState();
}

class _DetectionResultsScreenState
    extends ConsumerState<DetectionResultsScreen> {
  // =========================================================================
  // PROPIEDADES
  // =========================================================================

  /// Ingrediente seleccionado para filtrar/resaltar.
  String? _selectedIngredient;

  // =========================================================================
  // LIFECYCLE
  // =========================================================================

  @override
  void initState() {
    super.initState();
    // Inicializar cantidades para los ingredientes detectados
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(ingredientQuantitiesProvider.notifier)
          .setFromDetections(widget.detections);
    });
  }

  // =========================================================================
  // METODOS DE NEGOCIO
  // =========================================================================

  /// Alterna el filtro de ingrediente.
  void _toggleIngredientFilter(String label) {
    setState(() {
      _selectedIngredient = _selectedIngredient == label ? null : label;
    });
  }

  /// Limpia el filtro de ingrediente.
  void _clearFilter() {
    setState(() {
      _selectedIngredient = null;
    });
  }

  /// Obtiene las detecciones filtradas.
  List<Detection> get _filteredDetections {
    if (_selectedIngredient == null) return widget.detections;
    return widget.detections.filterByLabel(_selectedIngredient!);
  }

  /// Muestra el dialogo de ajuste de cantidad.
  Future<void> _showQuantityDialog(
      String label, dynamic currentQuantity) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => QuantityAdjustmentDialog(
        ingredientLabel: label,
        currentQuantity: currentQuantity,
      ),
    );

    if (result == true && mounted) {
      setState(() {});
    }
  }

  /// Capitaliza la primera letra.
  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  /// Obtiene el color segun el nivel de confianza.
  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.7) return Colors.green;
    if (confidence >= 0.5) return Colors.orange;
    return Colors.red;
  }

  // =========================================================================
  // BUILD
  // =========================================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Volver',
          onPressed: () {
            if (widget.onRetakePressed != null) {
              widget.onRetakePressed!();
            } else {
              context.goBackOrHome();
            }
          },
        ),
        title: Text(widget.title),
        backgroundColor: theme.colorScheme.inversePrimary,
        actions: [
          if (_selectedIngredient != null)
            IconButton(
              icon: const Icon(Icons.filter_alt_off),
              tooltip: 'Mostrar todos',
              onPressed: _clearFilter,
            ),
          if (widget.showShareButton)
            IconButton(
              icon: const Icon(Icons.share),
              tooltip: 'Compartir',
              onPressed: () {
                // TODO: Implementar compartir
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Funcion de compartir proximamente')),
                );
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Indicador de filtro activo
            if (_selectedIngredient != null) ...[
              _buildFilterIndicator(),
              const SizedBox(height: 16),
            ],

            // Imagen con bounding boxes
            _buildImageWithBoundingBoxes(),
            const SizedBox(height: 16),

            // Resumen de detecciones
            _buildDetectionSummary(theme),
            const SizedBox(height: 16),

            // Lista de ingredientes
            if (widget.detections.isNotEmpty) ...[
              _buildIngredientsList(theme),
              const SizedBox(height: 24),

              // Seccion nutricional
              _buildNutritionSection(theme),
            ],

            const SizedBox(height: 24),

            // Boton para nueva captura
            if (widget.onRetakePressed != null)
              ElevatedButton.icon(
                onPressed: widget.onRetakePressed,
                icon: const Icon(Icons.camera_alt),
                label: Text(widget.retakeButtonText),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // WIDGETS DE UI
  // =========================================================================

  /// Indicador de filtro activo.
  Widget _buildFilterIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.filter_alt, color: Colors.blue.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Mostrando: ${_capitalizeFirst(_selectedIngredient!)} (${_filteredDetections.length})',
              style: TextStyle(
                color: Colors.blue.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            iconSize: 20,
            color: Colors.blue.shade700,
            onPressed: _clearFilter,
          ),
        ],
      ),
    );
  }

  /// Imagen con bounding boxes.
  Widget _buildImageWithBoundingBoxes() {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth;
          final maxHeight = MediaQuery.of(context).size.height * 0.4;

          final imageAspectRatio =
              widget.imageWidth > 0 && widget.imageHeight > 0
                  ? widget.imageWidth / widget.imageHeight
                  : 1.0;

          double renderWidth, renderHeight;
          if (maxWidth / maxHeight > imageAspectRatio) {
            renderHeight = maxHeight;
            renderWidth = maxHeight * imageAspectRatio;
          } else {
            renderWidth = maxWidth;
            renderHeight = maxWidth / imageAspectRatio;
          }

          return SizedBox(
            width: maxWidth,
            height: renderHeight,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Image.file(
                  widget.imageFile,
                  fit: BoxFit.contain,
                  width: renderWidth,
                  height: renderHeight,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: Icon(Icons.broken_image, size: 48),
                      ),
                    );
                  },
                ),
                if (_filteredDetections.isNotEmpty &&
                    widget.imageWidth > 0 &&
                    widget.imageHeight > 0)
                  SizedBox(
                    width: renderWidth,
                    height: renderHeight,
                    child: CustomPaint(
                      painter: _ResultsBoundingBoxPainter(
                        detections: _filteredDetections,
                        imageWidth: widget.imageWidth,
                        imageHeight: widget.imageHeight,
                        highlightLabel: _selectedIngredient,
                        allDetections: widget.detections,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Resumen de detecciones.
  Widget _buildDetectionSummary(ThemeData theme) {
    final stats = widget.detections.stats;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              widget.detections.isEmpty ? Icons.search_off : Icons.check_circle,
              size: 48,
              color: widget.detections.isEmpty
                  ? Colors.grey
                  : AppColors.primaryGreen,
            ),
            const SizedBox(height: 8),
            Text(
              widget.detections.isEmpty
                  ? 'No se detectaron ingredientes'
                  : 'Detectados ${stats.total} ingredientes (${stats.uniqueIngredients} unicos)',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            if (widget.detections.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Confianza promedio: ${(stats.averageConfidence * 100).toStringAsFixed(0)}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Lista de ingredientes detectados.
  Widget _buildIngredientsList(ThemeData theme) {
    final grouped = widget.detections.groupByLabel();
    final sortedLabels = grouped.keys.toList()
      ..sort((a, b) => grouped[b]!.length.compareTo(grouped[a]!.length));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Ingredientes Detectados (${widget.detections.length})',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (_selectedIngredient != null)
              TextButton.icon(
                onPressed: _clearFilter,
                icon: const Icon(Icons.visibility, size: 18),
                label: const Text('Ver todos'),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Toca un ingrediente para resaltar sus detecciones',
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.grey.shade600,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 8),
        ...sortedLabels
            .map((label) => _buildIngredientCard(label, grouped[label]!)),
      ],
    );
  }

  /// Card de ingrediente individual.
  Widget _buildIngredientCard(String label, List<Detection> detections) {
    final count = detections.length;
    final avgConfidence =
        detections.map((d) => d.confidence).reduce((a, b) => a + b) / count;
    final isSelected = _selectedIngredient == label;

    return Card(
      elevation: isSelected ? 4 : 1,
      color: isSelected ? Colors.blue.shade50 : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: Colors.blue.shade400, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _toggleIngredientFilter(label),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor:
                  isSelected ? Colors.blue : _getConfidenceColor(avgConfidence),
              child: Text(
                count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              _capitalizeFirst(label),
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.blue.shade700 : null,
              ),
            ),
            subtitle: Text(
              'Confianza: ${(avgConfidence * 100).toStringAsFixed(1)}%',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  avgConfidence >= 0.7
                      ? Icons.check_circle
                      : avgConfidence >= 0.5
                          ? Icons.help
                          : Icons.warning,
                  color: isSelected
                      ? Colors.blue
                      : _getConfidenceColor(avgConfidence),
                ),
                const SizedBox(width: 8),
                Icon(
                  isSelected ? Icons.visibility : Icons.visibility_outlined,
                  color: isSelected ? Colors.blue : Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // SECCION DE NUTRICION
  // =========================================================================

  /// Seccion de informacion nutricional.
  Widget _buildNutritionSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.restaurant_menu, color: Colors.green),
            const SizedBox(width: 8),
            Text(
              'Informacion Nutricional',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Preview de nutrientes totales
        _buildNutrientPreview(),
        const SizedBox(height: 16),

        // Detalle por ingrediente
        _buildNutritionCards(theme),
      ],
    );
  }

  /// Preview de nutrientes totales.
  Widget _buildNutrientPreview() {
    final totalNutrientsAsync = ref.watch(totalNutrientsWithQuantitiesProvider);

    return totalNutrientsAsync.when(
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, _) => Card(
        color: Colors.orange.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.orange.shade700),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('No se pudo calcular nutrientes totales'),
              ),
            ],
          ),
        ),
      ),
      data: (nutrients) => Card(
        elevation: 3,
        color: Colors.green.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.calculate,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Total Nutricional',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade900,
                        ),
                  ),
                  const Spacer(),
                  Builder(
                    builder: (context) {
                      final isDark = Theme.of(context).brightness == Brightness.dark;
                      return Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.green.shade900 : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'En tiempo real',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.green.shade200 : Colors.green.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildNutrientItem(
                      'Calorias',
                      nutrients.energyKcal.toStringAsFixed(0),
                      'kcal',
                      Icons.local_fire_department,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildNutrientItem(
                      'Proteinas',
                      nutrients.proteinG.toStringAsFixed(1),
                      'g',
                      Icons.fitness_center,
                      Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildNutrientItem(
                      'Grasas',
                      nutrients.fatG.toStringAsFixed(1),
                      'g',
                      Icons.water_drop,
                      Colors.amber,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildNutrientItem(
                      'Carbohidratos',
                      nutrients.carbohydratesG.toStringAsFixed(1),
                      'g',
                      Icons.grain,
                      Colors.blue,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Item individual de nutriente.
  Widget _buildNutrientItem(
    String label,
    String value,
    String unit,
    IconData icon,
    Color color,
  ) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey.shade900 : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withAlpha(77), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 16, color: color),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    unit,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// Cards de nutricion por ingrediente.
  Widget _buildNutritionCards(ThemeData theme) {
    final uniqueLabels = widget.detections.uniqueLabels.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detalle por ingrediente',
          style: theme.textTheme.titleSmall?.copyWith(
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        ...uniqueLabels.map((label) => _buildNutritionCardForLabel(label)),
      ],
    );
  }

  /// Card de nutricion para un ingrediente especifico.
  Widget _buildNutritionCardForLabel(String label) {
    final nutritionAsync = ref.watch(nutritionByLabelProvider(label));
    final quantitiesState = ref.watch(ingredientQuantitiesProvider);
    final currentQuantity = quantitiesState.getQuantity(label);

    return nutritionAsync.when(
      loading: () => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Text(label.replaceAll('_', ' ')),
            ],
          ),
        ),
      ),
      error: (e, _) => NutritionNotFoundCard(label: label),
      data: (nutrition) {
        if (nutrition == null) {
          return NutritionNotFoundCard(label: label);
        }

        // Obtener confianza promedio de este ingrediente
        final detectionsForLabel = widget.detections.filterByLabel(label);
        final avgConfidence = detectionsForLabel.isNotEmpty
            ? detectionsForLabel
                    .map((d) => d.confidence)
                    .reduce((a, b) => a + b) /
                detectionsForLabel.length
            : null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            NutritionCard(
              nutrition: nutrition,
              confidence: avgConfidence,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.scale, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Cantidad: ${currentQuantity?.grams.toStringAsFixed(0) ?? "100"}g',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () =>
                        _showQuantityDialog(label, currentQuantity),
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Ajustar'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}

// =============================================================================
// BOUNDING BOX PAINTER
// =============================================================================

/// Painter para dibujar bounding boxes en los resultados.
class _ResultsBoundingBoxPainter extends CustomPainter {
  final List<Detection> detections;
  final int imageWidth;
  final int imageHeight;
  final String? highlightLabel;
  final List<Detection> allDetections;

  _ResultsBoundingBoxPainter({
    required this.detections,
    required this.imageWidth,
    required this.imageHeight,
    this.highlightLabel,
    required this.allDetections,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (allDetections.isEmpty || imageWidth <= 0 || imageHeight <= 0) return;

    final double scaleX = size.width / imageWidth;
    final double scaleY = size.height / imageHeight;

    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final fillPaint = Paint()..style = PaintingStyle.fill;

    // Dibujar todas las detecciones, pero con diferente opacidad
    for (final detection in allDetections) {
      final bool isHighlighted =
          highlightLabel == null || detection.label == highlightLabel;
      final double opacity = isHighlighted ? 1.0 : 0.3;

      Color boxColor;
      if (highlightLabel != null && detection.label == highlightLabel) {
        boxColor = Colors.blue;
      } else if (detection.isHighConfidence) {
        boxColor = Colors.green;
      } else if (detection.isMediumConfidence) {
        boxColor = Colors.orange;
      } else {
        boxColor = Colors.red;
      }

      strokePaint.color = boxColor.withAlpha((opacity * 255).round());
      fillPaint.color = boxColor.withAlpha((0.15 * opacity * 255).round());

      final double x1 = detection.x1 * scaleX;
      final double y1 = detection.y1 * scaleY;
      final double x2 = detection.x2 * scaleX;
      final double y2 = detection.y2 * scaleY;

      if (x1.isNaN || y1.isNaN || x2.isNaN || y2.isNaN) continue;
      if (x2 <= x1 || y2 <= y1) continue;

      final rect = Rect.fromLTRB(x1, y1, x2, y2);

      canvas.drawRect(rect, fillPaint);
      canvas.drawRect(rect, strokePaint);

      if (isHighlighted) {
        _drawLabel(canvas, detection, x1, y1, boxColor, size);
      }
    }
  }

  void _drawLabel(
    Canvas canvas,
    Detection detection,
    double x1,
    double y1,
    Color boxColor,
    Size canvasSize,
  ) {
    final String labelText =
        '${detection.label} ${detection.confidenceFormatted}';

    final textSpan = TextSpan(
      text: labelText,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    const double padding = 4;
    final double labelWidth = textPainter.width + padding * 2;
    final double labelHeight = textPainter.height + padding;

    double labelX = x1;
    double labelY = y1 > labelHeight + 2 ? y1 - labelHeight - 2 : y1 + 2;

    labelX = labelX.clamp(0, max(0, canvasSize.width - labelWidth));
    labelY = labelY.clamp(0, max(0, canvasSize.height - labelHeight));

    final labelRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(labelX, labelY, labelWidth, labelHeight),
      const Radius.circular(4),
    );

    canvas.drawRRect(labelRect, Paint()..color = boxColor.withAlpha(230));

    textPainter.paint(canvas, Offset(labelX + padding, labelY + padding / 2));
  }

  @override
  bool shouldRepaint(covariant _ResultsBoundingBoxPainter oldDelegate) {
    return oldDelegate.detections != detections ||
        oldDelegate.imageWidth != imageWidth ||
        oldDelegate.imageHeight != imageHeight ||
        oldDelegate.highlightLabel != highlightLabel;
  }
}

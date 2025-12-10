// ╔═══════════════════════════════════════════════════════════════════════════════╗
// ║                    detection_gallery_screen.dart                              ║
// ║          Pantalla de detección de ingredientes desde galería                  ║
// ╠═══════════════════════════════════════════════════════════════════════════════╣
// ║  Permite seleccionar imágenes de la galería y ejecutar detección YOLO.        ║
// ║  Muestra resultados con bounding boxes y lista de ingredientes detectados.    ║
// ╚═══════════════════════════════════════════════════════════════════════════════╝

import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

import '../services/yolo_detector.dart';
import '../../../data/models/detection.dart';
import '../../../core/exceptions/app_exceptions.dart';

class GalleryDetectionPage extends StatefulWidget {
  const GalleryDetectionPage({super.key});

  @override
  State<GalleryDetectionPage> createState() => _GalleryDetectionPageState();
}

class _GalleryDetectionPageState extends State<GalleryDetectionPage> {
  // ═══════════════════════════════════════════════════════════════════════════
  // PROPIEDADES
  // ═══════════════════════════════════════════════════════════════════════════

  final YoloDetector _detector = YoloDetector();
  final ImagePicker _imagePicker = ImagePicker();

  File? _selectedImage;
  List<Detection> _detections = [];

  bool _isLoading = false;
  bool _isModelLoaded = false;
  String _statusMessage = 'Presiona "Cargar Modelo" para iniciar';

  NutriVisionException? _currentError;
  int _inferenceTimeMs = 0;

  int _imageWidth = 0;
  int _imageHeight = 0;

  String? _selectedIngredient;

  // ═══════════════════════════════════════════════════════════════════════════
  // LIFECYCLE
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  void dispose() {
    _safeDisposeDetector();
    super.dispose();
  }

  void _safeDisposeDetector() {
    try {
      _detector.dispose();
    } catch (e, stackTrace) {
      ExceptionHandler.logError(e, stackTrace);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS DE NEGOCIO
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _loadModel() async {
    setState(() {
      _isLoading = true;
      _currentError = null;
      _statusMessage = 'Cargando modelo...';
    });

    try {
      await _detector.initialize();

      if (!mounted) return;

      setState(() {
        _isModelLoaded = true;
        _statusMessage = 'Modelo cargado ✓ (${_detector.labelCount} clases)';
      });

      _showSnackBar('Modelo cargado exitosamente', Colors.green);
    } on NutriVisionException catch (e, stackTrace) {
      _handleError(e, stackTrace);
    } catch (e, stackTrace) {
      _handleError(ExceptionHandler.wrap(e, stackTrace), stackTrace);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    setState(() => _currentError = null);

    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (pickedFile == null) return;

      final file = File(pickedFile.path);
      if (!await file.exists()) {
        throw ImageFileException(
          message: 'El archivo seleccionado no existe',
          filePath: pickedFile.path,
        );
      }

      final bytes = await file.readAsBytes();
      final decodedImage = img.decodeImage(bytes);

      if (decodedImage == null) {
        throw ImageDecodeException(message: 'No se pudo leer la imagen');
      }

      if (!mounted) return;

      setState(() {
        _selectedImage = file;
        _imageWidth = decodedImage.width;
        _imageHeight = decodedImage.height;
        _detections = [];
        _selectedIngredient = null;
        _statusMessage = 'Imagen: ${_imageWidth}x$_imageHeight. Presiona "Detectar".';
      });
    } on NutriVisionException catch (e, stackTrace) {
      _handleError(e, stackTrace);
    } catch (e, stackTrace) {
      _handleError(ExceptionHandler.wrap(e, stackTrace), stackTrace);
    }
  }

  Future<void> _runDetection() async {
    if (_selectedImage == null || !_isModelLoaded) return;

    setState(() {
      _isLoading = true;
      _currentError = null;
      _statusMessage = 'Ejecutando detección...';
      _selectedIngredient = null;
    });

    try {
      final bytes = await _selectedImage!.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) {
        throw ImageDecodeException(message: 'No se pudo decodificar la imagen');
      }

      _imageWidth = image.width;
      _imageHeight = image.height;

      final stopwatch = Stopwatch()..start();
      final detections = await _detector.detect(image);
      stopwatch.stop();

      if (!mounted) return;

      setState(() {
        _detections = detections;
        _inferenceTimeMs = stopwatch.elapsedMilliseconds;
        _statusMessage = _buildStatusMessage(detections);
      });

      _showSnackBar('Detectados ${detections.length} ingredientes', Colors.green);
    } on NutriVisionException catch (e, stackTrace) {
      _handleError(e, stackTrace);
    } catch (e, stackTrace) {
      _handleError(ExceptionHandler.wrap(e, stackTrace), stackTrace);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _buildStatusMessage(List<Detection> detections) {
    final stats = detections.stats;
    return 'Detectados: ${stats.total} (${stats.uniqueIngredients} únicos) • ${_inferenceTimeMs}ms\n'
        'Confianza: ${(stats.averageConfidence * 100).toStringAsFixed(0)}% promedio';
  }

  void _handleError(NutriVisionException error, StackTrace stackTrace) {
    ExceptionHandler.logError(error, stackTrace);
    if (!mounted) return;
    setState(() {
      _currentError = error;
      _statusMessage = 'Error: ${error.userMessage}';
    });
    _showSnackBar(error.userMessage, Colors.red);
  }

  void _toggleIngredientFilter(String label) {
    setState(() {
      _selectedIngredient = _selectedIngredient == label ? null : label;
    });
  }

  List<Detection> get _filteredDetections {
    if (_selectedIngredient == null) return _detections;
    return _detections.filterByLabel(_selectedIngredient!);
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD UI
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detección de Ingredientes'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_selectedIngredient != null)
            IconButton(
              icon: const Icon(Icons.filter_alt_off),
              tooltip: 'Mostrar todos',
              onPressed: () => setState(() => _selectedIngredient = null),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatusCard(),
            const SizedBox(height: 16),
            if (_currentError != null) ...[
              _buildErrorCard(),
              const SizedBox(height: 16),
            ],
            _buildActionButtons(),
            const SizedBox(height: 16),
            if (_selectedIngredient != null) ...[
              _buildFilterIndicator(),
              const SizedBox(height: 16),
            ],
            if (_selectedImage != null) ...[
              _buildImageWithBoundingBoxes(),
              const SizedBox(height: 16),
            ],
            if (_detections.isNotEmpty) _buildDetectionsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              _currentError != null
                  ? Icons.error
                  : _isModelLoaded
                  ? Icons.check_circle
                  : Icons.info,
              size: 48,
              color: _currentError != null
                  ? Colors.red
                  : _isModelLoaded
                  ? Colors.green
                  : Colors.grey,
            ),
            const SizedBox(height: 8),
            Text(
              _statusMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (_isLoading) ...[
              const SizedBox(height: 16),
              const CircularProgressIndicator(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.red.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _currentError!.userMessage,
                style: TextStyle(color: Colors.red.shade700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _loadModel,
                icon: const Icon(Icons.memory),
                label: Text(_isModelLoaded ? 'Modelo Cargado' : 'Cargar Modelo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isModelLoaded ? Colors.green : null,
                  foregroundColor: _isModelLoaded ? Colors.white : null,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isLoading || !_isModelLoaded ? null : _pickImage,
                icon: const Icon(Icons.image),
                label: const Text('Galería'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _isLoading || !_isModelLoaded || _selectedImage == null
              ? null
              : _runDetection,
          icon: const Icon(Icons.search),
          label: const Text('Detectar Ingredientes'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(48),
          ),
        ),
      ],
    );
  }

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
            onPressed: () => setState(() => _selectedIngredient = null),
          ),
        ],
      ),
    );
  }

  Widget _buildImageWithBoundingBoxes() {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth;
          final maxHeight = MediaQuery.of(context).size.height * 0.5;

          final imageAspectRatio = _imageWidth > 0 && _imageHeight > 0
              ? _imageWidth / _imageHeight
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
                  _selectedImage!,
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
                if (_filteredDetections.isNotEmpty && _imageWidth > 0 && _imageHeight > 0)
                  SizedBox(
                    width: renderWidth,
                    height: renderHeight,
                    child: CustomPaint(
                      painter: BoundingBoxPainter(
                        detections: _filteredDetections,
                        imageWidth: _imageWidth,
                        imageHeight: _imageHeight,
                        highlightLabel: _selectedIngredient,
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

  Widget _buildDetectionsList() {
    final grouped = _detections.groupByLabel();
    final sortedLabels = grouped.keys.toList()
      ..sort((a, b) => grouped[b]!.length.compareTo(grouped[a]!.length));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Ingredientes Detectados (${_detections.length})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (_selectedIngredient != null)
              TextButton.icon(
                onPressed: () => setState(() => _selectedIngredient = null),
                icon: const Icon(Icons.visibility, size: 18),
                label: const Text('Ver todos'),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Toca un ingrediente para filtrar sus detecciones',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey.shade600,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 8),
        ...sortedLabels.map((label) => _buildIngredientCard(label, grouped[label]!)),
      ],
    );
  }

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
              backgroundColor: isSelected
                  ? Colors.blue
                  : _getConfidenceColor(avgConfidence),
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

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.7) return Colors.green;
    if (confidence >= 0.5) return Colors.orange;
    return Colors.red;
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// BOUNDING BOX PAINTER - VERSIÓN CORREGIDA (sin withOpacity deprecated)
// ═══════════════════════════════════════════════════════════════════════════════

class BoundingBoxPainter extends CustomPainter {
  final List<Detection> detections;
  final int imageWidth;
  final int imageHeight;
  final String? highlightLabel;

  BoundingBoxPainter({
    required this.detections,
    required this.imageWidth,
    required this.imageHeight,
    this.highlightLabel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (detections.isEmpty || imageWidth <= 0 || imageHeight <= 0) return;

    final double scaleX = size.width / imageWidth;
    final double scaleY = size.height / imageHeight;

    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final fillPaint = Paint()..style = PaintingStyle.fill;

    for (final detection in detections) {
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

      // Usar withAlpha en lugar de withOpacity (deprecated)
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
    final String labelText = '${detection.label} ${detection.confidenceFormatted}';

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

    // Usar withAlpha en lugar de withOpacity (deprecated)
    canvas.drawRRect(labelRect, Paint()..color = boxColor.withAlpha(230));

    textPainter.paint(canvas, Offset(labelX + padding, labelY + padding / 2));
  }

  @override
  bool shouldRepaint(covariant BoundingBoxPainter oldDelegate) {
    return oldDelegate.detections != detections ||
        oldDelegate.imageWidth != imageWidth ||
        oldDelegate.imageHeight != imageHeight ||
        oldDelegate.highlightLabel != highlightLabel;
  }
}

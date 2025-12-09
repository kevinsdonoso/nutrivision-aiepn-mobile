// ╔═══════════════════════════════════════════════════════════════════════════════╗
// ║                      detection_test_screen.dart                               ║
// ║            Pantalla de prueba para verificar detección YOLO                   ║
// ╠═══════════════════════════════════════════════════════════════════════════════╣
// ║  Pantalla simple para probar que el modelo TFLite funciona correctamente.     ║
// ║  Permite seleccionar una imagen de galería y ejecutar detección.              ║
// ╚═══════════════════════════════════════════════════════════════════════════════╝

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

import '../../ml/yolo_detector.dart';
import '../../data/models/detection.dart';

/// Pantalla de prueba para verificar que el detector YOLO funciona.
///
/// Esta pantalla permite:
/// 1. Cargar el modelo TFLite
/// 2. Seleccionar una imagen de la galería
/// 3. Ejecutar detección y mostrar resultados
/// 4. Visualizar bounding boxes sobre la imagen
class DetectionTestScreen extends StatefulWidget {
  const DetectionTestScreen({super.key});

  @override
  State<DetectionTestScreen> createState() => _DetectionTestScreenState();
}

class _DetectionTestScreenState extends State<DetectionTestScreen> {
  // ═══════════════════════════════════════════════════════════════════════════
  // PROPIEDADES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Detector YOLO
  final YoloDetector _detector = YoloDetector();

  /// Selector de imágenes
  final ImagePicker _imagePicker = ImagePicker();

  /// Imagen seleccionada (archivo)
  File? _selectedImage;

  /// Lista de detecciones
  List<Detection> _detections = [];

  /// Estados de la UI
  bool _isLoading = false;
  bool _isModelLoaded = false;
  String _statusMessage = 'Presiona "Cargar Modelo" para iniciar';

  /// Tiempo de inferencia (para métricas)
  int _inferenceTimeMs = 0;

  // ═══════════════════════════════════════════════════════════════════════════
  // LIFECYCLE
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  void dispose() {
    _detector.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS DE NEGOCIO
  // ═══════════════════════════════════════════════════════════════════════════

  /// Carga el modelo TFLite
  Future<void> _loadModel() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Cargando modelo...';
    });

    try {
      await _detector.initialize();

      setState(() {
        _isModelLoaded = true;
        _statusMessage = 'Modelo cargado ✓ (${_detector.labelCount} clases)';
      });

      _showSnackBar('Modelo cargado exitosamente', Colors.green);

    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
      });
      _showSnackBar('Error cargando modelo: $e', Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Selecciona una imagen de la galería
  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _detections = [];
          _statusMessage = 'Imagen seleccionada. Presiona "Detectar" para analizar.';
        });
      }
    } catch (e) {
      _showSnackBar('Error seleccionando imagen: $e', Colors.red);
    }
  }

  /// Ejecuta la detección sobre la imagen seleccionada
  Future<void> _runDetection() async {
    if (_selectedImage == null) {
      _showSnackBar('Primero selecciona una imagen', Colors.orange);
      return;
    }

    if (!_isModelLoaded) {
      _showSnackBar('Primero carga el modelo', Colors.orange);
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Ejecutando detección...';
    });

    try {
      // Leer y decodificar imagen
      final bytes = await _selectedImage!.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) {
        throw Exception('No se pudo decodificar la imagen');
      }

      // Medir tiempo de inferencia
      final stopwatch = Stopwatch()..start();

      // Ejecutar detección
      final detections = await _detector.detect(image);

      stopwatch.stop();

      setState(() {
        _detections = detections;
        _inferenceTimeMs = stopwatch.elapsedMilliseconds;
        _statusMessage = 'Detectados: ${detections.length} ingredientes (${_inferenceTimeMs}ms)';
      });

      _showSnackBar(
        'Detectados ${detections.length} ingredientes',
        Colors.green,
      );

    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
      });
      _showSnackBar('Error en detección: $e', Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Muestra un SnackBar con mensaje
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD UI
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test de Detección YOLO'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─────────────────────────────────────────────────────────────────
            // TARJETA DE ESTADO
            // ─────────────────────────────────────────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(
                      _isModelLoaded ? Icons.check_circle : Icons.info,
                      size: 48,
                      color: _isModelLoaded ? Colors.green : Colors.grey,
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
            ),

            const SizedBox(height: 16),

            // ─────────────────────────────────────────────────────────────────
            // BOTONES DE ACCIÓN
            // ─────────────────────────────────────────────────────────────────
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

            const SizedBox(height: 16),

            // ─────────────────────────────────────────────────────────────────
            // IMAGEN CON BOUNDING BOXES
            // ─────────────────────────────────────────────────────────────────
            if (_selectedImage != null) ...[
              Card(
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    // Imagen
                    Image.file(
                      _selectedImage!,
                      fit: BoxFit.contain,
                      width: double.infinity,
                    ),

                    // Overlay con bounding boxes
                    if (_detections.isNotEmpty)
                      Positioned.fill(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return CustomPaint(
                              painter: BoundingBoxPainter(
                                detections: _detections,
                                imageFile: _selectedImage!,
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
            ],

            // ─────────────────────────────────────────────────────────────────
            // LISTA DE DETECCIONES
            // ─────────────────────────────────────────────────────────────────
            if (_detections.isNotEmpty) ...[
              Text(
                'Ingredientes Detectados (${_detections.length})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),

              // Agrupar por ingrediente
              ..._buildDetectionsList(),
            ],
          ],
        ),
      ),
    );
  }

  /// Construye la lista de detecciones agrupadas por ingrediente
  List<Widget> _buildDetectionsList() {
    final grouped = _detections.groupByLabel();
    final sortedLabels = grouped.keys.toList()
      ..sort((a, b) => grouped[b]!.length.compareTo(grouped[a]!.length));

    return sortedLabels.map((label) {
      final count = grouped[label]!.length;
      final avgConfidence = grouped[label]!
          .map((d) => d.confidence)
          .reduce((a, b) => a + b) / count;

      return Card(
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: _getConfidenceColor(avgConfidence),
            child: Text(
              count.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            'Confianza promedio: ${(avgConfidence * 100).toStringAsFixed(1)}%',
          ),
          trailing: Icon(
            avgConfidence >= 0.7
                ? Icons.check_circle
                : avgConfidence >= 0.5
                ? Icons.help
                : Icons.warning,
            color: _getConfidenceColor(avgConfidence),
          ),
        ),
      );
    }).toList();
  }

  /// Obtiene el color según el nivel de confianza
  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.7) return Colors.green;
    if (confidence >= 0.5) return Colors.orange;
    return Colors.red;
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// CUSTOM PAINTER PARA BOUNDING BOXES
// ═══════════════════════════════════════════════════════════════════════════════

/// Dibuja los bounding boxes sobre la imagen.
class BoundingBoxPainter extends CustomPainter {
  final List<Detection> detections;
  final File imageFile;

  BoundingBoxPainter({
    required this.detections,
    required this.imageFile,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Necesitamos conocer las dimensiones originales de la imagen
    // Para escalar correctamente los bounding boxes
    // Este es un placeholder - en producción usaríamos las dimensiones reales

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    for (final detection in detections) {
      // Color según confianza
      paint.color = detection.isHighConfidence
          ? Colors.green
          : detection.isMediumConfidence
          ? Colors.orange
          : Colors.red;

      // Nota: Aquí deberíamos escalar las coordenadas según el tamaño del widget
      // Por ahora solo dibujamos un placeholder
      // En la implementación real, necesitamos las dimensiones de la imagen

      // Dibujar etiqueta
      textPainter.text = TextSpan(
        text: '${detection.label} ${detection.confidenceFormatted}',
        style: TextStyle(
          color: paint.color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          backgroundColor: Colors.black54,
        ),
      );
      textPainter.layout();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

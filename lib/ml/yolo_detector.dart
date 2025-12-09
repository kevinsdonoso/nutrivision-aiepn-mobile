// ╔═══════════════════════════════════════════════════════════════════════════════╗
// ║                         yolo_detector.dart                                    ║
// ║              Motor de inferencia YOLO11n con TensorFlow Lite                  ║
// ╠═══════════════════════════════════════════════════════════════════════════════╣
// ║  Clase principal para detección de ingredientes alimenticios.                 ║
// ║  Maneja: carga del modelo, preprocesamiento, inferencia y postprocesamiento.  ║
// ║                                                                               ║
// ║  Modelo: YOLO11n (Ultralytics) exportado a TFLite FP32                        ║
// ║  Input:  [1, 640, 640, 3] - Imagen RGB normalizada                            ║
// ║  Output: [1, 87, 8400] - 4 bbox + 83 clases × 8400 predicciones               ║
// ╚═══════════════════════════════════════════════════════════════════════════════╝

import 'dart:math';

import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;

import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../data/models/detection.dart';

/// Log condicional solo en modo debug
void _debugLog(String message) {
  if (kDebugMode) {
    debugPrint(message);
  }
}

/// Detector de ingredientes alimenticios usando YOLO11n.
///
/// Esta clase encapsula toda la lógica de:
/// 1. Carga del modelo TFLite y etiquetas
/// 2. Preprocesamiento de imágenes (letterbox resize, normalización)
/// 3. Ejecución de inferencia con TFLite
/// 4. Postprocesamiento (parsing de output, NMS)
///
/// Ejemplo de uso:
/// ```dart
/// final detector = YoloDetector();
/// await detector.initialize();
///
/// final image = img.decodeImage(bytes)!;
/// final detections = await detector.detect(image);
///
/// for (final det in detections) {
///   print('${det.label}: ${det.confidenceFormatted}');
/// }
///
/// detector.dispose();
/// ```
class YoloDetector {
  // ═══════════════════════════════════════════════════════════════════════════
  // CONSTANTES DEL MODELO
  // ═══════════════════════════════════════════════════════════════════════════

  /// Tamaño de entrada del modelo (640x640 píxeles)
  /// YOLO11n fue entrenado con esta resolución
  static const int inputSize = 640;

  /// Número de clases de ingredientes (83 en NutriVisionAIEPN)
  static const int numClasses = 83;

  /// Número total de predicciones por imagen
  /// YOLO11n genera 8400 anchor boxes en total (diferentes escalas)
  static const int numPredictions = 8400;

  /// Umbral de confianza mínimo para considerar una detección válida
  /// Valores más altos = menos detecciones pero más precisas
  static const double defaultConfidenceThreshold = 0.40;

  /// Umbral de IoU para Non-Maximum Suppression
  /// Si dos cajas tienen IoU > este valor, se elimina la de menor confianza
  static const double defaultIouThreshold = 0.45;

  /// Ruta al modelo TFLite en assets
  static const String modelPath = 'assets/models/yolov11n_float32.tflite';

  /// Ruta al archivo de etiquetas en assets
  static const String labelsPath = 'assets/labels/labels.txt';

  // ═══════════════════════════════════════════════════════════════════════════
  // PROPIEDADES PRIVADAS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Intérprete de TensorFlow Lite
  Interpreter? _interpreter;

  /// Lista de etiquetas de clases (ingredientes)
  List<String> _labels = [];

  /// Indica si el detector está inicializado y listo
  bool _isInitialized = false;

  /// Tensor de entrada reutilizable (evita realocaciones)
  List<List<List<List<double>>>>? _inputTensor;

  /// Tensor de salida reutilizable
  List<List<List<double>>>? _outputTensor;

  // ═══════════════════════════════════════════════════════════════════════════
  // PROPIEDADES PÚBLICAS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Indica si el detector está listo para realizar inferencias
  bool get isInitialized => _isInitialized;

  /// Lista de etiquetas de ingredientes cargadas
  List<String> get labels => List.unmodifiable(_labels);

  /// Número de clases cargadas
  int get labelCount => _labels.length;

  // ═══════════════════════════════════════════════════════════════════════════
  // INICIALIZACIÓN
  // ═══════════════════════════════════════════════════════════════════════════

  /// Inicializa el detector cargando el modelo y las etiquetas.
  ///
  /// Debe llamarse antes de cualquier operación de detección.
  /// Es seguro llamar múltiples veces (solo inicializa una vez).
  ///
  /// Throws:
  /// - [Exception] si el modelo no puede cargarse
  /// - [Exception] si las etiquetas no pueden leerse
  Future<void> initialize() async {
    // Evitar reinicialización
    if (_isInitialized) {
      _debugLog('⚠️ YoloDetector ya está inicializado');
      return;
    }

    try {
      _debugLog('🔄 Inicializando YoloDetector...');

      // ─────────────────────────────────────────────────────────────────────
      // PASO 1: Configurar opciones del intérprete
      // ─────────────────────────────────────────────────────────────────────
      final options = InterpreterOptions();

      // Usar múltiples threads para operaciones paralelas
      // 4 threads es un buen balance para la mayoría de dispositivos
      options.threads = 4;

      // XNNPack proporciona optimizaciones SIMD para CPU
      // Funciona en TODOS los dispositivos (a diferencia de GPU delegate)
      // Mejora el rendimiento 2-3x en operaciones de convolución
      options.addDelegate(XNNPackDelegate());

      _debugLog('   ├─ Configuración: 4 threads + XNNPack delegate');

      // ─────────────────────────────────────────────────────────────────────
      // PASO 2: Cargar modelo TFLite
      // ─────────────────────────────────────────────────────────────────────
      _interpreter = await Interpreter.fromAsset(
        modelPath,
        options: options,
      );

      // Preasignar tensores para mejor rendimiento
      _interpreter!.allocateTensors();

      // Verificar shapes del modelo
      final inputShape = _interpreter!.getInputTensor(0).shape;
      final outputShape = _interpreter!.getOutputTensor(0).shape;

      _debugLog('   ├─ Modelo cargado: $modelPath');
      _debugLog('   │  ├─ Input shape:  $inputShape');
      _debugLog('   │  └─ Output shape: $outputShape');

      // ─────────────────────────────────────────────────────────────────────
      // PASO 3: Cargar etiquetas
      // ─────────────────────────────────────────────────────────────────────
      final labelsData = await rootBundle.loadString(labelsPath);
      _labels = labelsData
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();

      _debugLog('   ├─ Labels cargados: ${_labels.length} clases');

      // Verificar que el número de clases coincide
      if (_labels.length != numClasses) {
        _debugLog('   ⚠️ ADVERTENCIA: Se esperaban $numClasses clases, se encontraron ${_labels.length}');
      }

      // ─────────────────────────────────────────────────────────────────────
      // PASO 4: Preasignar tensores
      // ─────────────────────────────────────────────────────────────────────
      _preallocateTensors();

      _isInitialized = true;
      _debugLog('   └─ ✅ YoloDetector inicializado correctamente');

    } catch (e, stackTrace) {
      _debugLog('   └─ ❌ Error inicializando YoloDetector: $e');
      _debugLog(stackTrace.toString());
      rethrow;
    }
  }

  /// Preasigna los tensores de entrada/salida para evitar realocaciones.
  void _preallocateTensors() {
    // Input: [1, 640, 640, 3]
    _inputTensor = List.generate(
      1,
          (_) => List.generate(
        inputSize,
            (_) => List.generate(
          inputSize,
              (_) => List.filled(3, 0.0),
        ),
      ),
    );

    // Output: [1, 87, 8400] donde 87 = 4 (bbox) + 83 (clases)
    _outputTensor = List.generate(
      1,
          (_) => List.generate(
        4 + numClasses, // 87
            (_) => List.filled(numPredictions, 0.0), // 8400
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DETECCIÓN PRINCIPAL
  // ═══════════════════════════════════════════════════════════════════════════

  /// Ejecuta detección de ingredientes sobre una imagen.
  ///
  /// [image] Imagen a analizar (cualquier tamaño, se redimensiona internamente)
  /// [confidenceThreshold] Umbral mínimo de confianza (default: 0.40)
  /// [iouThreshold] Umbral de IoU para NMS (default: 0.45)
  ///
  /// Returns: Lista de detecciones ordenadas por confianza (mayor a menor)
  ///
  /// Throws:
  /// - [StateError] si el detector no está inicializado
  Future<List<Detection>> detect(
      img.Image image, {
        double confidenceThreshold = defaultConfidenceThreshold,
        double iouThreshold = defaultIouThreshold,
      }) async {
    // Verificar inicialización
    if (!_isInitialized || _interpreter == null) {
      throw StateError(
        'YoloDetector no está inicializado. Llama a initialize() primero.',
      );
    }

    // ─────────────────────────────────────────────────────────────────────────
    // PASO 1: Preprocesamiento
    // ─────────────────────────────────────────────────────────────────────────
    final preprocessResult = _preprocess(image);

    // ─────────────────────────────────────────────────────────────────────────
    // PASO 2: Inferencia
    // ─────────────────────────────────────────────────────────────────────────
    _interpreter!.run(_inputTensor!, _outputTensor!);

    // ─────────────────────────────────────────────────────────────────────────
    // PASO 3: Postprocesamiento
    // ─────────────────────────────────────────────────────────────────────────
    final detections = _postprocess(
      _outputTensor!,
      preprocessResult,
      image.width,
      image.height,
      confidenceThreshold,
      iouThreshold,
    );

    return detections;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PREPROCESAMIENTO
  // ═══════════════════════════════════════════════════════════════════════════

  /// Preprocesa la imagen para el modelo YOLO.
  ///
  /// Operaciones:
  /// 1. Letterbox resize: Redimensiona manteniendo aspect ratio, padding gris
  /// 2. Normalización: Convierte píxeles de [0,255] a [0,1]
  /// 3. Conversión a tensor: Formato [1, H, W, C]
  _PreprocessResult _preprocess(img.Image image) {
    final int origWidth = image.width;
    final int origHeight = image.height;

    // ─────────────────────────────────────────────────────────────────────────
    // PASO 1: Calcular escala para letterbox
    // ─────────────────────────────────────────────────────────────────────────
    // Letterbox mantiene el aspect ratio original de la imagen
    // La dimensión más grande se ajusta a inputSize, la otra se centra con padding

    final double scaleWidth = inputSize / origWidth;
    final double scaleHeight = inputSize / origHeight;
    final double scale = min(scaleWidth, scaleHeight);

    final int newWidth = (origWidth * scale).round();
    final int newHeight = (origHeight * scale).round();

    // ─────────────────────────────────────────────────────────────────────────
    // PASO 2: Redimensionar imagen
    // ─────────────────────────────────────────────────────────────────────────
    final img.Image resized = img.copyResize(
      image,
      width: newWidth,
      height: newHeight,
      interpolation: img.Interpolation.linear,
    );

    // ─────────────────────────────────────────────────────────────────────────
    // PASO 3: Crear canvas con padding gris (114, 114, 114)
    // ─────────────────────────────────────────────────────────────────────────
    // El valor 114 es el estándar de Ultralytics YOLO
    // Representa un gris neutro que no interfiere con la detección

    final int padLeft = (inputSize - newWidth) ~/ 2;
    final int padTop = (inputSize - newHeight) ~/ 2;

    // ─────────────────────────────────────────────────────────────────────────
    // PASO 4: Llenar tensor de entrada con imagen normalizada
    // ─────────────────────────────────────────────────────────────────────────
    // Valor de padding normalizado: 114/255 ≈ 0.447
    const double padValue = 114.0 / 255.0;

    for (int y = 0; y < inputSize; y++) {
      for (int x = 0; x < inputSize; x++) {
        // Verificar si estamos en la región de la imagen o en el padding
        final int srcX = x - padLeft;
        final int srcY = y - padTop;

        if (srcX >= 0 && srcX < newWidth && srcY >= 0 && srcY < newHeight) {
          // Región de la imagen: obtener píxel y normalizar
          final pixel = resized.getPixel(srcX, srcY);
          _inputTensor![0][y][x][0] = pixel.r / 255.0; // R
          _inputTensor![0][y][x][1] = pixel.g / 255.0; // G
          _inputTensor![0][y][x][2] = pixel.b / 255.0; // B
        } else {
          // Región de padding: gris 114
          _inputTensor![0][y][x][0] = padValue;
          _inputTensor![0][y][x][1] = padValue;
          _inputTensor![0][y][x][2] = padValue;
        }
      }
    }

    return _PreprocessResult(
      scale: scale,
      padLeft: padLeft,
      padTop: padTop,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // POSTPROCESAMIENTO
  // ═══════════════════════════════════════════════════════════════════════════

  /// Postprocesa la salida del modelo para obtener detecciones.
  ///
  /// Operaciones:
  /// 1. Parsear output tensor [1, 87, 8400]
  /// 2. Filtrar por umbral de confianza
  /// 3. Convertir coordenadas de modelo a imagen original
  /// 4. Aplicar Non-Maximum Suppression (NMS)
  List<Detection> _postprocess(
      List<List<List<double>>> output,
      _PreprocessResult preprocess,
      int origWidth,
      int origHeight,
      double confidenceThreshold,
      double iouThreshold,
      ) {
    List<Detection> detections = [];

    // ─────────────────────────────────────────────────────────────────────────
    // PASO 1: Parsear cada predicción
    // ─────────────────────────────────────────────────────────────────────────
    // Output shape: [1, 87, 8400]
    // - Índices 0-3: cx, cy, w, h (centro x, centro y, ancho, alto)
    // - Índices 4-86: scores de las 83 clases

    for (int i = 0; i < numPredictions; i++) {
      // Extraer bounding box (en coordenadas del modelo 640x640)
      final double cx = output[0][0][i]; // Centro X
      final double cy = output[0][1][i]; // Centro Y
      final double w = output[0][2][i];  // Ancho
      final double h = output[0][3][i];  // Alto

      // Encontrar la clase con mayor score
      double maxScore = 0;
      int maxClassId = 0;

      for (int c = 0; c < numClasses; c++) {
        final double score = output[0][4 + c][i];
        if (score > maxScore) {
          maxScore = score;
          maxClassId = c;
        }
      }

      // Filtrar por umbral de confianza
      if (maxScore < confidenceThreshold) continue;

      // ─────────────────────────────────────────────────────────────────────
      // PASO 2: Convertir coordenadas a imagen original
      // ─────────────────────────────────────────────────────────────────────
      // 1. Convertir de centro a esquinas
      // 2. Quitar padding
      // 3. Escalar a dimensiones originales

      // Convertir de (cx, cy, w, h) a (x1, y1, x2, y2) en espacio del modelo
      final double x1Model = cx - w / 2;
      final double y1Model = cy - h / 2;
      final double x2Model = cx + w / 2;
      final double y2Model = cy + h / 2;

      // Quitar padding y escalar a imagen original
      final double x1 = ((x1Model - preprocess.padLeft) / preprocess.scale)
          .clamp(0, origWidth.toDouble());
      final double y1 = ((y1Model - preprocess.padTop) / preprocess.scale)
          .clamp(0, origHeight.toDouble());
      final double x2 = ((x2Model - preprocess.padLeft) / preprocess.scale)
          .clamp(0, origWidth.toDouble());
      final double y2 = ((y2Model - preprocess.padTop) / preprocess.scale)
          .clamp(0, origHeight.toDouble());

      // Verificar que el bounding box es válido
      if (x2 <= x1 || y2 <= y1) continue;

      // Obtener etiqueta
      final String label = maxClassId < _labels.length
          ? _labels[maxClassId]
          : 'clase_$maxClassId';

      detections.add(Detection(
        x1: x1,
        y1: y1,
        x2: x2,
        y2: y2,
        confidence: maxScore,
        classId: maxClassId,
        label: label,
      ));
    }

    // ─────────────────────────────────────────────────────────────────────────
    // PASO 3: Aplicar Non-Maximum Suppression
    // ─────────────────────────────────────────────────────────────────────────
    return _nonMaxSuppression(detections, iouThreshold);
  }

  /// Aplica Non-Maximum Suppression para eliminar detecciones duplicadas.
  ///
  /// NMS funciona así:
  /// 1. Ordenar detecciones por confianza (mayor a menor)
  /// 2. Para cada detección, eliminar las que tienen IoU > umbral
  /// 3. Solo se comparan detecciones de la MISMA clase
  List<Detection> _nonMaxSuppression(
      List<Detection> detections,
      double iouThreshold,
      ) {
    if (detections.isEmpty) return [];

    // Ordenar por confianza descendente
    detections.sort((a, b) => b.confidence.compareTo(a.confidence));

    List<Detection> result = [];
    List<bool> suppressed = List.filled(detections.length, false);

    for (int i = 0; i < detections.length; i++) {
      if (suppressed[i]) continue;

      // Esta detección no está suprimida, agregarla al resultado
      result.add(detections[i]);

      // Suprimir detecciones de la misma clase con alto IoU
      for (int j = i + 1; j < detections.length; j++) {
        if (suppressed[j]) continue;

        // Solo comparar si son de la misma clase
        if (detections[i].classId != detections[j].classId) continue;

        // Calcular IoU
        final double iou = detections[i].calculateIoU(detections[j]);

        // Suprimir si IoU es mayor al umbral
        if (iou >= iouThreshold) {
          suppressed[j] = true;
        }
      }
    }

    return result;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LIMPIEZA
  // ═══════════════════════════════════════════════════════════════════════════

  /// Libera los recursos del detector.
  ///
  /// Debe llamarse cuando el detector ya no se necesita para evitar memory leaks.
  void dispose() {
    if (_interpreter != null) {
      _interpreter!.close();
      _interpreter = null;
    }
    _inputTensor = null;
    _outputTensor = null;
    _labels = [];
    _isInitialized = false;
    _debugLog('🧹 YoloDetector disposed');
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// CLASES AUXILIARES PRIVADAS
// ═══════════════════════════════════════════════════════════════════════════════

/// Resultado del preprocesamiento, contiene información para
/// convertir coordenadas del modelo a la imagen original.
class _PreprocessResult {
  /// Factor de escala aplicado a la imagen
  final double scale;

  /// Padding izquierdo agregado (en píxeles del modelo)
  final int padLeft;

  /// Padding superior agregado (en píxeles del modelo)
  final int padTop;

  const _PreprocessResult({
    required this.scale,
    required this.padLeft,
    required this.padTop,
  });
}

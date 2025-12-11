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

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../../../core/exceptions/app_exceptions.dart';
import '../../../core/logging/app_logger.dart';
import '../../../data/models/detection.dart';

/// Detector de ingredientes alimenticios usando YOLO11n.
class YoloDetector {
  // ═══════════════════════════════════════════════════════════════════════════
  // CONSTANTES DEL MODELO
  // ═══════════════════════════════════════════════════════════════════════════

  static const String _tag = 'YoloDetector';

  static const int inputSize = 640;
  static const int numClasses = 83;
  static const int numPredictions = 8400;
  static const double defaultConfidenceThreshold = 0.40;
  static const double defaultIouThreshold = 0.45;
  static const String modelPath = 'assets/models/yolov11n_float32.tflite';
  static const String labelsPath = 'assets/labels/labels.txt';

  // Optimización: límite de detecciones antes de NMS para reducir O(n²)
  static const int maxDetectionsBeforeNms = 200;

  // ═══════════════════════════════════════════════════════════════════════════
  // PROPIEDADES PRIVADAS
  // ═══════════════════════════════════════════════════════════════════════════

  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isInitialized = false;
  bool _isDisposed = false;

  List<List<List<List<double>>>>? _inputTensor;
  List<List<List<double>>>? _outputTensor;

  // ═══════════════════════════════════════════════════════════════════════════
  // PROPIEDADES PÚBLICAS
  // ═══════════════════════════════════════════════════════════════════════════

  bool get isInitialized => _isInitialized;
  List<String> get labels => List.unmodifiable(_labels);
  int get labelCount => _labels.length;

  // ═══════════════════════════════════════════════════════════════════════════
  // INICIALIZACIÓN
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> initialize() async {
    if (_isDisposed) {
      throw ModelDisposedException();
    }

    if (_isInitialized) {
      AppLogger.warning('YoloDetector ya está inicializado', tag: _tag);
      return;
    }

    try {
      final options = InterpreterOptions();
      options.threads = 4;
      options.addDelegate(XNNPackDelegate());

      try {
        _interpreter = await Interpreter.fromAsset(
          modelPath,
          options: options,
        );
      } catch (e, stackTrace) {
        throw ModelLoadException(
          message: 'No se pudo cargar el modelo TFLite: $e',
          modelPath: modelPath,
          originalError: e,
          stackTrace: stackTrace,
        );
      }

      _interpreter!.allocateTensors();

      final inputShape = _interpreter!.getInputTensor(0).shape;
      final outputShape = _interpreter!.getOutputTensor(0).shape;

      try {
        final labelsData = await rootBundle.loadString(labelsPath);
        _labels = labelsData
            .split('\n')
            .map((line) => line.trim())
            .where((line) => line.isNotEmpty)
            .toList();
      } catch (e, stackTrace) {
        throw LabelsLoadException(
          message: 'No se pudo cargar el archivo de etiquetas: $e',
          labelsPath: labelsPath,
          originalError: e,
          stackTrace: stackTrace,
        );
      }

      if (_labels.length != numClasses) {
        AppLogger.warning(
          'Se esperaban $numClasses clases, se encontraron ${_labels.length}',
          tag: _tag,
        );
      }

      _preallocateTensors();

      _isInitialized = true;

      // Log estructurado de inicialización
      AppLogger.tree(
        'YoloDetector inicializado',
        [
          'Config: 4 threads + XNNPack delegate',
          'Modelo: ${modelPath.split('/').last}',
          'Input: $inputShape',
          'Output: $outputShape',
          'Labels: ${_labels.length} clases',
        ],
        tag: _tag,
      );
    } catch (e) {
      if (e is NutriVisionException) rethrow;
      throw ModelException(
        message: 'Error inicializando YoloDetector: $e',
        originalError: e,
      );
    }
  }

  void _preallocateTensors() {
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

    _outputTensor = List.generate(
      1,
          (_) => List.generate(
        4 + numClasses,
            (_) => List.filled(numPredictions, 0.0),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DETECCIÓN PRINCIPAL
  // ═══════════════════════════════════════════════════════════════════════════

  Future<List<Detection>> detect(
      img.Image image, {
        double confidenceThreshold = defaultConfidenceThreshold,
        double iouThreshold = defaultIouThreshold,
        bool verbose = true,
      }) async {
    if (_isDisposed) {
      throw ModelDisposedException();
    }

    if (!_isInitialized || _interpreter == null) {
      throw ModelNotInitializedException();
    }

    try {
      final preprocessResult = _preprocess(image);

      _interpreter!.run(_inputTensor!, _outputTensor!);

      final detections = _postprocess(
        _outputTensor!,
        preprocessResult,
        image.width,
        image.height,
        confidenceThreshold,
        iouThreshold,
        verbose: verbose,
      );

      if (verbose) {
        // Log resumido de detección
        final items = <String>[
          'Imagen: ${image.width}x${image.height}',
          'Scale: ${preprocessResult.scale.toStringAsFixed(3)}',
          'Detecciones: ${detections.length}',
        ];

        // Agregar primeras detecciones si hay
        if (kDebugMode && detections.isNotEmpty) {
          for (int i = 0; i < min(3, detections.length); i++) {
            final d = detections[i];
            items.add('${d.label}: ${d.confidenceFormatted}');
          }
        }

        AppLogger.tree('Detección completada', items, tag: _tag);
      }

      return detections;
    } on NutriVisionException {
      rethrow;
    } catch (e, stackTrace) {
      throw InferenceException(
        message: 'Error durante la inferencia: $e',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PREPROCESAMIENTO
  // ═══════════════════════════════════════════════════════════════════════════

  _PreprocessResult _preprocess(img.Image image) {
    try {
      final int origWidth = image.width;
      final int origHeight = image.height;

      final double scaleWidth = inputSize / origWidth;
      final double scaleHeight = inputSize / origHeight;
      final double scale = min(scaleWidth, scaleHeight);

      final int newWidth = (origWidth * scale).round();
      final int newHeight = (origHeight * scale).round();

      final img.Image resized = img.copyResize(
        image,
        width: newWidth,
        height: newHeight,
        interpolation: img.Interpolation.linear,
      );

      final int padLeft = (inputSize - newWidth) ~/ 2;
      final int padTop = (inputSize - newHeight) ~/ 2;

      const double padValue = 114.0 / 255.0;

      for (int y = 0; y < inputSize; y++) {
        for (int x = 0; x < inputSize; x++) {
          final int srcX = x - padLeft;
          final int srcY = y - padTop;

          if (srcX >= 0 && srcX < newWidth && srcY >= 0 && srcY < newHeight) {
            final pixel = resized.getPixel(srcX, srcY);
            _inputTensor![0][y][x][0] = pixel.r / 255.0;
            _inputTensor![0][y][x][1] = pixel.g / 255.0;
            _inputTensor![0][y][x][2] = pixel.b / 255.0;
          } else {
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
        newWidth: newWidth,
        newHeight: newHeight,
      );
    } catch (e, stackTrace) {
      throw PreprocessingException(
        message: 'Error en preprocesamiento de imagen: $e',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // POSTPROCESAMIENTO - CORREGIDO
  // ═══════════════════════════════════════════════════════════════════════════

  List<Detection> _postprocess(
      List<List<List<double>>> output,
      _PreprocessResult preprocess,
      int origWidth,
      int origHeight,
      double confidenceThreshold,
      double iouThreshold, {
      bool verbose = true,
      }) {
    try {
      List<Detection> detections = [];

      for (int i = 0; i < numPredictions; i++) {
        // Optimización: Early exit si ya tenemos suficientes detecciones
        if (detections.length >= maxDetectionsBeforeNms) {
          break;
        }

        // Coordenadas normalizadas (0-1)
        final double cxNorm = output[0][0][i];
        final double cyNorm = output[0][1][i];
        final double wNorm = output[0][2][i];
        final double hNorm = output[0][3][i];

        // Desnormalizar: convertir de rango [0,1] a [0,640]
        final double cx = cxNorm * inputSize;
        final double cy = cyNorm * inputSize;
        final double w = wNorm * inputSize;
        final double h = hNorm * inputSize;

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
        if (maxScore < confidenceThreshold) {
          continue;
        }

        // Convertir de (cx, cy, w, h) a (x1, y1, x2, y2) en espacio 640x640
        final double x1Model = cx - w / 2;
        final double y1Model = cy - h / 2;
        final double x2Model = cx + w / 2;
        final double y2Model = cy + h / 2;

        // Convertir de espacio del modelo (con padding) a imagen original
        final double x1 = (x1Model - preprocess.padLeft) / preprocess.scale;
        final double y1 = (y1Model - preprocess.padTop) / preprocess.scale;
        final double x2 = (x2Model - preprocess.padLeft) / preprocess.scale;
        final double y2 = (y2Model - preprocess.padTop) / preprocess.scale;

        // Clampear a los límites de la imagen original
        final double x1Clamped = x1.clamp(0.0, origWidth.toDouble());
        final double y1Clamped = y1.clamp(0.0, origHeight.toDouble());
        final double x2Clamped = x2.clamp(0.0, origWidth.toDouble());
        final double y2Clamped = y2.clamp(0.0, origHeight.toDouble());

        // Verificar que el bounding box es válido
        if (x2Clamped <= x1Clamped || y2Clamped <= y1Clamped) {
          continue;
        }

        // Obtener etiqueta
        final String label = maxClassId < _labels.length
            ? _labels[maxClassId]
            : 'clase_$maxClassId';

        detections.add(Detection.fromModelOutput(
          x1: x1Clamped,
          y1: y1Clamped,
          x2: x2Clamped,
          y2: y2Clamped,
          confidence: maxScore,
          classId: maxClassId,
          label: label,
          imageWidth: origWidth,
          imageHeight: origHeight,
        ));
      }

      return _nonMaxSuppression(detections, iouThreshold);
    } catch (e, stackTrace) {
      throw PostprocessingException(
        message: 'Error en postprocesamiento: $e',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  List<Detection> _nonMaxSuppression(
      List<Detection> detections,
      double iouThreshold,
      ) {
    if (detections.isEmpty) return [];

    detections.sort((a, b) => b.confidence.compareTo(a.confidence));

    List<Detection> result = [];
    List<bool> suppressed = List.filled(detections.length, false);

    for (int i = 0; i < detections.length; i++) {
      if (suppressed[i]) continue;

      result.add(detections[i]);

      for (int j = i + 1; j < detections.length; j++) {
        if (suppressed[j]) continue;
        if (detections[i].classId != detections[j].classId) continue;

        final double iou = detections[i].calculateIoU(detections[j]);
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

  void dispose() {
    if (_interpreter != null) {
      _interpreter!.close();
      _interpreter = null;
    }
    _inputTensor = null;
    _outputTensor = null;
    _labels = [];
    _isInitialized = false;
    _isDisposed = true;
    AppLogger.debug('YoloDetector disposed', tag: _tag);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// CLASES AUXILIARES
// ═══════════════════════════════════════════════════════════════════════════════

class _PreprocessResult {
  final double scale;
  final int padLeft;
  final int padTop;
  final int newWidth;
  final int newHeight;

  const _PreprocessResult({
    required this.scale,
    required this.padLeft,
    required this.padTop,
    required this.newWidth,
    required this.newHeight,
  });

  @override
  String toString() => '_PreprocessResult(scale: $scale, padLeft: $padLeft, padTop: $padTop)';
}

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

import 'dart:async' show Completer;
import 'dart:math';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../../../core/exceptions/app_exceptions.dart';
import '../../../core/logging/app_logger.dart';
import '../../../data/models/detection.dart';
import 'detection_debug_helper.dart';

/// Fuente de la imagen para detección.
enum DetectionSource {
  /// Imagen desde galería o captura (JPEG/PNG)
  photo,

  /// Frame de cámara en tiempo real (YUV420)
  live,
}

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
  /// IoU threshold reducido de 0.45 a 0.30 para evitar que NMS sea muy agresivo
  /// y elimine demasiadas detecciones en modo LIVE.
  static const double defaultIouThreshold = 0.30;
  static const String modelPath = 'assets/models/yolov11n_float32.tflite';
  static const String labelsPath = 'assets/labels/labels.txt';

  // Optimización: límite de detecciones antes de NMS para reducir O(n²)
  // Reducido de 200 a 50 para mejorar rendimiento
  static const int maxDetectionsBeforeNms = 50;

  // ═══════════════════════════════════════════════════════════════════════════
  // PROPIEDADES PRIVADAS
  // ═══════════════════════════════════════════════════════════════════════════

  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isInitialized = false;
  bool _isDisposed = false;

  // Completer para prevenir inicializaciones concurrentes
  Completer<void>? _initializationCompleter;

  List<List<List<List<double>>>>? _inputTensor;
  List<List<List<double>>>? _outputTensor;

  // Contador de inferencias para logging periódico
  int _inferenceCounter = 0;

  // Contador de validación para logging LIVE (cada 30 frames)
  int _validationCounter = 0;

  // ═══════════════════════════════════════════════════════════════════════════
  // PROPIEDADES PÚBLICAS
  // ═══════════════════════════════════════════════════════════════════════════

  bool get isInitialized => _isInitialized;
  List<String> get labels => List.unmodifiable(_labels);
  int get labelCount => _labels.length;

  // ═══════════════════════════════════════════════════════════════════════════
  // INICIALIZACIÓN
  // ═══════════════════════════════════════════════════════════════════════════

  /// Inicializa el detector YOLO con fallback GPU → CPU.
  ///
  /// Idempotente: múltiples llamadas concurrentes esperan a la primera.
  Future<void> initialize() async {
    // ═══════════════════════════════════════════════════════════════════════════
    // VERIFICACIONES INICIALES
    // ═══════════════════════════════════════════════════════════════════════════

    if (_isDisposed) {
      throw ModelDisposedException();
    }

    if (_isInitialized) {
      AppLogger.debug('YoloDetector ya inicializado', tag: _tag);
      return;
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // IDEMPOTENCIA: Evitar inicializaciones concurrentes
    // ═══════════════════════════════════════════════════════════════════════════

    if (_initializationCompleter != null) {
      AppLogger.debug('Esperando inicialización en curso...', tag: _tag);
      return _initializationCompleter!.future;
    }

    _initializationCompleter = Completer<void>();

    try {
      await _performInitialization();
      _isInitialized = true;
      _initializationCompleter!.complete();
      AppLogger.info('YoloDetector inicializado correctamente', tag: _tag);
    } catch (e) {
      _initializationCompleter!.completeError(e);
      rethrow;
    } finally {
      _initializationCompleter = null;
    }
  }

  /// Realiza la inicialización con fallback GPU → CPU.
  Future<void> _performInitialization() async {
    Interpreter? tempInterpreter;
    GpuDelegateV2? gpuDelegate;
    String delegateUsed = 'None';

    // ═══════════════════════════════════════════════════════════════════════════
    // INTENTO 1: GPU DELEGATE
    // ═══════════════════════════════════════════════════════════════════════════

    try {
      AppLogger.info('INIT GPU START', tag: _tag);

      final gpuOptions = InterpreterOptions();
      gpuOptions.threads = 4;

      // Crear GPU delegate
      gpuDelegate = GpuDelegateV2(
        options: GpuDelegateOptionsV2(
          isPrecisionLossAllowed: false, // Mantener FP32
        ),
      );
      gpuOptions.addDelegate(gpuDelegate);
      AppLogger.debug('GPU delegate created', tag: _tag);

      // Cargar modelo
      tempInterpreter = await Interpreter.fromAsset(
        modelPath,
        options: gpuOptions,
      );
      AppLogger.debug('Interpreter.fromAsset OK (GPU)', tag: _tag);

      // Allocate tensors
      tempInterpreter.allocateTensors();
      AppLogger.debug('GPU allocateTensors OK', tag: _tag);

      // Test de inferencia
      _testInference(tempInterpreter);
      AppLogger.debug('GPU test inference OK', tag: _tag);

      delegateUsed = 'GPU (GpuDelegateV2)';
      AppLogger.info('INIT GPU OK', tag: _tag);
    } catch (eGpu, stackGpu) {
      // ═══════════════════════════════════════════════════════════════════════════
      // GPU FALLÓ - LOG ERROR Y LIMPIAR RECURSOS
      // ═══════════════════════════════════════════════════════════════════════════

      AppLogger.error(
        'INIT GPU FAIL - Fallback to CPU',
        tag: _tag,
        error: eGpu,
      );
      AppLogger.debug('GPU error stack: $stackGpu', tag: _tag);

      // Limpiar recursos GPU
      try {
        tempInterpreter?.close();
        gpuDelegate?.delete();
      } catch (eCleanup) {
        AppLogger.warning('Error limpiando GPU: $eCleanup', tag: _tag);
      }
      tempInterpreter = null;

      // ═══════════════════════════════════════════════════════════════════════════
      // INTENTO 2: CPU (XNNPack) FALLBACK
      // ═══════════════════════════════════════════════════════════════════════════

      try {
        AppLogger.info('FALLBACK CPU START', tag: _tag);

        final cpuOptions = InterpreterOptions();
        cpuOptions.threads = 4;
        cpuOptions.addDelegate(XNNPackDelegate());
        AppLogger.debug('XNNPack delegate created', tag: _tag);

        // Cargar modelo con CPU delegate
        tempInterpreter = await Interpreter.fromAsset(
          modelPath,
          options: cpuOptions,
        );
        AppLogger.debug('Interpreter.fromAsset OK (CPU)', tag: _tag);

        // Allocate tensors
        tempInterpreter.allocateTensors();
        AppLogger.debug('CPU allocateTensors OK', tag: _tag);

        // Test de inferencia
        _testInference(tempInterpreter);
        AppLogger.debug('CPU test inference OK', tag: _tag);

        delegateUsed = 'XNNPack (CPU)';
        AppLogger.info('FALLBACK CPU OK', tag: _tag);
      } catch (eCpu, stackCpu) {
        // ═══════════════════════════════════════════════════════════════════════════
        // CPU TAMBIÉN FALLÓ - ERROR FATAL
        // ═══════════════════════════════════════════════════════════════════════════

        AppLogger.error(
          'FALLBACK CPU FAIL',
          tag: _tag,
          error: eCpu,
        );
        AppLogger.debug('CPU error stack: $stackCpu', tag: _tag);

        // Limpiar recursos CPU
        try {
          tempInterpreter?.close();
        } catch (eCleanup) {
          AppLogger.warning('Error limpiando CPU: $eCleanup', tag: _tag);
        }
        tempInterpreter = null;

        throw ModelLoadException(
          message: 'Falló inicialización GPU y CPU:\nGPU: $eGpu\nCPU: $eCpu',
          modelPath: modelPath,
          originalError: eCpu,
          stackTrace: stackCpu,
        );
      }
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // ÉXITO: ASIGNAR INTERPRETER VÁLIDO
    // ═══════════════════════════════════════════════════════════════════════════

    _interpreter = tempInterpreter;

    // ═══════════════════════════════════════════════════════════════════════════
    // CARGAR LABELS
    // ═══════════════════════════════════════════════════════════════════════════

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

    // ═══════════════════════════════════════════════════════════════════════════
    // PREALLOCAR TENSORS
    // ═══════════════════════════════════════════════════════════════════════════

    _preallocateTensors();

    // ═══════════════════════════════════════════════════════════════════════════
    // LOG FINAL
    // ═══════════════════════════════════════════════════════════════════════════

    final inputShape = _interpreter!.getInputTensor(0).shape;
    final outputShape = _interpreter!.getOutputTensor(0).shape;

    AppLogger.tree(
      'YoloDetector inicializado',
      [
        'Config: 4 threads + $delegateUsed',
        'Modelo: ${modelPath.split('/').last}',
        'Input: $inputShape',
        'Output: $outputShape',
        'Labels: ${_labels.length} clases',
      ],
      tag: _tag,
    );
  }

  /// Ejecuta una inferencia de prueba con datos dummy para verificar
  /// que el interpreter está funcionando correctamente.
  ///
  /// Lanza exception si la inferencia falla.
  void _testInference(Interpreter interpreter) {
    try {
      // Crear tensor dummy de entrada [1, 640, 640, 3]
      final dummyInput = List.generate(
        1,
        (_) => List.generate(
          640,
          (_) => List.generate(
            640,
            (_) => List.filled(3, 0.0),
          ),
        ),
      );

      // Crear tensor dummy de salida [1, 87, 8400]
      final dummyOutput = List.generate(
        1,
        (_) => List.generate(
          87,
          (_) => List.filled(8400, 0.0),
        ),
      );

      // Ejecutar inferencia
      interpreter.run(dummyInput, dummyOutput);
    } catch (e, stack) {
      throw ModelException(
        message: 'Test de inferencia falló: $e',
        originalError: e,
        stackTrace: stack,
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
    DetectionSource? debugSource, // Para debug helper (opcional)
  }) async {
    if (_isDisposed) {
      throw ModelDisposedException();
    }

    if (!_isInitialized || _interpreter == null) {
      throw ModelNotInitializedException();
    }

    try {
      // ════════════════════════════════════════════════════════════
      // DEBUG: Guardar imagen RGB original (antes de preprocesado)
      // ════════════════════════════════════════════════════════════
      if (debugSource != null) {
        await DetectionDebugHelper.saveRgbConverted(
          image,
          debugSource.name,
        );
      }

      // ════════════════════════════════════════════════════════════
      // INSTRUMENTACIÓN: Sub-etapas de inferencia
      // ════════════════════════════════════════════════════════════
      final stopwatchPreprocess = Stopwatch()..start();
      final preprocessResult = _preprocess(image);
      stopwatchPreprocess.stop();

      // NOTA: No guardamos imagen preprocesada porque ya está en tensor Float32List
      // (requeriría reconstrucción compleja desde el tensor)

      final stopwatchRun = Stopwatch()..start();
      _interpreter!.run(_inputTensor!, _outputTensor!);
      stopwatchRun.stop();

      final stopwatchPostprocess = Stopwatch()..start();
      final detections = _postprocess(
        _outputTensor!,
        preprocessResult,
        image.width,
        image.height,
        confidenceThreshold,
        iouThreshold,
        verbose: verbose,
      );
      stopwatchPostprocess.stop();

      _inferenceCounter++;

      // Loggear cada 10 inferencias para no saturar
      if (verbose && _inferenceCounter % 10 == 0) {
        AppLogger.tree(
          'YOLO Metrics (Inference #$_inferenceCounter)',
          [
            'Preprocess: ${stopwatchPreprocess.elapsedMilliseconds}ms',
            'Interpreter.run: ${stopwatchRun.elapsedMilliseconds}ms',
            'Postprocess+NMS: ${stopwatchPostprocess.elapsedMilliseconds}ms',
            'Total YOLO: ${stopwatchPreprocess.elapsedMilliseconds + stopwatchRun.elapsedMilliseconds + stopwatchPostprocess.elapsedMilliseconds}ms',
            'Detecciones: ${detections.length}',
          ],
          tag: _tag,
        );
      } else if (verbose) {
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

  /// Detecta objetos desde diferentes fuentes con pipeline unificado y logging.
  ///
  /// Esta función wrapper unifica el logging para validar que PHOTO y LIVE
  /// usan exactamente los mismos parámetros (confidence, iou, preprocesado).
  ///
  /// [source] - Fuente de la imagen (photo o live)
  /// [image] - Imagen ya decodificada a RGB (puede venir de JPEG o YUV→RGB)
  /// [confidenceThreshold] - Umbral de confianza (default: 0.40 para ambos)
  /// [iouThreshold] - Umbral IoU para NMS (default: 0.45 para ambos)
  Future<List<Detection>> detectFromSource({
    required DetectionSource source,
    required img.Image image,
    double? confidenceThreshold,
    double? iouThreshold,
  }) async {
    final threshold = confidenceThreshold ?? defaultConfidenceThreshold;
    final iou = iouThreshold ?? defaultIouThreshold;

    // ═══════════════════════════════════════════════════════════════════════════
    // LOGGING UNIFICADO: Validar que PHOTO y LIVE usan mismos parámetros
    // ═══════════════════════════════════════════════════════════════════════════

    final shouldLog = source == DetectionSource.photo ||
        (_validationCounter % 30 == 0);

    if (shouldLog && kDebugMode) {
      AppLogger.debug(
        'Pipeline ${source.name.toUpperCase()}:\n'
        '  originalW/H: ${image.width}x${image.height}\n'
        '  inputModelW/H: $inputSize x $inputSize\n'
        '  confidenceThreshold: $threshold\n'
        '  iouThreshold: $iou',
        tag: _tag,
      );
    }

    if (source == DetectionSource.live) {
      _validationCounter++;
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // DELEGAR AL PIPELINE EXISTENTE (ya unificado)
    // ═══════════════════════════════════════════════════════════════════════════

    // verbose=false para LIVE (evitar saturar logs)
    // verbose=true para PHOTO (logs detallados útiles)
    final verbose = source == DetectionSource.photo;

    return detect(
      image,
      confidenceThreshold: threshold,
      iouThreshold: iou,
      verbose: verbose,
      debugSource: source, // Activar debug helper si está habilitado
    );
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

      // ════════════════════════════════════════════════════════════
      // OPTIMIZACIÓN: Acceso directo a bytes en vez de getPixel()
      // Evita 409,600 llamadas a getPixel() (640×640)
      // ════════════════════════════════════════════════════════════

      // Obtener bytes de la imagen redimensionada
      // El formato es RGBA (4 bytes por pixel)
      final resizedBytes = resized.getBytes(order: img.ChannelOrder.rgba);

      for (int y = 0; y < inputSize; y++) {
        for (int x = 0; x < inputSize; x++) {
          final int srcX = x - padLeft;
          final int srcY = y - padTop;

          if (srcX >= 0 && srcX < newWidth && srcY >= 0 && srcY < newHeight) {
            // Acceso directo a bytes (RGBA format: 4 bytes per pixel)
            final int index = (srcY * newWidth + srcX) * 4;
            _inputTensor![0][y][x][0] = resizedBytes[index] / 255.0; // R
            _inputTensor![0][y][x][1] = resizedBytes[index + 1] / 255.0; // G
            _inputTensor![0][y][x][2] = resizedBytes[index + 2] / 255.0; // B
            // Alpha channel (index+3) no se usa
          } else {
            // Padding con valor gris (114)
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

      // ════════════════════════════════════════════════════════════
      // OPTIMIZACIÓN: TopK antes de NMS para reducir O(n²)
      // Ordenar por confidence y tomar top 50 antes de NMS
      // ════════════════════════════════════════════════════════════

      if (detections.length > maxDetectionsBeforeNms) {
        detections.sort((a, b) => b.confidence.compareTo(a.confidence));
        detections = detections.sublist(0, maxDetectionsBeforeNms);
      }

      final finalDetections = _nonMaxSuppression(detections, iouThreshold);

      // Logging para debugging LIVE vs PHOTO
      if (verbose || (_validationCounter > 0 && _validationCounter % 30 == 0)) {
        AppLogger.debug(
          'Postprocessing Results:\n'
          '  #Detections pre-NMS: ${detections.length}\n'
          '  #Detections post-NMS: ${finalDetections.length}\n'
          '  Confidence threshold: $confidenceThreshold\n'
          '  IoU threshold: $iouThreshold',
          tag: _tag,
        );
      }

      return finalDetections;
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
  String toString() =>
      '_PreprocessResult(scale: $scale, padLeft: $padLeft, padTop: $padTop)';
}

// ╔═══════════════════════════════════════════════════════════════════════════════╗
// ║                           detection_service.dart                              ║
// ║              Procesador de frames de cámara para detección YOLO               ║
// ╠═══════════════════════════════════════════════════════════════════════════════╣
// ║  Convierte frames de cámara (YUV420) a formato RGB para inferencia.           ║
// ║  Usa código nativo C++ (si disponible) o Isolates como fallback.              ║
// ╚═══════════════════════════════════════════════════════════════════════════════╝

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import '../../../core/constants/app_constants.dart';
import '../../../core/exceptions/app_exceptions.dart';
import '../../../core/logging/app_logger.dart';
import '../../../data/models/detection.dart';
import 'image_processing_isolate.dart';
import 'native_image_processor.dart';
import 'yolo_service.dart';

/// Procesador de frames de cámara para detección en tiempo real.
///
/// Maneja:
/// - Conversión YUV420 → RGB
/// - Rotación según orientación del sensor
/// - Throttling para evitar sobrecarga
/// - Invocación del detector YOLO
class CameraFrameProcessor {
  // ═══════════════════════════════════════════════════════════════════════════
  // CONSTANTES
  // ═══════════════════════════════════════════════════════════════════════════

  static const String _tag = 'CameraProcessor';

  // ═══════════════════════════════════════════════════════════════════════════
  // PROPIEDADES
  // ═══════════════════════════════════════════════════════════════════════════

  final YoloDetector _detector;

  /// Indica si se está procesando un frame actualmente.
  bool _isProcessing = false;

  /// Contador de frames para throttling.
  int _frameCounter = 0;

  // ═══════════════════════════════════════════════════════════════════════════
  // CONSTRUCTOR
  // ═══════════════════════════════════════════════════════════════════════════

  CameraFrameProcessor(this._detector);

  // ═══════════════════════════════════════════════════════════════════════════
  // GETTERS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Indica si el procesador está ocupado.
  bool get isBusy => _isProcessing;

  /// Número de frames procesados.
  int get processedFrames => _frameCounter;

  // ═══════════════════════════════════════════════════════════════════════════
  // PROCESAMIENTO PRINCIPAL
  // ═══════════════════════════════════════════════════════════════════════════

  /// Intenta procesar un frame de cámara.
  ///
  /// Retorna `null` si:
  /// - Ya se está procesando otro frame
  /// - No han pasado suficientes frames (throttling)
  /// - El tiempo mínimo entre inferencias no ha pasado
  ///
  /// [cameraImage] - Frame de la cámara en formato YUV420
  /// [sensorOrientation] - Orientación del sensor de la cámara en grados
  /// [isFrontCamera] - Si es la cámara frontal (para espejo)
  /// [confidenceThreshold] - Umbral mínimo de confianza para detecciones
  /// [iouThreshold] - Umbral IoU para Non-Maximum Suppression
  Future<ProcessingResult?> processFrame(
    CameraImage cameraImage, {
    int sensorOrientation = 90,
    bool isFrontCamera = false,
    double? confidenceThreshold,
    double? iouThreshold,
  }) async {
    // SIMPLIFICADO: Solo verificar si está ocupado
    // El flag isBusy ya proporciona throttling natural
    // Los checks adicionales descartaban frames innecesariamente
    if (_isProcessing) {
      return null;
    }

    _frameCounter++;
    _isProcessing = true;

    try {
      // ════════════════════════════════════════════════════════════
      // INSTRUMENTACIÓN: Timers por etapa
      // ════════════════════════════════════════════════════════════
      final stopwatchTotal = Stopwatch()..start();
      final stopwatchConversion = Stopwatch();

      img.Image? finalImage;
      int outputWidth = cameraImage.width;
      int outputHeight = cameraImage.height;

      // ETAPA 1: Conversión YUV→RGB
      stopwatchConversion.start();

      // Intentar conversión nativa primero (más rápida)
      if (NativeImageProcessor.isAvailable) {
        finalImage = await _tryNativeConversion(
          cameraImage,
          sensorOrientation,
          isFrontCamera,
        );
      }

      // Fallback a isolate si nativo no disponible/falló
      if (finalImage == null) {
        AppLogger.debug('Usando fallback Isolate', tag: _tag);
        final isolateResult = await _convertWithIsolate(
          cameraImage,
          sensorOrientation,
          isFrontCamera,
        );
        if (isolateResult != null) {
          finalImage = isolateResult.image;
          outputWidth = isolateResult.width;
          outputHeight = isolateResult.height;
        }
      } else {
        // Ajustar dimensiones según rotación (nativo exitoso)
        if (sensorOrientation == 90 || sensorOrientation == 270) {
          final temp = outputWidth;
          outputWidth = outputHeight;
          outputHeight = temp;
        }
      }

      stopwatchConversion.stop();

      if (finalImage == null) {
        AppLogger.warning('No se pudo convertir el frame', tag: _tag);
        return null;
      }

      // Ejecutar detección con pipeline unificado (LIVE)
      final detections = await _detector.detectFromSource(
        source: DetectionSource.live,
        image: finalImage,
        confidenceThreshold:
            confidenceThreshold ?? AppConstants.realtimeConfidenceThreshold,
        iouThreshold: iouThreshold,
      );

      stopwatchTotal.stop();

      // Loggear métricas cada 10 inferencias para no saturar
      if (_frameCounter % 10 == 0) {
        final detectionLabels = detections.map((d) => d.label).join(', ');
        AppLogger.tree(
          '📊 Frame #$_frameCounter Performance',
          [
            '📷 Input: ${cameraImage.width}x${cameraImage.height} YUV',
            '🖼️  Output: ${outputWidth}x$outputHeight RGB',
            '🎚️  Confidence: ${(confidenceThreshold ?? AppConstants.realtimeConfidenceThreshold).toStringAsFixed(2)}',
            '⏱️  Total: ${stopwatchTotal.elapsedMilliseconds}ms',
            '   ├─ YUV→RGB: ${stopwatchConversion.elapsedMilliseconds}ms',
            '   └─ Detección: ${stopwatchTotal.elapsedMilliseconds - stopwatchConversion.elapsedMilliseconds}ms',
            '📈 FPS: ${(1000 / stopwatchTotal.elapsedMilliseconds).toStringAsFixed(1)}',
            '🎯 DETECCIONES: ${detections.length}',
            if (detections.isNotEmpty) '   └─ Labels: $detectionLabels',
          ],
          tag: _tag,
        );
      }

      return ProcessingResult(
        detections: detections,
        inferenceTimeMs: stopwatchTotal.elapsedMilliseconds,
        imageWidth: outputWidth,
        imageHeight: outputHeight,
      );
    } on NutriVisionException {
      rethrow;
    } catch (e, stackTrace) {
      throw FrameConversionException(
        message: 'Error procesando frame: $e',
        originalError: e,
        stackTrace: stackTrace,
      );
    } finally {
      _isProcessing = false;
    }
  }

  /// Intenta conversión usando código nativo C++.
  Future<img.Image?> _tryNativeConversion(
    CameraImage cameraImage,
    int sensorOrientation,
    bool isFrontCamera,
  ) async {
    try {
      if (cameraImage.planes.length < 3) return null;

      final yPlane = cameraImage.planes[0];
      final uPlane = cameraImage.planes[1];
      final vPlane = cameraImage.planes[2];

      // OPTIMIZACIÓN: Evitar copias innecesarias, pasar bytes directamente
      final rgbBytes = await NativeImageProcessor.convertYuvToRgb(
        yBytes: yPlane.bytes,
        uBytes: uPlane.bytes,
        vBytes: vPlane.bytes,
        width: cameraImage.width,
        height: cameraImage.height,
        yRowStride: yPlane.bytesPerRow,
        uvRowStride: uPlane.bytesPerRow,
        uvPixelStride: uPlane.bytesPerPixel ?? 1,
      );

      if (rgbBytes == null) return null;

      // Crear imagen desde bytes RGB
      final image = img.Image.fromBytes(
        width: cameraImage.width,
        height: cameraImage.height,
        bytes: rgbBytes.buffer,
        format: img.Format.uint8,
        numChannels: 3,
      );

      // Rotar según orientación
      img.Image rotatedImage;
      switch (sensorOrientation) {
        case 90:
          rotatedImage = img.copyRotate(image, angle: 90);
          break;
        case 180:
          rotatedImage = img.copyRotate(image, angle: 180);
          break;
        case 270:
          rotatedImage = img.copyRotate(image, angle: 270);
          break;
        default:
          rotatedImage = image;
      }

      // Espejo para cámara frontal
      return isFrontCamera ? img.flipHorizontal(rotatedImage) : rotatedImage;
    } catch (e) {
      AppLogger.warning('Error en conversión nativa: $e', tag: _tag);
      return null;
    }
  }

  /// Convierte usando isolate (fallback).
  Future<_IsolateResult?> _convertWithIsolate(
    CameraImage cameraImage,
    int sensorOrientation,
    bool isFrontCamera,
  ) async {
    final input = _prepareIsolateInput(
      cameraImage,
      sensorOrientation,
      isFrontCamera,
    );

    if (input == null) return null;

    final conversionResult = await compute(
      convertYuvToRgbIsolate,
      input,
    );

    if (!conversionResult.isSuccess || conversionResult.rgbBytes == null) {
      AppLogger.warning(
          'Conversión en isolate falló: ${conversionResult.error}',
          tag: _tag);
      return null;
    }

    // OPTIMIZACIÓN: Crear imagen desde bytes RGB crudos (sin PNG decode)
    final image = img.Image.fromBytes(
      width: conversionResult.width,
      height: conversionResult.height,
      bytes: conversionResult.rgbBytes!.buffer,
      format: img.Format.uint8,
      numChannels: 3,
    );

    return _IsolateResult(
      image: image,
      width: conversionResult.width,
      height: conversionResult.height,
    );
  }

  /// Prepara los datos del frame para enviar al isolate.
  YuvConversionInput? _prepareIsolateInput(
    CameraImage cameraImage,
    int sensorOrientation,
    bool isFrontCamera,
  ) {
    try {
      if (cameraImage.planes.length < 3) {
        AppLogger.warning('Frame no tiene 3 planos YUV', tag: _tag);
        return null;
      }

      final yPlane = cameraImage.planes[0];
      final uPlane = cameraImage.planes[1];
      final vPlane = cameraImage.planes[2];

      return YuvConversionInput(
        width: cameraImage.width,
        height: cameraImage.height,
        yBytes: Uint8List.fromList(yPlane.bytes),
        uBytes: Uint8List.fromList(uPlane.bytes),
        vBytes: Uint8List.fromList(vPlane.bytes),
        yRowStride: yPlane.bytesPerRow,
        uvRowStride: uPlane.bytesPerRow,
        uvPixelStride: uPlane.bytesPerPixel ?? 1,
        sensorOrientation: sensorOrientation,
        flipHorizontal: isFrontCamera,
      );
    } catch (e) {
      AppLogger.error('Error preparando input para isolate',
          tag: _tag, error: e);
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UTILIDADES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Resetea el contador de frames.
  void resetCounter() {
    _frameCounter = 0;
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// RESULTADO DEL PROCESAMIENTO
// ═══════════════════════════════════════════════════════════════════════════════

/// Resultado del procesamiento de un frame.
class ProcessingResult {
  /// Detecciones encontradas en el frame.
  final List<Detection> detections;

  /// Tiempo de inferencia en milisegundos.
  final int inferenceTimeMs;

  /// Ancho de la imagen procesada.
  final int imageWidth;

  /// Alto de la imagen procesada.
  final int imageHeight;

  const ProcessingResult({
    required this.detections,
    required this.inferenceTimeMs,
    required this.imageWidth,
    required this.imageHeight,
  });

  /// Número de detecciones.
  int get count => detections.length;

  /// FPS estimado basado en tiempo de inferencia.
  double get estimatedFps => inferenceTimeMs > 0 ? 1000 / inferenceTimeMs : 0;

  @override
  String toString() =>
      'ProcessingResult(detections: $count, time: ${inferenceTimeMs}ms, fps: ${estimatedFps.toStringAsFixed(1)})';
}

/// Resultado interno de conversión en isolate.
class _IsolateResult {
  final img.Image image;
  final int width;
  final int height;

  const _IsolateResult({
    required this.image,
    required this.width,
    required this.height,
  });
}

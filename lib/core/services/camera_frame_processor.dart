// ╔═══════════════════════════════════════════════════════════════════════════════╗
// ║                         camera_frame_processor.dart                           ║
// ║              Procesador de frames de cámara para detección YOLO               ║
// ╠═══════════════════════════════════════════════════════════════════════════════╣
// ║  Convierte frames de cámara (YUV420) a formato RGB para inferencia.           ║
// ║  Implementa throttling para evitar sobrecarga del dispositivo.                ║
// ╚═══════════════════════════════════════════════════════════════════════════════╝

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import '../constants/app_constants.dart';
import '../exceptions/app_exceptions.dart';
import '../../data/models/detection.dart';
import '../../ml/yolo_detector.dart';

/// Procesador de frames de cámara para detección en tiempo real.
///
/// Maneja:
/// - Conversión YUV420 → RGB
/// - Rotación según orientación del sensor
/// - Throttling para evitar sobrecarga
/// - Invocación del detector YOLO
class CameraFrameProcessor {
  // ═══════════════════════════════════════════════════════════════════════════
  // PROPIEDADES
  // ═══════════════════════════════════════════════════════════════════════════

  final YoloDetector _detector;

  /// Indica si se está procesando un frame actualmente.
  bool _isProcessing = false;

  /// Contador de frames para throttling.
  int _frameCounter = 0;

  /// Timestamp del último procesamiento.
  DateTime _lastProcessTime = DateTime.now();

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
  Future<ProcessingResult?> processFrame(
    CameraImage cameraImage, {
    int sensorOrientation = 90,
    bool isFrontCamera = false,
  }) async {
    // Verificar si está ocupado
    if (_isProcessing) {
      return null;
    }

    // Throttling por contador de frames
    _frameCounter++;
    if (_frameCounter % AppConstants.cameraFrameSkip != 0) {
      return null;
    }

    // Throttling por tiempo mínimo
    final now = DateTime.now();
    final elapsed = now.difference(_lastProcessTime).inMilliseconds;
    if (elapsed < AppConstants.minInferenceIntervalMs) {
      return null;
    }

    _isProcessing = true;
    _lastProcessTime = now;

    try {
      final stopwatch = Stopwatch()..start();

      // Convertir YUV420 a RGB
      final rgbImage = _convertYUV420ToRGB(cameraImage);
      if (rgbImage == null) {
        return null;
      }

      // Rotar según orientación del sensor
      final rotatedImage = _rotateImage(rgbImage, sensorOrientation);

      // Espejo para cámara frontal
      final finalImage = isFrontCamera
          ? img.flipHorizontal(rotatedImage)
          : rotatedImage;

      // Ejecutar detección
      final detections = await _detector.detect(
        finalImage,
        confidenceThreshold: AppConstants.realtimeConfidenceThreshold,
      );

      stopwatch.stop();

      return ProcessingResult(
        detections: detections,
        inferenceTimeMs: stopwatch.elapsedMilliseconds,
        imageWidth: finalImage.width,
        imageHeight: finalImage.height,
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

  // ═══════════════════════════════════════════════════════════════════════════
  // CONVERSIÓN YUV420 → RGB
  // ═══════════════════════════════════════════════════════════════════════════

  /// Convierte un frame YUV420 de la cámara a imagen RGB.
  ///
  /// El formato YUV420 es el más común en cámaras Android.
  /// Estructura de planes:
  /// - Plane 0: Y (luminancia)
  /// - Plane 1: U (crominancia)
  /// - Plane 2: V (crominancia)
  img.Image? _convertYUV420ToRGB(CameraImage cameraImage) {
    try {
      final int width = cameraImage.width;
      final int height = cameraImage.height;

      // Verificar que tenemos los 3 planos YUV
      if (cameraImage.planes.length < 3) {
        _debugLog('⚠️ Frame no tiene 3 planos YUV');
        return null;
      }

      final yPlane = cameraImage.planes[0];
      final uPlane = cameraImage.planes[1];
      final vPlane = cameraImage.planes[2];

      final int yRowStride = yPlane.bytesPerRow;
      final int uvRowStride = uPlane.bytesPerRow;
      final int uvPixelStride = uPlane.bytesPerPixel ?? 1;

      final Uint8List yBytes = yPlane.bytes;
      final Uint8List uBytes = uPlane.bytes;
      final Uint8List vBytes = vPlane.bytes;

      // Crear imagen de salida
      final img.Image image = img.Image(width: width, height: height);

      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          // Índice en el plano Y
          final int yIndex = y * yRowStride + x;

          // Índice en los planos UV (submuestreados 2x2)
          final int uvIndex = (y ~/ 2) * uvRowStride + (x ~/ 2) * uvPixelStride;

          // Obtener valores YUV
          final int yValue = yBytes[yIndex];
          final int uValue = uBytes[uvIndex];
          final int vValue = vBytes[uvIndex];

          // Convertir YUV a RGB usando fórmula ITU-R BT.601
          int r = (yValue + 1.402 * (vValue - 128)).round().clamp(0, 255);
          int g = (yValue - 0.344136 * (uValue - 128) - 0.714136 * (vValue - 128))
              .round()
              .clamp(0, 255);
          int b = (yValue + 1.772 * (uValue - 128)).round().clamp(0, 255);

          image.setPixelRgb(x, y, r, g, b);
        }
      }

      return image;
    } catch (e) {
      _debugLog('❌ Error en conversión YUV→RGB: $e');
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ROTACIÓN DE IMAGEN
  // ═══════════════════════════════════════════════════════════════════════════

  /// Rota la imagen según la orientación del sensor de la cámara.
  ///
  /// Los sensores de cámara típicamente reportan orientaciones de:
  /// - 0°: Landscape izquierda
  /// - 90°: Portrait normal (más común en Android)
  /// - 180°: Landscape derecha
  /// - 270°: Portrait invertido
  img.Image _rotateImage(img.Image image, int sensorOrientation) {
    switch (sensorOrientation) {
      case 90:
        return img.copyRotate(image, angle: 90);
      case 180:
        return img.copyRotate(image, angle: 180);
      case 270:
        return img.copyRotate(image, angle: 270);
      case 0:
      default:
        return image;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UTILIDADES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Resetea el contador de frames.
  void resetCounter() {
    _frameCounter = 0;
  }

  /// Log condicional solo en modo debug.
  void _debugLog(String message) {
    if (kDebugMode) {
      debugPrint('[CameraFrameProcessor] $message');
    }
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
  double get estimatedFps =>
      inferenceTimeMs > 0 ? 1000 / inferenceTimeMs : 0;

  @override
  String toString() =>
      'ProcessingResult(detections: $count, time: ${inferenceTimeMs}ms, fps: ${estimatedFps.toStringAsFixed(1)})';
}

// ╔═══════════════════════════════════════════════════════════════════════════════╗
// ║                        detection_controller.dart                              ║
// ║           Controlador centralizado de detección en tiempo real                ║
// ╠═══════════════════════════════════════════════════════════════════════════════╣
// ║  Gestiona el ciclo de vida completo de la detección YOLO:                    ║
// ║  - Lazy loading del YoloDetector (solo al activar detección)                 ║
// ║  - Control ON/OFF de detección                                               ║
// ║  - Throttling de inferencias                                                 ║
// ║  - Métricas runtime (FPS, latency, confidence)                               ║
// ║  - Cleanup de recursos                                                       ║
// ╚═══════════════════════════════════════════════════════════════════════════════╝

import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/logging/app_logger.dart';
import '../../../data/models/detection.dart';
import 'yolo_detector.dart';
import 'camera_frame_processor.dart';

/// Controlador que gestiona el ciclo de vida completo de la detección.
///
/// Responsabilidades:
/// - Lazy initialization del YoloDetector
/// - Control ON/OFF de detección
/// - Throttling de inferencias
/// - Métricas runtime (FPS, latency, confidence)
/// - Cleanup de recursos
class DetectionController {
  static const String _tag = 'DetectionController';

  // ═══════════════════════════════════════════════════════════════════════════
  // ESTADO PRIVADO
  // ═══════════════════════════════════════════════════════════════════════════

  YoloDetector? _detector;
  CameraFrameProcessor? _frameProcessor;

  bool _isDetectionActive = false;
  bool _isInitializing = false;
  bool _isInferring = false;

  // Throttling
  int _frameCounter = 0;
  DateTime? _lastInferenceTime;

  // Métricas runtime
  final List<int> _recentInferenceTimes = []; // Últimos 30 tiempos
  final List<double> _recentConfidences = []; // Últimos 30 confidences
  int _totalFramesProcessed = 0;
  DateTime? _sessionStartTime;

  // Callbacks
  Function(List<Detection>, RuntimeMetrics)? _onDetectionsUpdated;
  Function(String)? _onError;
  Function(bool)? _onInitializingChanged;

  // ═══════════════════════════════════════════════════════════════════════════
  // GETTERS PÚBLICOS
  // ═══════════════════════════════════════════════════════════════════════════

  bool get isDetectionActive => _isDetectionActive;
  bool get isInitializing => _isInitializing;
  bool get isInitialized => _detector?.isInitialized ?? false;
  bool get isBusy => _isInferring || (_frameProcessor?.isBusy ?? false);

  RuntimeMetrics get currentMetrics => _calculateMetrics();

  // ═══════════════════════════════════════════════════════════════════════════
  // INICIALIZACIÓN
  // ═══════════════════════════════════════════════════════════════════════════

  /// Registra callbacks para comunicarse con la UI.
  void registerCallbacks({
    Function(List<Detection>, RuntimeMetrics)? onDetectionsUpdated,
    Function(String)? onError,
    Function(bool)? onInitializingChanged,
  }) {
    _onDetectionsUpdated = onDetectionsUpdated;
    _onError = onError;
    _onInitializingChanged = onInitializingChanged;
  }

  /// Inicializa el detector de forma lazy (solo si no está inicializado).
  ///
  /// Retorna `true` si la inicialización fue exitosa.
  Future<bool> _ensureDetectorInitialized() async {
    if (_detector != null && _detector!.isInitialized) {
      return true; // Ya inicializado
    }

    if (_isInitializing) {
      AppLogger.debug('Inicialización ya en progreso, esperando...',
          tag: _tag);
      // Esperar a que termine la inicialización en curso
      while (_isInitializing) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return _detector?.isInitialized ?? false;
    }

    try {
      _isInitializing = true;
      _onInitializingChanged?.call(true);

      AppLogger.info('Inicializando YoloDetector (lazy loading)...', tag: _tag);

      _detector = YoloDetector();
      await _detector!.initialize();

      _frameProcessor = CameraFrameProcessor(_detector!);

      AppLogger.info('YoloDetector inicializado correctamente', tag: _tag);
      return true;
    } catch (e, stackTrace) {
      AppLogger.error('Error inicializando detector',
          tag: _tag, error: e, stackTrace: stackTrace);

      _detector?.dispose();
      _detector = null;
      _frameProcessor = null;

      _onError?.call('Error cargando modelo de IA: $e');
      return false;
    } finally {
      _isInitializing = false;
      _onInitializingChanged?.call(false);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CONTROL ON/OFF
  // ═══════════════════════════════════════════════════════════════════════════

  /// Activa la detección en tiempo real.
  ///
  /// Primera vez: Carga el modelo (3-5 segundos)
  /// Subsecuente: Instantáneo (modelo ya en memoria)
  Future<void> startDetection() async {
    if (_isDetectionActive) {
      AppLogger.debug('Detección ya está activa', tag: _tag);
      return;
    }

    // Asegurar que el detector esté inicializado
    final success = await _ensureDetectorInitialized();
    if (!success) {
      AppLogger.error('No se pudo inicializar detector', tag: _tag);
      return;
    }

    _isDetectionActive = true;
    _sessionStartTime = DateTime.now();
    _totalFramesProcessed = 0;
    _frameCounter = 0;

    AppLogger.info('Detección en tiempo real ACTIVADA', tag: _tag);
  }

  /// Desactiva la detección en tiempo real.
  ///
  /// NOTA: El detector permanece en memoria para rápida reactivación.
  /// Para liberar completamente la memoria, llamar a dispose().
  void stopDetection() {
    if (!_isDetectionActive) {
      AppLogger.debug('Detección ya está desactivada', tag: _tag);
      return;
    }

    _isDetectionActive = false;

    // Limpiar métricas de sesión
    _recentInferenceTimes.clear();
    _recentConfidences.clear();

    AppLogger.info('Detección en tiempo real DESACTIVADA (modelo en memoria)',
        tag: _tag);
  }

  /// Toggle de detección (conveniencia).
  Future<void> toggleDetection() async {
    if (_isDetectionActive) {
      stopDetection();
    } else {
      await startDetection();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PROCESAMIENTO DE FRAMES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Procesa un frame de la cámara si todas las condiciones se cumplen.
  ///
  /// Guards:
  /// - Detección debe estar activa
  /// - No estar procesando otro frame
  /// - Throttling: frame skip + tiempo mínimo
  ///
  /// Retorna `true` si el frame fue procesado.
  Future<bool> processFrame(
    CameraImage cameraImage, {
    required int sensorOrientation,
    required bool isFrontCamera,
    int frameSkip = 4,
    double confidenceThreshold = 0.50,
    double? iouThreshold,
  }) async {
    // GUARD 1: Detección activa
    if (!_isDetectionActive) {
      return false;
    }

    // GUARD 2: No inferencia concurrente
    if (_isInferring || (_frameProcessor?.isBusy ?? false)) {
      return false;
    }

    // GUARD 3: Frame skipping
    _frameCounter++;
    if (_frameCounter < frameSkip) {
      return false;
    }
    _frameCounter = 0;

    // GUARD 4: Time-based throttling
    final now = DateTime.now();
    if (_lastInferenceTime != null) {
      final elapsed = now.difference(_lastInferenceTime!).inMilliseconds;
      if (elapsed < AppConstants.minInferenceIntervalMs) {
        return false;
      }
    }

    // ══════════════════════════════════════════════════════════
    // PROCESAR FRAME
    // ══════════════════════════════════════════════════════════

    _isInferring = true;
    final inferenceStart = DateTime.now();

    try {
      final result = await _frameProcessor!.processFrame(
        cameraImage,
        sensorOrientation: sensorOrientation,
        isFrontCamera: isFrontCamera,
        confidenceThreshold: confidenceThreshold,
        iouThreshold: iouThreshold,
      );

      if (result == null) {
        return false;
      }

      _lastInferenceTime = DateTime.now();
      final inferenceTimeMs =
          _lastInferenceTime!.difference(inferenceStart).inMilliseconds;

      // Actualizar métricas
      _updateMetrics(inferenceTimeMs, result.detections);
      _totalFramesProcessed++;

      // Callback a la UI
      final metrics = _calculateMetrics();
      _onDetectionsUpdated?.call(result.detections, metrics);

      return true;
    } catch (e, stackTrace) {
      AppLogger.error('Error procesando frame',
          tag: _tag, error: e, stackTrace: stackTrace);

      _onError?.call('Error en detección: $e');
      return false;
    } finally {
      _isInferring = false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTRICAS RUNTIME
  // ═══════════════════════════════════════════════════════════════════════════

  void _updateMetrics(int inferenceTimeMs, List<Detection> detections) {
    // Mantener solo los últimos 30 valores
    _recentInferenceTimes.add(inferenceTimeMs);
    if (_recentInferenceTimes.length > 30) {
      _recentInferenceTimes.removeAt(0);
    }

    // Confidence promedio de las detecciones
    if (detections.isNotEmpty) {
      final avgConfidence = detections
              .map((d) => d.confidence)
              .reduce((a, b) => a + b) /
          detections.length;

      _recentConfidences.add(avgConfidence);
      if (_recentConfidences.length > 30) {
        _recentConfidences.removeAt(0);
      }
    }
  }

  RuntimeMetrics _calculateMetrics() {
    if (_recentInferenceTimes.isEmpty) {
      return RuntimeMetrics.empty();
    }

    // FPS promedio (basado en últimas 30 inferencias)
    final avgInferenceMs =
        _recentInferenceTimes.reduce((a, b) => a + b) /
            _recentInferenceTimes.length;
    final avgFps = avgInferenceMs > 0 ? (1000 / avgInferenceMs).toDouble() : 0.0;

    // Latency (min, max, avg)
    final minLatencyMs =
        _recentInferenceTimes.reduce((a, b) => a < b ? a : b);
    final maxLatencyMs =
        _recentInferenceTimes.reduce((a, b) => a > b ? a : b);

    // Confidence promedio
    final avgConfidence = _recentConfidences.isNotEmpty
        ? _recentConfidences.reduce((a, b) => a + b) /
            _recentConfidences.length
        : 0.0;

    // Tiempo de sesión
    final sessionDurationSec = _sessionStartTime != null
        ? DateTime.now().difference(_sessionStartTime!).inSeconds
        : 0;

    return RuntimeMetrics(
      avgFps: avgFps,
      avgLatencyMs: avgInferenceMs.round(),
      minLatencyMs: minLatencyMs,
      maxLatencyMs: maxLatencyMs,
      avgConfidence: avgConfidence,
      totalFramesProcessed: _totalFramesProcessed,
      sessionDurationSec: sessionDurationSec,
    );
  }

  /// Resetea las métricas de la sesión actual.
  void resetMetrics() {
    _recentInferenceTimes.clear();
    _recentConfidences.clear();
    _totalFramesProcessed = 0;
    _sessionStartTime = DateTime.now();
    _frameCounter = 0;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CLEANUP
  // ═══════════════════════════════════════════════════════════════════════════

  /// Libera TODOS los recursos (detector + frame processor).
  ///
  /// Llamar solo al salir de la pantalla.
  /// Para pausar temporalmente, usar stopDetection().
  void dispose() {
    stopDetection();

    _detector?.dispose();
    _detector = null;
    _frameProcessor = null;

    _onDetectionsUpdated = null;
    _onError = null;
    _onInitializingChanged = null;

    AppLogger.debug('DetectionController disposed', tag: _tag);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MODELO: RuntimeMetrics
// ═══════════════════════════════════════════════════════════════════════════════

/// Métricas de rendimiento runtime de la detección.
@immutable
class RuntimeMetrics {
  final double avgFps;
  final int avgLatencyMs;
  final int minLatencyMs;
  final int maxLatencyMs;
  final double avgConfidence;
  final int totalFramesProcessed;
  final int sessionDurationSec;

  const RuntimeMetrics({
    required this.avgFps,
    required this.avgLatencyMs,
    required this.minLatencyMs,
    required this.maxLatencyMs,
    required this.avgConfidence,
    required this.totalFramesProcessed,
    required this.sessionDurationSec,
  });

  factory RuntimeMetrics.empty() => const RuntimeMetrics(
        avgFps: 0,
        avgLatencyMs: 0,
        minLatencyMs: 0,
        maxLatencyMs: 0,
        avgConfidence: 0,
        totalFramesProcessed: 0,
        sessionDurationSec: 0,
      );

  @override
  String toString() {
    return 'RuntimeMetrics('
        'fps: ${avgFps.toStringAsFixed(1)}, '
        'latency: ${avgLatencyMs}ms [$minLatencyMs-$maxLatencyMs], '
        'confidence: ${(avgConfidence * 100).toStringAsFixed(1)}%, '
        'frames: $totalFramesProcessed, '
        'duration: ${sessionDurationSec}s'
        ')';
  }
}

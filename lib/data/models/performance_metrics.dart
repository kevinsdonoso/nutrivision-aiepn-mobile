// ═══════════════════════════════════════════════════════════════════════════════
// ║                         performance_metrics.dart                            ║
// ║              Modelo para métricas de rendimiento de inferencia              ║
// ═══════════════════════════════════════════════════════════════════════════════
// ║  Registra tiempos detallados de cada etapa del pipeline de detección.      ║
// ║  Usado para profiling y optimización de rendimiento.                        ║
// ═══════════════════════════════════════════════════════════════════════════════

import 'package:flutter/foundation.dart';

/// Métricas de rendimiento de una inferencia.
///
/// Captura tiempos detallados por etapa:
/// - Conversión YUV→RGB
/// - Preprocesamiento (resize + letterbox + normalización)
/// - Inferencia TFLite (interpreter.run)
/// - Postprocesamiento (parsing + NMS)
@immutable
class PerformanceMetrics {
  /// Número de frame/inferencia.
  final int frameNumber;

  /// Tiempo total de procesamiento (ms).
  final int totalMs;

  /// Tiempo de conversión YUV→RGB (ms).
  final int conversionMs;

  /// Tiempo de preprocesamiento (ms).
  final int preprocessMs;

  /// Tiempo de inferencia TFLite (ms).
  final int inferenceMs;

  /// Tiempo de postprocesamiento + NMS (ms).
  final int postprocessMs;

  /// Número de detecciones encontradas.
  final int detectionCount;

  /// Timestamp de la medición.
  final DateTime timestamp;

  const PerformanceMetrics({
    required this.frameNumber,
    required this.totalMs,
    required this.conversionMs,
    required this.preprocessMs,
    required this.inferenceMs,
    required this.postprocessMs,
    required this.detectionCount,
    required this.timestamp,
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GETTERS CALCULADOS
  // ═══════════════════════════════════════════════════════════════════════════

  /// FPS calculado basado en tiempo total.
  double get fps => totalMs > 0 ? 1000 / totalMs : 0;

  /// Porcentaje del tiempo dedicado a conversión YUV→RGB.
  double get conversionPercent =>
      totalMs > 0 ? (conversionMs / totalMs) * 100 : 0;

  /// Porcentaje del tiempo dedicado a preprocesamiento.
  double get preprocessPercent =>
      totalMs > 0 ? (preprocessMs / totalMs) * 100 : 0;

  /// Porcentaje del tiempo dedicado a inferencia.
  double get inferencePercent =>
      totalMs > 0 ? (inferenceMs / totalMs) * 100 : 0;

  /// Porcentaje del tiempo dedicado a postprocesamiento.
  double get postprocessPercent =>
      totalMs > 0 ? (postprocessMs / totalMs) * 100 : 0;

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS DE AYUDA
  // ═══════════════════════════════════════════════════════════════════════════

  /// Crea métricas vacías/iniciales.
  factory PerformanceMetrics.empty() => PerformanceMetrics(
        frameNumber: 0,
        totalMs: 0,
        conversionMs: 0,
        preprocessMs: 0,
        inferenceMs: 0,
        postprocessMs: 0,
        detectionCount: 0,
        timestamp: DateTime.now(),
      );

  /// Crea una copia con valores modificados.
  PerformanceMetrics copyWith({
    int? frameNumber,
    int? totalMs,
    int? conversionMs,
    int? preprocessMs,
    int? inferenceMs,
    int? postprocessMs,
    int? detectionCount,
    DateTime? timestamp,
  }) {
    return PerformanceMetrics(
      frameNumber: frameNumber ?? this.frameNumber,
      totalMs: totalMs ?? this.totalMs,
      conversionMs: conversionMs ?? this.conversionMs,
      preprocessMs: preprocessMs ?? this.preprocessMs,
      inferenceMs: inferenceMs ?? this.inferenceMs,
      postprocessMs: postprocessMs ?? this.postprocessMs,
      detectionCount: detectionCount ?? this.detectionCount,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  /// Resumen de las métricas como lista de strings.
  List<String> toLogLines() {
    return [
      'Frame #$frameNumber - ${timestamp.toIso8601String()}',
      'Total: ${totalMs}ms (${fps.toStringAsFixed(1)} FPS)',
      'YUV→RGB: ${conversionMs}ms (${conversionPercent.toStringAsFixed(1)}%)',
      'Preprocess: ${preprocessMs}ms (${preprocessPercent.toStringAsFixed(1)}%)',
      'Inference: ${inferenceMs}ms (${inferencePercent.toStringAsFixed(1)}%)',
      'Postprocess: ${postprocessMs}ms (${postprocessPercent.toStringAsFixed(1)}%)',
      'Detections: $detectionCount',
    ];
  }

  @override
  String toString() {
    return 'PerformanceMetrics(frame: $frameNumber, total: ${totalMs}ms, '
        'fps: ${fps.toStringAsFixed(1)}, detections: $detectionCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PerformanceMetrics &&
        other.frameNumber == frameNumber &&
        other.totalMs == totalMs &&
        other.conversionMs == conversionMs &&
        other.preprocessMs == preprocessMs &&
        other.inferenceMs == inferenceMs &&
        other.postprocessMs == postprocessMs &&
        other.detectionCount == detectionCount;
  }

  @override
  int get hashCode => Object.hash(
        frameNumber,
        totalMs,
        conversionMs,
        preprocessMs,
        inferenceMs,
        postprocessMs,
        detectionCount,
      );
}

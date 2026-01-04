// =====================================================================================
// ||                           camera_settings.dart                                 ||
// ||              Modelo de configuracion de camara para deteccion                  ||
// =====================================================================================
// ||  Define los parametros ajustables para la deteccion en tiempo real.            ||
// ||  Permite optimizar rendimiento segun las capacidades del dispositivo.          ||
// =====================================================================================

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

/// Modelo inmutable para la configuracion de camara y deteccion.
///
/// Permite ajustar parametros de rendimiento en tiempo real:
/// - Frame skip: cuantos frames saltar entre inferencias
/// - Resolucion: calidad de la camara
/// - Umbral de confianza: filtrado de detecciones
/// - Opciones de visualizacion (FPS, memoria)
///
/// Ejemplo de uso:
/// ```dart
/// final settings = CameraSettings.defaults();
/// final updated = settings.copyWith(frameSkip: 2, showFps: true);
/// ```
@immutable
class CameraSettings {
  // ==================================================================================
  // PROPIEDADES DE RENDIMIENTO
  // ==================================================================================

  /// Numero de frames a saltar entre inferencias (1-5).
  ///
  /// - 1: Procesar cada frame (mayor precision, menor rendimiento)
  /// - 3: Balance recomendado
  /// - 5: Maximo rendimiento, menor precision
  final int frameSkip;

  /// Resolucion de la camara.
  ///
  /// Afecta tanto la calidad de imagen como el rendimiento.
  final CameraResolution resolution;

  /// Umbral minimo de confianza para mostrar detecciones (0.3 - 0.8).
  ///
  /// - 0.3: Muestra mas detecciones (posibles falsos positivos)
  /// - 0.5: Balance recomendado
  /// - 0.8: Solo detecciones muy seguras
  final double confidenceThreshold;

  /// Umbral IoU para Non-Maximum Suppression (0.20 - 0.50).
  ///
  /// - 0.20: Muy agresivo (elimina muchas detecciones superpuestas)
  /// - 0.30: Balance recomendado
  /// - 0.50: Menos agresivo (mantiene mas detecciones)
  final double iouThreshold;

  // ==================================================================================
  // OPCIONES DE VISUALIZACION
  // ==================================================================================

  /// Mostrar contador de FPS en pantalla.
  final bool showFps;

  /// Mostrar informacion de uso de memoria.
  final bool showMemoryInfo;

  // ==================================================================================
  // CONSTANTES DE VALIDACION
  // ==================================================================================

  /// Frame skip minimo permitido.
  static const int minFrameSkip = 1;

  /// Frame skip maximo permitido.
  static const int maxFrameSkip = 5;

  /// Umbral de confianza minimo.
  static const double minConfidence = 0.30;

  /// Umbral de confianza maximo.
  static const double maxConfidence = 0.80;

  /// Umbral IoU minimo.
  static const double minIouThreshold = 0.20;

  /// Umbral IoU maximo.
  static const double maxIouThreshold = 0.50;

  // ==================================================================================
  // VALORES POR DEFECTO
  // ==================================================================================

  /// Frame skip por defecto para tiempo real.
  /// frameSkip=4 → Procesar 1 de cada 4 frames (~7.5 FPS @ 30fps cámara)
  static const int defaultFrameSkip = 4;

  /// Resolucion por defecto para tiempo real.
  /// Medium resolution (720x480) ofrece mejor balance detección/rendimiento.
  /// LOW (352x288) es demasiado baja para detectar ingredientes correctamente.
  static const CameraResolution defaultResolution = CameraResolution.medium;

  /// Umbral de confianza por defecto.
  /// Igualado a 0.40 para paridad con detección FOTO/galería.
  static const double defaultConfidenceThreshold = 0.40;

  /// Umbral IoU por defecto.
  /// 0.30 ofrece buen balance entre eliminar duplicados y mantener detecciones.
  static const double defaultIouThreshold = 0.30;

  /// Mostrar FPS por defecto.
  static const bool defaultShowFps = false;

  /// Mostrar memoria por defecto.
  static const bool defaultShowMemoryInfo = false;

  // ==================================================================================
  // CONSTRUCTOR
  // ==================================================================================

  /// Crea una nueva configuracion de camara.
  ///
  /// Todos los parametros son validados automaticamente.
  const CameraSettings({
    this.frameSkip = defaultFrameSkip,
    this.resolution = defaultResolution,
    this.confidenceThreshold = defaultConfidenceThreshold,
    this.iouThreshold = defaultIouThreshold,
    this.showFps = defaultShowFps,
    this.showMemoryInfo = defaultShowMemoryInfo,
  })  : assert(
          frameSkip >= minFrameSkip && frameSkip <= maxFrameSkip,
          'frameSkip debe estar entre $minFrameSkip y $maxFrameSkip',
        ),
        assert(
          confidenceThreshold >= minConfidence &&
              confidenceThreshold <= maxConfidence,
          'confidenceThreshold debe estar entre $minConfidence y $maxConfidence',
        ),
        assert(
          iouThreshold >= minIouThreshold && iouThreshold <= maxIouThreshold,
          'iouThreshold debe estar entre $minIouThreshold y $maxIouThreshold',
        );

  // ==================================================================================
  // FACTORY CONSTRUCTORS
  // ==================================================================================

  /// Crea configuracion con valores por defecto.
  factory CameraSettings.defaults() => const CameraSettings();

  /// Crea configuracion optimizada para rendimiento.
  ///
  /// Ideal para dispositivos de gama baja.
  factory CameraSettings.performanceMode() => const CameraSettings(
        frameSkip: 5,
        resolution: CameraResolution.low,
        confidenceThreshold: 0.55,
        iouThreshold: 0.35,
        showFps: true,
        showMemoryInfo: false,
      );

  /// Crea configuracion optimizada para calidad.
  ///
  /// Ideal para dispositivos de gama alta.
  factory CameraSettings.qualityMode() => const CameraSettings(
        frameSkip: 1,
        resolution: CameraResolution.high,
        confidenceThreshold: 0.40,
        iouThreshold: 0.30,
        showFps: false,
        showMemoryInfo: false,
      );

  /// Crea CameraSettings desde un Map (SharedPreferences).
  factory CameraSettings.fromJson(Map<String, dynamic> json) {
    return CameraSettings(
      frameSkip: (json['frameSkip'] as int?) ?? defaultFrameSkip,
      resolution: CameraResolution.fromString(
        json['resolution'] as String? ?? defaultResolution.name,
      ),
      confidenceThreshold: (json['confidenceThreshold'] as num?)?.toDouble() ??
          defaultConfidenceThreshold,
      iouThreshold: (json['iouThreshold'] as num?)?.toDouble() ??
          defaultIouThreshold,
      showFps: json['showFps'] as bool? ?? defaultShowFps,
      showMemoryInfo: json['showMemoryInfo'] as bool? ?? defaultShowMemoryInfo,
    );
  }

  // ==================================================================================
  // METODOS
  // ==================================================================================

  /// Crea una copia con valores modificados.
  CameraSettings copyWith({
    int? frameSkip,
    CameraResolution? resolution,
    double? confidenceThreshold,
    double? iouThreshold,
    bool? showFps,
    bool? showMemoryInfo,
  }) {
    return CameraSettings(
      frameSkip: frameSkip ?? this.frameSkip,
      resolution: resolution ?? this.resolution,
      confidenceThreshold: confidenceThreshold ?? this.confidenceThreshold,
      iouThreshold: iouThreshold ?? this.iouThreshold,
      showFps: showFps ?? this.showFps,
      showMemoryInfo: showMemoryInfo ?? this.showMemoryInfo,
    );
  }

  /// Convierte a Map para persistencia.
  Map<String, dynamic> toJson() {
    return {
      'frameSkip': frameSkip,
      'resolution': resolution.name,
      'confidenceThreshold': confidenceThreshold,
      'iouThreshold': iouThreshold,
      'showFps': showFps,
      'showMemoryInfo': showMemoryInfo,
    };
  }

  /// Valida que los valores esten dentro de los rangos permitidos.
  ///
  /// Retorna una copia con valores corregidos si es necesario.
  CameraSettings validated() {
    return CameraSettings(
      frameSkip: frameSkip.clamp(minFrameSkip, maxFrameSkip),
      resolution: resolution,
      confidenceThreshold:
          confidenceThreshold.clamp(minConfidence, maxConfidence),
      iouThreshold: iouThreshold.clamp(minIouThreshold, maxIouThreshold),
      showFps: showFps,
      showMemoryInfo: showMemoryInfo,
    );
  }

  /// Verifica si la configuracion actual es la por defecto.
  bool get isDefault =>
      frameSkip == defaultFrameSkip &&
      resolution == defaultResolution &&
      confidenceThreshold == defaultConfidenceThreshold &&
      iouThreshold == defaultIouThreshold &&
      showFps == defaultShowFps &&
      showMemoryInfo == defaultShowMemoryInfo;

  @override
  String toString() {
    return 'CameraSettings('
        'frameSkip: $frameSkip, '
        'resolution: ${resolution.displayName}, '
        'confidence: ${(confidenceThreshold * 100).toInt()}%, '
        'iou: ${(iouThreshold * 100).toInt()}%, '
        'showFps: $showFps, '
        'showMemory: $showMemoryInfo'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CameraSettings &&
        other.frameSkip == frameSkip &&
        other.resolution == resolution &&
        other.confidenceThreshold == confidenceThreshold &&
        other.iouThreshold == iouThreshold &&
        other.showFps == showFps &&
        other.showMemoryInfo == showMemoryInfo;
  }

  @override
  int get hashCode => Object.hash(
        frameSkip,
        resolution,
        confidenceThreshold,
        iouThreshold,
        showFps,
        showMemoryInfo,
      );
}

// =====================================================================================
// ENUM: RESOLUCION DE CAMARA
// =====================================================================================

/// Opciones de resolucion de camara.
///
/// Mapea directamente a [ResolutionPreset] del paquete camera.
enum CameraResolution {
  /// Baja resolucion (352x288 píxeles).
  /// ⚠️ NO RECOMENDADO para detección - muy pocas detecciones.
  low,

  /// Resolucion media (720x480 píxeles).
  /// ✅ RECOMENDADO - Buen balance detección/rendimiento (~8-12 FPS).
  medium,

  /// Alta resolucion (1280x720 píxeles).
  /// ✅✅ Mejor detección - Requiere dispositivo potente (~5-8 FPS).
  high,

  /// Ultra resolucion (1920x1080+ píxeles, hasta 4K si el dispositivo lo soporta).
  /// ✅✅✅ Máxima detección - Solo dispositivos de gama alta (~3-5 FPS).
  /// NOTA: Aunque usa más píxeles, FOTO siempre detectará mejor por usar resolución completa.
  ultra;

  /// Nombre para mostrar en la UI.
  String get displayName {
    switch (this) {
      case CameraResolution.low:
        return 'Baja';
      case CameraResolution.medium:
        return 'Media';
      case CameraResolution.high:
        return 'Alta';
      case CameraResolution.ultra:
        return 'Ultra';
    }
  }

  /// Descripcion de la resolucion.
  String get description {
    switch (this) {
      case CameraResolution.low:
        return '⚠️ Poca detección';
      case CameraResolution.medium:
        return '✅ Recomendado';
      case CameraResolution.high:
        return '✅✅ Mejor detección';
      case CameraResolution.ultra:
        return '✅✅✅ Máxima detección (lento)';
    }
  }

  /// Convierte a ResolutionPreset del paquete camera.
  ResolutionPreset toResolutionPreset() {
    switch (this) {
      case CameraResolution.low:
        return ResolutionPreset.low;
      case CameraResolution.medium:
        return ResolutionPreset.medium;
      case CameraResolution.high:
        return ResolutionPreset.high;
      case CameraResolution.ultra:
        return ResolutionPreset.max;
    }
  }

  /// Crea CameraResolution desde un string.
  static CameraResolution fromString(String value) {
    switch (value.toLowerCase()) {
      case 'low':
        return CameraResolution.low;
      case 'high':
        return CameraResolution.high;
      case 'ultra':
        return CameraResolution.ultra;
      case 'medium':
      default:
        return CameraResolution.medium;
    }
  }

  /// Crea CameraResolution desde ResolutionPreset.
  static CameraResolution fromResolutionPreset(ResolutionPreset preset) {
    switch (preset) {
      case ResolutionPreset.low:
        return CameraResolution.low;
      case ResolutionPreset.high:
        return CameraResolution.high;
      case ResolutionPreset.veryHigh:
      case ResolutionPreset.ultraHigh:
      case ResolutionPreset.max:
        return CameraResolution.ultra;
      case ResolutionPreset.medium:
        return CameraResolution.medium;
    }
  }
}

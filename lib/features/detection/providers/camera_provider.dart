// ╔═══════════════════════════════════════════════════════════════════════════════╗
// ║                         camera_provider.dart                                  ║
// ║              Providers Riverpod para el estado de cámara                      ║
// ╠═══════════════════════════════════════════════════════════════════════════════╣
// ║  Gestiona el estado de la cámara, detecciones en tiempo real,                 ║
// ║  y permisos del dispositivo.                                                  ║
// ╚═══════════════════════════════════════════════════════════════════════════════╝

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../data/models/detection.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// ENUMS Y ESTADOS
// ═══════════════════════════════════════════════════════════════════════════════

/// Estados posibles de la cámara.
enum CameraStatus {
  /// Cámara no inicializada
  uninitialized,

  /// Inicializando cámara y modelo
  initializing,

  /// Lista para usar
  ready,

  /// Streaming activo (procesando frames)
  streaming,

  /// Error durante operación
  error,

  /// Permiso de cámara denegado
  permissionDenied,
}

/// Estado inmutable de la cámara y detecciones.
@immutable
class CameraState {
  /// Estado actual de la cámara
  final CameraStatus status;

  /// Detecciones actuales (del último frame procesado)
  final List<Detection> detections;

  /// Mensaje de error (si status == error)
  final String? errorMessage;

  /// Indica si se está procesando un frame
  final bool isProcessingFrame;

  /// Contador de frames procesados
  final int frameCount;

  /// Tiempo de la última inferencia en ms
  final int? lastInferenceTimeMs;

  /// Indica si el flash está activado
  final bool flashEnabled;

  /// Indica si se usa la cámara frontal
  final bool isFrontCamera;

  const CameraState({
    this.status = CameraStatus.uninitialized,
    this.detections = const [],
    this.errorMessage,
    this.isProcessingFrame = false,
    this.frameCount = 0,
    this.lastInferenceTimeMs,
    this.flashEnabled = false,
    this.isFrontCamera = false,
  });

  /// Estado inicial por defecto.
  factory CameraState.initial() => const CameraState();

  /// Crea una copia con valores modificados.
  CameraState copyWith({
    CameraStatus? status,
    List<Detection>? detections,
    String? errorMessage,
    bool? isProcessingFrame,
    int? frameCount,
    int? lastInferenceTimeMs,
    bool? flashEnabled,
    bool? isFrontCamera,
  }) {
    return CameraState(
      status: status ?? this.status,
      detections: detections ?? this.detections,
      errorMessage: errorMessage,
      isProcessingFrame: isProcessingFrame ?? this.isProcessingFrame,
      frameCount: frameCount ?? this.frameCount,
      lastInferenceTimeMs: lastInferenceTimeMs ?? this.lastInferenceTimeMs,
      flashEnabled: flashEnabled ?? this.flashEnabled,
      isFrontCamera: isFrontCamera ?? this.isFrontCamera,
    );
  }

  /// Verifica si la cámara está lista para streaming.
  bool get canStream =>
      status == CameraStatus.ready || status == CameraStatus.streaming;

  /// Calcula FPS aproximado basado en tiempo de inferencia.
  double get estimatedFps {
    if (lastInferenceTimeMs == null || lastInferenceTimeMs == 0) return 0;
    return 1000 / lastInferenceTimeMs!;
  }

  @override
  String toString() =>
      'CameraState(status: $status, detections: ${detections.length}, fps: ${estimatedFps.toStringAsFixed(1)})';
}

// ═══════════════════════════════════════════════════════════════════════════════
// NOTIFIER (GESTOR DE ESTADO)
// ═══════════════════════════════════════════════════════════════════════════════

/// Notifier que gestiona el estado de la cámara.
class CameraNotifier extends StateNotifier<CameraState> {
  CameraNotifier() : super(CameraState.initial());

  /// Establece el estado de la cámara.
  void setStatus(CameraStatus status) {
    state = state.copyWith(status: status);
  }

  /// Marca el inicio de la inicialización.
  void startInitializing() {
    state = state.copyWith(status: CameraStatus.initializing);
  }

  /// Marca la cámara como lista.
  void setReady() {
    state = state.copyWith(
      status: CameraStatus.ready,
      errorMessage: null,
    );
  }

  /// Inicia el streaming.
  void startStreaming() {
    state = state.copyWith(status: CameraStatus.streaming);
  }

  /// Detiene el streaming.
  void stopStreaming() {
    if (state.status == CameraStatus.streaming) {
      state = state.copyWith(status: CameraStatus.ready);
    }
  }

  /// Actualiza las detecciones con resultados de inferencia.
  void updateDetections(List<Detection> detections, int inferenceTimeMs) {
    state = state.copyWith(
      detections: detections,
      lastInferenceTimeMs: inferenceTimeMs,
      frameCount: state.frameCount + 1,
      isProcessingFrame: false,
    );
  }

  /// Limpia las detecciones actuales.
  void clearDetections() {
    state = state.copyWith(detections: []);
  }

  /// Marca que se está procesando un frame.
  void setProcessing(bool processing) {
    state = state.copyWith(isProcessingFrame: processing);
  }

  /// Establece un error.
  void setError(String message) {
    state = state.copyWith(
      status: CameraStatus.error,
      errorMessage: message,
      isProcessingFrame: false,
    );
  }

  /// Marca permiso denegado.
  void setPermissionDenied() {
    state = state.copyWith(status: CameraStatus.permissionDenied);
  }

  /// Alterna el estado del flash.
  void toggleFlash() {
    state = state.copyWith(flashEnabled: !state.flashEnabled);
  }

  /// Cambia entre cámara frontal y trasera.
  void toggleCamera() {
    state = state.copyWith(isFrontCamera: !state.isFrontCamera);
  }

  /// Resetea el estado a inicial.
  void reset() {
    state = CameraState.initial();
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════════

/// Provider principal del estado de cámara.
final cameraStateProvider =
    StateNotifierProvider.autoDispose<CameraNotifier, CameraState>((ref) {
  return CameraNotifier();
});

/// Provider para el estado de la cámara (solo lectura).
final cameraStatusProvider = Provider.autoDispose<CameraStatus>((ref) {
  return ref.watch(cameraStateProvider).status;
});

/// Provider para las detecciones actuales.
final currentDetectionsProvider = Provider.autoDispose<List<Detection>>((ref) {
  return ref.watch(cameraStateProvider).detections;
});

/// Provider para el conteo de detecciones.
final detectionCountProvider = Provider.autoDispose<int>((ref) {
  return ref.watch(currentDetectionsProvider).length;
});

/// Provider para verificar si se está procesando.
final isProcessingProvider = Provider.autoDispose<bool>((ref) {
  return ref.watch(cameraStateProvider).isProcessingFrame;
});

/// Provider para el FPS estimado.
final estimatedFpsProvider = Provider.autoDispose<double>((ref) {
  return ref.watch(cameraStateProvider).estimatedFps;
});

/// Provider para verificar permiso de cámara.
final cameraPermissionProvider = FutureProvider.autoDispose<bool>((ref) async {
  final status = await Permission.camera.status;

  if (status.isGranted) {
    return true;
  }

  if (status.isDenied) {
    final result = await Permission.camera.request();
    return result.isGranted;
  }

  return false;
});

/// Provider que indica si el permiso fue denegado permanentemente.
final isPermissionPermanentlyDeniedProvider =
    FutureProvider.autoDispose<bool>((ref) async {
  final status = await Permission.camera.status;
  return status.isPermanentlyDenied;
});

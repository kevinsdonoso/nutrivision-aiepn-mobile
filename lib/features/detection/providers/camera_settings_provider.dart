// =====================================================================================
// ||                     camera_settings_provider.dart                              ||
// ||              Providers Riverpod para configuracion de camara                   ||
// =====================================================================================
// ||  Gestiona el estado de la configuracion de camara con persistencia.            ||
// ||  Proporciona providers granulares para evitar rebuilds innecesarios.           ||
// =====================================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/camera_settings.dart';
import '../../../data/repositories/settings_repository.dart';

// =====================================================================================
// REPOSITORY PROVIDER
// =====================================================================================

/// Provider para el repositorio de configuracion.
///
/// Se inicializa automaticamente al primer uso.
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final repository = SettingsRepository();
  ref.onDispose(repository.dispose);
  return repository;
});

// =====================================================================================
// SETTINGS NOTIFIER
// =====================================================================================

/// Notifier para gestionar la configuracion de camara.
///
/// Proporciona metodos para:
/// - Cargar configuracion guardada
/// - Actualizar configuracion
/// - Restaurar valores por defecto
/// - Actualizar campos individuales
class CameraSettingsNotifier extends AsyncNotifier<CameraSettings> {
  @override
  Future<CameraSettings> build() async {
    final repository = ref.read(settingsRepositoryProvider);
    await repository.initialize();
    return repository.loadCameraSettings();
  }

  /// Actualiza la configuracion completa.
  Future<void> updateSettings(CameraSettings settings) async {
    final repository = ref.read(settingsRepositoryProvider);
    final success = await repository.saveCameraSettings(settings);

    if (success) {
      state = AsyncValue.data(settings);
    }
  }

  /// Restaura la configuracion a valores por defecto.
  Future<CameraSettings> resetToDefaults() async {
    final repository = ref.read(settingsRepositoryProvider);
    final defaults = await repository.resetToDefaults();
    state = AsyncValue.data(defaults);
    return defaults;
  }

  /// Actualiza el frame skip.
  Future<void> updateFrameSkip(int frameSkip) async {
    final current = state.valueOrNull ?? CameraSettings.defaults();
    await updateSettings(current.copyWith(frameSkip: frameSkip));
  }

  /// Actualiza la resolucion de camara.
  Future<void> updateResolution(CameraResolution resolution) async {
    final current = state.valueOrNull ?? CameraSettings.defaults();
    await updateSettings(current.copyWith(resolution: resolution));
  }

  /// Actualiza el umbral de confianza.
  Future<void> updateConfidenceThreshold(double threshold) async {
    final current = state.valueOrNull ?? CameraSettings.defaults();
    await updateSettings(current.copyWith(confidenceThreshold: threshold));
  }

  /// Activa o desactiva el indicador de FPS.
  Future<void> toggleShowFps(bool show) async {
    final current = state.valueOrNull ?? CameraSettings.defaults();
    await updateSettings(current.copyWith(showFps: show));
  }

  /// Activa o desactiva el indicador de memoria.
  Future<void> toggleShowMemoryInfo(bool show) async {
    final current = state.valueOrNull ?? CameraSettings.defaults();
    await updateSettings(current.copyWith(showMemoryInfo: show));
  }
}

// =====================================================================================
// MAIN PROVIDER
// =====================================================================================

/// Provider principal para la configuracion de camara.
///
/// Uso:
/// ```dart
/// final settingsAsync = ref.watch(cameraSettingsProvider);
///
/// settingsAsync.when(
///   loading: () => CircularProgressIndicator(),
///   error: (e, _) => Text('Error: $e'),
///   data: (settings) => Text('Frame skip: ${settings.frameSkip}'),
/// );
/// ```
final cameraSettingsProvider =
    AsyncNotifierProvider<CameraSettingsNotifier, CameraSettings>(
  CameraSettingsNotifier.new,
);

// =====================================================================================
// PROVIDERS GRANULARES
// =====================================================================================

/// Provider para el frame skip actual.
///
/// Util cuando solo se necesita este valor para evitar rebuilds.
final frameSkipProvider = Provider<int>((ref) {
  final settings = ref.watch(cameraSettingsProvider);
  return settings.valueOrNull?.frameSkip ?? CameraSettings.defaultFrameSkip;
});

/// Provider para la resolucion de camara actual.
final cameraResolutionProvider = Provider<CameraResolution>((ref) {
  final settings = ref.watch(cameraSettingsProvider);
  return settings.valueOrNull?.resolution ?? CameraSettings.defaultResolution;
});

/// Provider para el umbral de confianza actual.
final confidenceThresholdProvider = Provider<double>((ref) {
  final settings = ref.watch(cameraSettingsProvider);
  return settings.valueOrNull?.confidenceThreshold ??
      CameraSettings.defaultConfidenceThreshold;
});

/// Provider para el estado de mostrar FPS.
final showFpsProvider = Provider<bool>((ref) {
  final settings = ref.watch(cameraSettingsProvider);
  return settings.valueOrNull?.showFps ?? CameraSettings.defaultShowFps;
});

/// Provider para el estado de mostrar memoria.
final showMemoryInfoProvider = Provider<bool>((ref) {
  final settings = ref.watch(cameraSettingsProvider);
  return settings.valueOrNull?.showMemoryInfo ??
      CameraSettings.defaultShowMemoryInfo;
});

/// Provider que indica si la configuracion esta cargada.
final isSettingsLoadedProvider = Provider<bool>((ref) {
  final settings = ref.watch(cameraSettingsProvider);
  return settings.hasValue;
});

/// Provider que indica si la configuracion tiene valores por defecto.
final isDefaultSettingsProvider = Provider<bool>((ref) {
  final settings = ref.watch(cameraSettingsProvider);
  return settings.valueOrNull?.isDefault ?? true;
});

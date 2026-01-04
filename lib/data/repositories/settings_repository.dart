// =====================================================================================
// ||                         settings_repository.dart                               ||
// ||              Repositorio para persistencia de configuracion                    ||
// =====================================================================================
// ||  Gestiona el almacenamiento de configuracion de camara usando SharedPreferences.||
// ||  Proporciona metodos para guardar, cargar y restaurar valores por defecto.     ||
// =====================================================================================

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/logging/app_logger.dart';
import '../models/camera_settings.dart';

/// Repositorio para persistencia de configuracion de camara.
///
/// Utiliza SharedPreferences para almacenar la configuracion
/// de manera persistente entre sesiones de la aplicacion.
///
/// Ejemplo de uso:
/// ```dart
/// final repo = SettingsRepository();
/// await repo.initialize();
///
/// // Cargar configuracion
/// final settings = await repo.loadCameraSettings();
///
/// // Guardar configuracion
/// await repo.saveCameraSettings(settings.copyWith(frameSkip: 2));
///
/// // Restaurar valores por defecto
/// await repo.resetToDefaults();
/// ```
class SettingsRepository {
  // ==================================================================================
  // CONSTANTES
  // ==================================================================================

  /// Tag para logging.
  static const String _tag = 'SettingsRepo';

  /// Clave para almacenar configuracion de camara.
  static const String _cameraSettingsKey = 'camera_settings';

  // ==================================================================================
  // PROPIEDADES
  // ==================================================================================

  /// Instancia de SharedPreferences.
  SharedPreferences? _prefs;

  /// Indica si el repositorio esta inicializado.
  bool _initialized = false;

  // ==================================================================================
  // INICIALIZACION
  // ==================================================================================

  /// Indica si el repositorio esta inicializado.
  bool get isInitialized => _initialized;

  /// Inicializa el repositorio.
  ///
  /// Debe llamarse antes de usar cualquier otro metodo.
  /// Es seguro llamar multiples veces (no-op si ya esta inicializado).
  Future<void> initialize() async {
    if (_initialized) return;

    AppLogger.debug('Inicializando SettingsRepository...', tag: _tag);

    try {
      _prefs = await SharedPreferences.getInstance();
      _initialized = true;
      AppLogger.info('SettingsRepository inicializado correctamente',
          tag: _tag);
    } catch (e) {
      AppLogger.error(
        'Error inicializando SettingsRepository: $e',
        tag: _tag,
      );
      rethrow;
    }
  }

  /// Asegura que el repositorio este inicializado.
  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await initialize();
    }
  }

  // ==================================================================================
  // CONFIGURACION DE CAMARA
  // ==================================================================================

  /// Carga la configuracion de camara desde SharedPreferences.
  ///
  /// Si no existe configuracion guardada, retorna valores por defecto.
  /// Si hay un error de parseo, retorna valores por defecto y loguea el error.
  Future<CameraSettings> loadCameraSettings() async {
    await _ensureInitialized();

    try {
      final jsonString = _prefs?.getString(_cameraSettingsKey);

      if (jsonString == null || jsonString.isEmpty) {
        AppLogger.debug(
          'No hay configuracion guardada, usando valores por defecto',
          tag: _tag,
        );
        return CameraSettings.defaults();
      }

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final settings = CameraSettings.fromJson(json).validated();

      AppLogger.debug(
        'Configuracion cargada: $settings',
        tag: _tag,
      );

      return settings;
    } catch (e) {
      AppLogger.error(
        'Error cargando configuracion, usando valores por defecto: $e',
        tag: _tag,
      );
      return CameraSettings.defaults();
    }
  }

  /// Guarda la configuracion de camara en SharedPreferences.
  ///
  /// Retorna true si se guardo correctamente, false en caso de error.
  Future<bool> saveCameraSettings(CameraSettings settings) async {
    await _ensureInitialized();

    try {
      final validatedSettings = settings.validated();
      final jsonString = jsonEncode(validatedSettings.toJson());

      final success = await _prefs?.setString(_cameraSettingsKey, jsonString);

      if (success == true) {
        AppLogger.debug(
          'Configuracion guardada: $validatedSettings',
          tag: _tag,
        );
        return true;
      } else {
        AppLogger.warning(
          'No se pudo guardar la configuracion',
          tag: _tag,
        );
        return false;
      }
    } catch (e) {
      AppLogger.error(
        'Error guardando configuracion: $e',
        tag: _tag,
      );
      return false;
    }
  }

  /// Restaura la configuracion de camara a valores por defecto.
  ///
  /// Elimina la configuracion guardada y retorna los valores por defecto.
  Future<CameraSettings> resetToDefaults() async {
    await _ensureInitialized();

    try {
      await _prefs?.remove(_cameraSettingsKey);

      AppLogger.info(
        'Configuracion restaurada a valores por defecto',
        tag: _tag,
      );

      return CameraSettings.defaults();
    } catch (e) {
      AppLogger.error(
        'Error restaurando configuracion por defecto: $e',
        tag: _tag,
      );
      return CameraSettings.defaults();
    }
  }

  /// Verifica si existe configuracion guardada.
  Future<bool> hasSavedSettings() async {
    await _ensureInitialized();

    final jsonString = _prefs?.getString(_cameraSettingsKey);
    return jsonString != null && jsonString.isNotEmpty;
  }

  // ==================================================================================
  // METODOS DE CONVENIENCIA
  // ==================================================================================

  /// Actualiza un solo campo de la configuracion.
  ///
  /// Carga la configuracion actual, aplica el cambio y guarda.
  Future<CameraSettings> updateFrameSkip(int frameSkip) async {
    final current = await loadCameraSettings();
    final updated = current.copyWith(frameSkip: frameSkip);
    await saveCameraSettings(updated);
    return updated;
  }

  /// Actualiza la resolucion de camara.
  Future<CameraSettings> updateResolution(CameraResolution resolution) async {
    final current = await loadCameraSettings();
    final updated = current.copyWith(resolution: resolution);
    await saveCameraSettings(updated);
    return updated;
  }

  /// Actualiza el umbral de confianza.
  Future<CameraSettings> updateConfidenceThreshold(double threshold) async {
    final current = await loadCameraSettings();
    final updated = current.copyWith(confidenceThreshold: threshold);
    await saveCameraSettings(updated);
    return updated;
  }

  /// Activa o desactiva el indicador de FPS.
  Future<CameraSettings> toggleShowFps(bool show) async {
    final current = await loadCameraSettings();
    final updated = current.copyWith(showFps: show);
    await saveCameraSettings(updated);
    return updated;
  }

  /// Activa o desactiva el indicador de memoria.
  Future<CameraSettings> toggleShowMemoryInfo(bool show) async {
    final current = await loadCameraSettings();
    final updated = current.copyWith(showMemoryInfo: show);
    await saveCameraSettings(updated);
    return updated;
  }

  // ==================================================================================
  // UTILIDADES
  // ==================================================================================

  /// Libera recursos del repositorio.
  void dispose() {
    _prefs = null;
    _initialized = false;
    AppLogger.debug('SettingsRepository disposed', tag: _tag);
  }
}

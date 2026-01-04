// ╔═══════════════════════════════════════════════════════════════════════════════╗
// ║                       detection_debug_helper.dart                             ║
// ║              Helper para debug de imágenes FOTO vs LIVE                       ║
// ╠═══════════════════════════════════════════════════════════════════════════════╣
// ║  Guarda imágenes debug para investigar diferencias en detección.              ║
// ║  ACTIVAR SOLO durante debugging - desactivar en producción.                   ║
// ╚═══════════════════════════════════════════════════════════════════════════════╝

import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

import '../../../core/logging/app_logger.dart';

/// Helper para guardar imágenes debug durante investigación de diferencias
/// entre detección FOTO y LIVE.
///
/// **USO:**
/// - Solo activar durante debugging con flag `_saveDebugImages`
/// - Las imágenes se guardan en: `[AppDocuments]/nutrivision_debug/`
/// - Guardar imágenes en puntos clave del pipeline:
///   1. Después de decodificación (RGB crudo)
///   2. Después de preprocesado (input al modelo 640x640)
///
/// **IMPORTANTE:** Desactivar en producción para evitar llenar almacenamiento.
class DetectionDebugHelper {
  static const String _tag = 'DebugHelper';

  /// Flag de control - cambiar a `true` para activar guardado
  /// IMPORTANTE: Debe ser `false` en producción
  static const bool _saveDebugImages = false;

  /// Número máximo de imágenes a guardar por tipo
  /// (para evitar llenar almacenamiento)
  static const int _maxImagesPerType = 5;

  /// Contadores de imágenes guardadas
  static int _photoRgbCount = 0;
  static int _photoModelInputCount = 0;
  static int _liveRgbCount = 0;
  static int _liveModelInputCount = 0;

  /// Guarda imagen RGB post-conversión (antes de preprocesado).
  ///
  /// [image] - Imagen RGB decodificada
  /// [source] - 'photo' o 'live'
  static Future<void> saveRgbConverted(
    img.Image image,
    String source,
  ) async {
    if (!_saveDebugImages || !kDebugMode) return;

    // Verificar límite
    if (source == 'photo' && _photoRgbCount >= _maxImagesPerType) return;
    if (source == 'live' && _liveRgbCount >= _maxImagesPerType) return;

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = '${source}_rgb_converted_$timestamp.png';

      final filePath = await _saveImage(image, filename);

      // Incrementar contador
      if (source == 'photo') {
        _photoRgbCount++;
      } else {
        _liveRgbCount++;
      }

      AppLogger.info(
        '💾 Debug image saved: $filePath\n'
        '   Size: ${image.width}x${image.height}\n'
        '   Count: ${source == 'photo' ? _photoRgbCount : _liveRgbCount}/$_maxImagesPerType',
        tag: _tag,
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error saving RGB converted image',
        tag: _tag,
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Guarda imagen preprocesada (input al modelo).
  ///
  /// [image] - Imagen después de letterbox/resize (640x640)
  /// [source] - 'photo' o 'live'
  static Future<void> saveModelInput(
    img.Image image,
    String source,
  ) async {
    if (!_saveDebugImages || !kDebugMode) return;

    // Verificar límite
    if (source == 'photo' && _photoModelInputCount >= _maxImagesPerType) {
      return;
    }
    if (source == 'live' && _liveModelInputCount >= _maxImagesPerType) {
      return;
    }

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = '${source}_model_input_$timestamp.png';

      final filePath = await _saveImage(image, filename);

      // Incrementar contador
      if (source == 'photo') {
        _photoModelInputCount++;
      } else {
        _liveModelInputCount++;
      }

      AppLogger.info(
        '💾 Debug image saved: $filePath\n'
        '   Size: ${image.width}x${image.height} (debe ser 640x640)\n'
        '   Count: ${source == 'photo' ? _photoModelInputCount : _liveModelInputCount}/$_maxImagesPerType',
        tag: _tag,
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error saving model input image',
        tag: _tag,
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Guarda imagen en disco.
  static Future<String> _saveImage(img.Image image, String filename) async {
    // Obtener directorio de documentos
    final directory = await getApplicationDocumentsDirectory();
    final debugDir = Directory('${directory.path}/nutrivision_debug');

    // Crear directorio si no existe
    if (!await debugDir.exists()) {
      await debugDir.create(recursive: true);
    }

    // Guardar imagen
    final file = File('${debugDir.path}/$filename');
    final pngBytes = img.encodePng(image);
    await file.writeAsBytes(pngBytes);

    return file.path;
  }

  /// Resetea contadores (útil al iniciar nueva sesión de debugging).
  static void resetCounters() {
    _photoRgbCount = 0;
    _photoModelInputCount = 0;
    _liveRgbCount = 0;
    _liveModelInputCount = 0;

    AppLogger.debug('Contadores de debug reseteados', tag: _tag);
  }

  /// Elimina todas las imágenes debug guardadas.
  static Future<void> clearDebugImages() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final debugDir = Directory('${directory.path}/nutrivision_debug');

      if (await debugDir.exists()) {
        await debugDir.delete(recursive: true);
        AppLogger.info('Imágenes debug eliminadas', tag: _tag);
      }

      resetCounters();
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error eliminando imágenes debug',
        tag: _tag,
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Obtiene estadísticas de debug.
  static Map<String, int> getStats() {
    return {
      'photo_rgb': _photoRgbCount,
      'photo_model_input': _photoModelInputCount,
      'live_rgb': _liveRgbCount,
      'live_model_input': _liveModelInputCount,
    };
  }

  /// Muestra ruta donde se guardan las imágenes debug.
  static Future<String> getDebugPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/nutrivision_debug';
  }
}

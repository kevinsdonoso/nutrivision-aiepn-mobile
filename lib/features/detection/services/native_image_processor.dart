// ╔═══════════════════════════════════════════════════════════════════════════════╗
// ║                        native_image_processor.dart                            ║
// ║              Cliente Dart para procesamiento nativo de imágenes               ║
// ╠═══════════════════════════════════════════════════════════════════════════════╣
// ║  Platform Channel para acceder a código C++ optimizado.                       ║
// ║  Provee conversión YUV→RGB ~10x más rápida que Dart puro.                     ║
// ╚═══════════════════════════════════════════════════════════════════════════════╝

import 'package:flutter/services.dart';

import '../../../core/logging/app_logger.dart';

/// Cliente para procesamiento de imágenes nativo.
///
/// Usa código C++ optimizado con NEON (ARM SIMD) para conversión
/// de color YUV420 a RGB significativamente más rápida.
class NativeImageProcessor {
  static const String _tag = 'NativeProcessor';

  /// Canal de comunicación con código nativo.
  static const _channel = MethodChannel('edu.epn.nutrivision/native_image_processor');

  /// Cache del soporte NEON.
  static bool? _neonSupported;

  /// Indica si el procesador nativo está disponible.
  static bool _available = true;

  /// Verifica si el procesador nativo está disponible.
  static bool get isAvailable => _available;

  /// Verifica si las optimizaciones NEON están soportadas.
  static Future<bool> isNeonSupported() async {
    if (_neonSupported != null) return _neonSupported!;

    try {
      _neonSupported = await _channel.invokeMethod<bool>('isNeonSupported') ?? false;
      return _neonSupported!;
    } catch (e) {
      AppLogger.warning('Error verificando NEON: $e', tag: _tag);
      _neonSupported = false;
      return false;
    }
  }

  /// Convierte una imagen YUV420 a RGB usando código nativo.
  ///
  /// Retorna `null` si el procesador nativo no está disponible
  /// o si ocurre un error. En ese caso, usar fallback Dart.
  ///
  /// [yBytes] - Bytes del plano Y (luminancia)
  /// [uBytes] - Bytes del plano U (crominancia)
  /// [vBytes] - Bytes del plano V (crominancia)
  /// [width] - Ancho de la imagen
  /// [height] - Alto de la imagen
  /// [yRowStride] - Stride del plano Y en bytes
  /// [uvRowStride] - Stride del plano UV en bytes
  /// [uvPixelStride] - Stride entre píxeles UV
  static Future<Uint8List?> convertYuvToRgb({
    required Uint8List yBytes,
    required Uint8List uBytes,
    required Uint8List vBytes,
    required int width,
    required int height,
    required int yRowStride,
    required int uvRowStride,
    required int uvPixelStride,
  }) async {
    if (!_available) return null;

    try {
      final result = await _channel.invokeMethod<Uint8List>('convertYuvToRgb', {
        'yBytes': yBytes,
        'uBytes': uBytes,
        'vBytes': vBytes,
        'width': width,
        'height': height,
        'yRowStride': yRowStride,
        'uvRowStride': uvRowStride,
        'uvPixelStride': uvPixelStride,
      });

      return result;
    } on PlatformException catch (e) {
      AppLogger.warning('Error en conversión nativa: ${e.message}', tag: _tag);
      return null;
    } on MissingPluginException {
      // El plugin nativo no está disponible (debug sin NDK?)
      _available = false;
      AppLogger.debug('Procesador nativo no disponible', tag: _tag);
      return null;
    } catch (e) {
      AppLogger.warning('Error inesperado: $e', tag: _tag);
      return null;
    }
  }
}

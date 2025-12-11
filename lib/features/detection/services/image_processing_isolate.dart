// ═══════════════════════════════════════════════════════════════════════════════════
// ║                         image_processing_isolate.dart                           ║
// ║              Worker isolate para conversión YUV→RGB en paralelo                 ║
// ╠═══════════════════════════════════════════════════════════════════════════════════╣
// ║  Mueve el procesamiento pesado de imágenes a un isolate separado.               ║
// ║  Libera el main thread para mantener la UI fluida.                              ║
// ╚═══════════════════════════════════════════════════════════════════════════════════╝

import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Datos de entrada para el isolate de conversión.
class YuvConversionInput {
  final int width;
  final int height;
  final Uint8List yBytes;
  final Uint8List uBytes;
  final Uint8List vBytes;
  final int yRowStride;
  final int uvRowStride;
  final int uvPixelStride;
  final int sensorOrientation;
  final bool flipHorizontal;

  const YuvConversionInput({
    required this.width,
    required this.height,
    required this.yBytes,
    required this.uBytes,
    required this.vBytes,
    required this.yRowStride,
    required this.uvRowStride,
    required this.uvPixelStride,
    required this.sensorOrientation,
    required this.flipHorizontal,
  });
}

/// Resultado de la conversión en isolate.
class YuvConversionResult {
  final Uint8List? rgbBytes;
  final int width;
  final int height;
  final String? error;

  const YuvConversionResult({
    this.rgbBytes,
    required this.width,
    required this.height,
    this.error,
  });

  bool get isSuccess => rgbBytes != null && error == null;
}

/// Función top-level para ejecutar en isolate con compute().
/// Convierte YUV420 a RGB, rota y opcionalmente espeja.
YuvConversionResult convertYuvToRgbIsolate(YuvConversionInput input) {
  try {
    final int width = input.width;
    final int height = input.height;

    // Crear imagen RGB
    final img.Image image = img.Image(width: width, height: height);

    final yBytes = input.yBytes;
    final uBytes = input.uBytes;
    final vBytes = input.vBytes;
    final yRowStride = input.yRowStride;
    final uvRowStride = input.uvRowStride;
    final uvPixelStride = input.uvPixelStride;

    // Conversión YUV420 a RGB con fórmula ITU-R BT.601
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int yIndex = y * yRowStride + x;
        final int uvIndex = (y ~/ 2) * uvRowStride + (x ~/ 2) * uvPixelStride;

        // Protección de bounds
        if (yIndex >= yBytes.length ||
            uvIndex >= uBytes.length ||
            uvIndex >= vBytes.length) {
          continue;
        }

        final int yValue = yBytes[yIndex];
        final int uValue = uBytes[uvIndex];
        final int vValue = vBytes[uvIndex];

        // Conversión YUV a RGB
        int r = (yValue + 1.402 * (vValue - 128)).round().clamp(0, 255);
        int g = (yValue - 0.344136 * (uValue - 128) - 0.714136 * (vValue - 128))
            .round()
            .clamp(0, 255);
        int b = (yValue + 1.772 * (uValue - 128)).round().clamp(0, 255);

        image.setPixelRgb(x, y, r, g, b);
      }
    }

    // Rotar según orientación del sensor
    img.Image rotatedImage;
    switch (input.sensorOrientation) {
      case 90:
        rotatedImage = img.copyRotate(image, angle: 90);
        break;
      case 180:
        rotatedImage = img.copyRotate(image, angle: 180);
        break;
      case 270:
        rotatedImage = img.copyRotate(image, angle: 270);
        break;
      case 0:
      default:
        rotatedImage = image;
    }

    // Espejo horizontal para cámara frontal
    final img.Image finalImage = input.flipHorizontal
        ? img.flipHorizontal(rotatedImage)
        : rotatedImage;

    // OPTIMIZACIÓN: Extraer bytes RGB crudos en lugar de PNG (~500ms ahorro)
    final rgbBytes = Uint8List(finalImage.width * finalImage.height * 3);
    int index = 0;
    for (int y = 0; y < finalImage.height; y++) {
      for (int x = 0; x < finalImage.width; x++) {
        final pixel = finalImage.getPixel(x, y);
        rgbBytes[index++] = pixel.r.toInt();
        rgbBytes[index++] = pixel.g.toInt();
        rgbBytes[index++] = pixel.b.toInt();
      }
    }

    return YuvConversionResult(
      rgbBytes: rgbBytes,
      width: finalImage.width,
      height: finalImage.height,
    );
  } catch (e) {
    return YuvConversionResult(
      width: input.width,
      height: input.height,
      error: e.toString(),
    );
  }
}

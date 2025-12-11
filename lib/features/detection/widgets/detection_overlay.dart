// ╔═══════════════════════════════════════════════════════════════════════════════╗
// ║                         detection_overlay.dart                                ║
// ║              Overlay de bounding boxes para detecciones en cámara             ║
// ╠═══════════════════════════════════════════════════════════════════════════════╣
// ║  CustomPainter que dibuja bounding boxes sobre el preview de cámara.          ║
// ║  Transforma coordenadas del modelo a coordenadas de pantalla.                 ║
// ╚═══════════════════════════════════════════════════════════════════════════════╝

import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/detection.dart';

/// Overlay que muestra bounding boxes sobre el preview de cámara.
class DetectionOverlay extends StatelessWidget {
  /// Lista de detecciones a mostrar.
  final List<Detection> detections;

  /// Tamaño del preview en pantalla.
  final Size previewSize;

  /// Ancho de la imagen procesada por el modelo.
  final int imageWidth;

  /// Alto de la imagen procesada por el modelo.
  final int imageHeight;

  /// Si es cámara frontal (para espejo horizontal).
  final bool isFrontCamera;

  const DetectionOverlay({
    super.key,
    required this.detections,
    required this.previewSize,
    required this.imageWidth,
    required this.imageHeight,
    this.isFrontCamera = false,
  });

  @override
  Widget build(BuildContext context) {
    // Limitar número de detecciones mostradas
    final displayDetections = detections.length > AppConstants.maxOverlayDetections
        ? detections.sublist(0, AppConstants.maxOverlayDetections)
        : detections;

    return CustomPaint(
      size: previewSize,
      painter: _DetectionOverlayPainter(
        detections: displayDetections,
        previewSize: previewSize,
        imageWidth: imageWidth,
        imageHeight: imageHeight,
        isFrontCamera: isFrontCamera,
      ),
    );
  }
}

/// CustomPainter para dibujar bounding boxes y etiquetas.
class _DetectionOverlayPainter extends CustomPainter {
  final List<Detection> detections;
  final Size previewSize;
  final int imageWidth;
  final int imageHeight;
  final bool isFrontCamera;

  // Paint reutilizable para mejor rendimiento
  final Paint _boxPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.5;

  final Paint _backgroundPaint = Paint()
    ..style = PaintingStyle.fill;

  // OPTIMIZACIÓN: Cache estático de TextPainters para evitar recreación
  static final Map<String, TextPainter> _labelCache = {};
  static const int _maxCacheSize = 50;

  _DetectionOverlayPainter({
    required this.detections,
    required this.previewSize,
    required this.imageWidth,
    required this.imageHeight,
    required this.isFrontCamera,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final detection in detections) {
      final rect = _transformBoundingBox(detection);
      final color = _getConfidenceColor(detection.confidence);

      _drawBoundingBox(canvas, rect, color);
      _drawLabel(canvas, detection, rect, color);
    }
  }

  /// Obtiene TextPainter del cache o crea uno nuevo.
  /// Gestiona el tamaño del cache para evitar memory leaks.
  TextPainter _getOrCreateTextPainter(String labelText) {
    // Buscar en cache
    if (_labelCache.containsKey(labelText)) {
      return _labelCache[labelText]!;
    }

    // Crear nuevo TextPainter
    final textPainter = TextPainter(
      text: TextSpan(
        text: labelText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    // Limpiar cache si excede límite (LRU simple: eliminar primeros)
    if (_labelCache.length >= _maxCacheSize) {
      final keysToRemove = _labelCache.keys.take(_maxCacheSize ~/ 4).toList();
      for (final key in keysToRemove) {
        _labelCache.remove(key);
      }
    }

    // Guardar en cache
    _labelCache[labelText] = textPainter;
    return textPainter;
  }

  /// Transforma coordenadas del modelo a coordenadas de pantalla.
  Rect _transformBoundingBox(Detection detection) {
    // Calcular factores de escala
    final scaleX = previewSize.width / imageWidth;
    final scaleY = previewSize.height / imageHeight;

    double x1 = detection.x1 * scaleX;
    double y1 = detection.y1 * scaleY;
    double x2 = detection.x2 * scaleX;
    double y2 = detection.y2 * scaleY;

    // Espejo horizontal para cámara frontal
    if (isFrontCamera) {
      final tempX1 = previewSize.width - x2;
      final tempX2 = previewSize.width - x1;
      x1 = tempX1;
      x2 = tempX2;
    }

    return Rect.fromLTRB(x1, y1, x2, y2);
  }

  /// Obtiene color basado en nivel de confianza.
  Color _getConfidenceColor(double confidence) {
    if (confidence >= AppConstants.highConfidenceThreshold) {
      return AppColors.confidenceHigh;
    } else if (confidence >= AppConstants.mediumConfidenceThreshold) {
      return AppColors.confidenceMedium;
    } else {
      return AppColors.confidenceLow;
    }
  }

  /// Dibuja el rectángulo del bounding box.
  void _drawBoundingBox(Canvas canvas, Rect rect, Color color) {
    _boxPaint.color = color;

    // Dibujar rectángulo con esquinas redondeadas
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(4));
    canvas.drawRRect(rrect, _boxPaint);

    // Dibujar esquinas destacadas
    _drawCorners(canvas, rect, color);
  }

  /// Dibuja esquinas destacadas en el bounding box.
  void _drawCorners(Canvas canvas, Rect rect, Color color) {
    final cornerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    const cornerLength = 15.0;

    // Esquina superior izquierda
    canvas.drawLine(
      Offset(rect.left, rect.top + cornerLength),
      Offset(rect.left, rect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(rect.left, rect.top),
      Offset(rect.left + cornerLength, rect.top),
      cornerPaint,
    );

    // Esquina superior derecha
    canvas.drawLine(
      Offset(rect.right - cornerLength, rect.top),
      Offset(rect.right, rect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(rect.right, rect.top),
      Offset(rect.right, rect.top + cornerLength),
      cornerPaint,
    );

    // Esquina inferior izquierda
    canvas.drawLine(
      Offset(rect.left, rect.bottom - cornerLength),
      Offset(rect.left, rect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(rect.left, rect.bottom),
      Offset(rect.left + cornerLength, rect.bottom),
      cornerPaint,
    );

    // Esquina inferior derecha
    canvas.drawLine(
      Offset(rect.right - cornerLength, rect.bottom),
      Offset(rect.right, rect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(rect.right, rect.bottom),
      Offset(rect.right, rect.bottom - cornerLength),
      cornerPaint,
    );
  }

  /// Dibuja la etiqueta con nombre y confianza.
  void _drawLabel(Canvas canvas, Detection detection, Rect rect, Color color) {
    final labelText = '${detection.label} ${detection.confidenceFormatted}';

    // OPTIMIZACIÓN: Usar TextPainter cacheado o crear nuevo
    final textPainter = _getOrCreateTextPainter(labelText);

    // Calcular posición del label (arriba del box)
    final labelWidth = textPainter.width + 12;
    final labelHeight = textPainter.height + 6;

    // Posición por defecto arriba del box
    double labelX = rect.left;
    double labelY = rect.top - labelHeight - 4;

    // Si no cabe arriba, ponerlo adentro del box
    if (labelY < 0) {
      labelY = rect.top + 4;
    }

    // Si se sale por la derecha, ajustar
    if (labelX + labelWidth > previewSize.width) {
      labelX = previewSize.width - labelWidth - 4;
    }

    // Fondo del label
    _backgroundPaint.color = color.withAlpha(220);
    final labelRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(labelX, labelY, labelWidth, labelHeight),
      const Radius.circular(4),
    );
    canvas.drawRRect(labelRect, _backgroundPaint);

    // Texto del label
    textPainter.paint(
      canvas,
      Offset(labelX + 6, labelY + 3),
    );
  }

  @override
  bool shouldRepaint(covariant _DetectionOverlayPainter oldDelegate) {
    // Repintar solo si las detecciones cambiaron
    if (oldDelegate.detections.length != detections.length) return true;

    for (int i = 0; i < detections.length; i++) {
      if (oldDelegate.detections[i] != detections[i]) return true;
    }

    return false;
  }
}

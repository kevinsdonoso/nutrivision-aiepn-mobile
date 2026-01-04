// ╔═══════════════════════════════════════════════════════════════════════════════╗
// ║                         detection.dart                                        ║
// ║                   Modelo de datos para detecciones                            ║
// ╠═══════════════════════════════════════════════════════════════════════════════╣
// ║  Representa una detección individual de ingrediente alimenticio.              ║
// ║  Contiene: bounding box, confianza, clase detectada y etiqueta.               ║
// ║  Incluye validaciones y factory methods para creación segura.                 ║
// ╚═══════════════════════════════════════════════════════════════════════════════╝

import '../../../core/exceptions/app_exceptions.dart';

/// Representa una detección de ingrediente en una imagen.
///
/// Cada detección contiene:
/// - Coordenadas del bounding box (x1, y1, x2, y2) en píxeles de la imagen original
/// - Nivel de confianza del modelo (0.0 - 1.0)
/// - ID de la clase detectada (0 - 82 para 83 clases)
/// - Etiqueta legible del ingrediente
///
/// Ejemplo de uso:
/// ```dart
/// final detection = Detection(
///   x1: 100, y1: 150, x2: 200, y2: 250,
///   confidence: 0.85,
///   classId: 5,
///   label: 'tomate',
/// );
/// print('${detection.label}: ${detection.confidencePercent}%');
/// ```
///
/// Throws [InvalidBoundingBoxException] si las coordenadas son inválidas.
/// Throws [InvalidConfidenceException] si la confianza está fuera de rango.
/// Throws [InvalidClassIdException] si el classId es negativo.
class Detection {
  // ═══════════════════════════════════════════════════════════════════════════
  // CONSTANTES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Número total de clases soportadas por el modelo
  static const int totalClasses = 83;

  /// Umbral de confianza para considerar detección de alta confianza
  static const double highConfidenceThreshold = 0.70;

  /// Umbral de confianza para considerar detección de confianza media
  static const double mediumConfidenceThreshold = 0.50;

  // ═══════════════════════════════════════════════════════════════════════════
  // PROPIEDADES DEL BOUNDING BOX
  // ═══════════════════════════════════════════════════════════════════════════

  /// Coordenada X de la esquina superior izquierda (en píxeles)
  final double x1;

  /// Coordenada Y de la esquina superior izquierda (en píxeles)
  final double y1;

  /// Coordenada X de la esquina inferior derecha (en píxeles)
  final double x2;

  /// Coordenada Y de la esquina inferior derecha (en píxeles)
  final double y2;

  // ═══════════════════════════════════════════════════════════════════════════
  // PROPIEDADES DE CLASIFICACIÓN
  // ═══════════════════════════════════════════════════════════════════════════

  /// Nivel de confianza del modelo para esta detección (0.0 - 1.0)
  ///
  /// Valores típicos:
  /// - > 0.7: Alta confianza
  /// - 0.5 - 0.7: Confianza media
  /// - < 0.5: Baja confianza (considerar filtrar)
  final double confidence;

  /// ID numérico de la clase detectada (índice en labels.txt)
  /// Rango: 0 - 82 (para 83 clases de ingredientes)
  final int classId;

  /// Nombre legible del ingrediente detectado
  /// Ejemplo: 'tomate', 'cebolla', 'arroz', etc.
  final String label;

  // ═══════════════════════════════════════════════════════════════════════════
  // CONSTRUCTOR
  // ═══════════════════════════════════════════════════════════════════════════

  /// Crea una nueva instancia de Detection con validación.
  ///
  /// Todos los parámetros son requeridos para garantizar datos completos.
  ///
  /// Throws [InvalidBoundingBoxException] si x2 <= x1 o y2 <= y1.
  /// Throws [InvalidConfidenceException] si confidence no está en [0.0, 1.0].
  /// Throws [InvalidClassIdException] si classId < 0.
  Detection({
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
    required this.confidence,
    required this.classId,
    required this.label,
  }) {
    _validate();
  }

  /// Constructor interno sin validación (para uso en factory methods controlados)
  const Detection._internal({
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
    required this.confidence,
    required this.classId,
    required this.label,
  });

  /// Valida los datos de la detección
  void _validate() {
    // Validar bounding box
    if (x2 <= x1) {
      throw InvalidBoundingBoxException(
        message: 'x2 ($x2) debe ser mayor que x1 ($x1)',
        x1: x1,
        y1: y1,
        x2: x2,
        y2: y2,
      );
    }

    if (y2 <= y1) {
      throw InvalidBoundingBoxException(
        message: 'y2 ($y2) debe ser mayor que y1 ($y1)',
        x1: x1,
        y1: y1,
        x2: x2,
        y2: y2,
      );
    }

    // Validar confianza
    if (confidence < 0.0 || confidence > 1.0) {
      throw InvalidConfidenceException(
        confidence: confidence,
        message: 'Confianza ($confidence) debe estar entre 0.0 y 1.0',
      );
    }

    // Validar classId
    if (classId < 0) {
      throw InvalidClassIdException(
        classId: classId,
        totalClasses: totalClasses,
        message: 'classId ($classId) no puede ser negativo',
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FACTORY CONSTRUCTORS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Crea una Detection desde datos crudos del modelo, con normalización.
  ///
  /// Útil para crear detecciones desde la salida del modelo YOLO.
  /// Aplica clamp a coordenadas negativas y confianza fuera de rango.
  ///
  /// [imageWidth] y [imageHeight] son las dimensiones de la imagen original
  /// para clampear las coordenadas dentro de los límites.
  factory Detection.fromModelOutput({
    required double x1,
    required double y1,
    required double x2,
    required double y2,
    required double confidence,
    required int classId,
    required String label,
    int? imageWidth,
    int? imageHeight,
  }) {
    // Normalizar coordenadas
    double clampedX1 = x1 < 0 ? 0 : x1;
    double clampedY1 = y1 < 0 ? 0 : y1;
    double clampedX2 = x2;
    double clampedY2 = y2;

    // Clampear a dimensiones de imagen si se proporcionan
    if (imageWidth != null) {
      clampedX1 = clampedX1.clamp(0, imageWidth.toDouble());
      clampedX2 = clampedX2.clamp(0, imageWidth.toDouble());
    }
    if (imageHeight != null) {
      clampedY1 = clampedY1.clamp(0, imageHeight.toDouble());
      clampedY2 = clampedY2.clamp(0, imageHeight.toDouble());
    }

    // Asegurar que x2 > x1 y y2 > y1 (swap si es necesario)
    if (clampedX2 <= clampedX1) {
      final temp = clampedX1;
      clampedX1 = clampedX2;
      clampedX2 = temp;
      // Si siguen iguales, añadir un mínimo
      if (clampedX2 <= clampedX1) {
        clampedX2 = clampedX1 + 1;
      }
    }
    if (clampedY2 <= clampedY1) {
      final temp = clampedY1;
      clampedY1 = clampedY2;
      clampedY2 = temp;
      if (clampedY2 <= clampedY1) {
        clampedY2 = clampedY1 + 1;
      }
    }

    // Normalizar confianza
    final clampedConfidence = confidence.clamp(0.0, 1.0);

    // Normalizar classId
    final clampedClassId = classId < 0 ? 0 : classId;

    return Detection._internal(
      x1: clampedX1,
      y1: clampedY1,
      x2: clampedX2,
      y2: clampedY2,
      confidence: clampedConfidence,
      classId: clampedClassId,
      label: label.isNotEmpty ? label : 'desconocido',
    );
  }

  /// Intenta crear una Detection, retornando null si los datos son inválidos.
  ///
  /// Útil cuando se procesan muchas detecciones y se quiere filtrar las inválidas
  /// sin lanzar excepciones.
  static Detection? tryCreate({
    required double x1,
    required double y1,
    required double x2,
    required double y2,
    required double confidence,
    required int classId,
    required String label,
  }) {
    try {
      return Detection(
        x1: x1,
        y1: y1,
        x2: x2,
        y2: y2,
        confidence: confidence,
        classId: classId,
        label: label,
      );
    } on NutriVisionException {
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PROPIEDADES CALCULADAS - DIMENSIONES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Ancho del bounding box en píxeles
  double get width => x2 - x1;

  /// Alto del bounding box en píxeles
  double get height => y2 - y1;

  /// Área del bounding box en píxeles cuadrados
  /// Útil para filtrar detecciones muy pequeñas o muy grandes
  double get area => width * height;

  /// Coordenada X del centro del bounding box
  double get centerX => (x1 + x2) / 2;

  /// Coordenada Y del centro del bounding box
  double get centerY => (y1 + y2) / 2;

  /// Relación de aspecto (ancho / alto)
  /// Útil para detectar cajas anormalmente estiradas
  double get aspectRatio => height > 0 ? width / height : 0;

  /// Indica si el bounding box es válido (tiene área positiva)
  bool get isValid => width > 0 && height > 0;

  // ═══════════════════════════════════════════════════════════════════════════
  // PROPIEDADES CALCULADAS - CONFIANZA
  // ═══════════════════════════════════════════════════════════════════════════

  /// Confianza expresada como porcentaje (0 - 100)
  double get confidencePercent => confidence * 100;

  /// Confianza formateada como string con 1 decimal
  /// Ejemplo: "85.3%"
  String get confidenceFormatted => '${confidencePercent.toStringAsFixed(1)}%';

  /// Indica si la detección tiene alta confianza (>= 70%)
  bool get isHighConfidence => confidence >= highConfidenceThreshold;

  /// Indica si la detección tiene confianza media (50% - 70%)
  bool get isMediumConfidence =>
      confidence >= mediumConfidenceThreshold &&
      confidence < highConfidenceThreshold;

  /// Indica si la detección tiene baja confianza (< 50%)
  bool get isLowConfidence => confidence < mediumConfidenceThreshold;

  /// Obtiene el nivel de confianza como enum
  ConfidenceLevel get confidenceLevel {
    if (isHighConfidence) return ConfidenceLevel.high;
    if (isMediumConfidence) return ConfidenceLevel.medium;
    return ConfidenceLevel.low;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS DE UTILIDAD
  // ═══════════════════════════════════════════════════════════════════════════

  /// Calcula el IoU (Intersection over Union) con otra detección.
  ///
  /// IoU es una métrica que mide cuánto se superponen dos bounding boxes.
  /// - IoU = 1.0: Las cajas son idénticas
  /// - IoU = 0.0: Las cajas no se superponen
  /// - IoU > 0.5: Se considera que detectan el mismo objeto (para NMS)
  ///
  /// [other] La otra detección para comparar
  /// Returns: Valor IoU entre 0.0 y 1.0
  double calculateIoU(Detection other) {
    // Calcular coordenadas de la intersección
    final intersectX1 = x1 > other.x1 ? x1 : other.x1;
    final intersectY1 = y1 > other.y1 ? y1 : other.y1;
    final intersectX2 = x2 < other.x2 ? x2 : other.x2;
    final intersectY2 = y2 < other.y2 ? y2 : other.y2;

    // Calcular área de intersección
    final intersectWidth =
        (intersectX2 - intersectX1) > 0 ? (intersectX2 - intersectX1) : 0.0;
    final intersectHeight =
        (intersectY2 - intersectY1) > 0 ? (intersectY2 - intersectY1) : 0.0;
    final intersectionArea = intersectWidth * intersectHeight;

    // Calcular área de unión
    final unionArea = area + other.area - intersectionArea;

    // Retornar IoU
    return unionArea > 0 ? intersectionArea / unionArea : 0;
  }

  /// Verifica si el centro de esta detección está dentro de otra.
  /// Útil para determinar si un ingrediente está "dentro" de otro.
  bool isCenterInsideOf(Detection other) {
    return centerX >= other.x1 &&
        centerX <= other.x2 &&
        centerY >= other.y1 &&
        centerY <= other.y2;
  }

  /// Verifica si esta detección se superpone con otra.
  bool overlaps(Detection other) {
    return calculateIoU(other) > 0;
  }

  /// Verifica si esta detección contiene completamente a otra.
  bool contains(Detection other) {
    return x1 <= other.x1 && y1 <= other.y1 && x2 >= other.x2 && y2 >= other.y2;
  }

  /// Crea una copia de esta detección con valores modificados.
  ///
  /// Throws [InvalidBoundingBoxException] si las nuevas coordenadas son inválidas.
  /// Throws [InvalidConfidenceException] si la nueva confianza está fuera de rango.
  Detection copyWith({
    double? x1,
    double? y1,
    double? x2,
    double? y2,
    double? confidence,
    int? classId,
    String? label,
  }) {
    return Detection(
      x1: x1 ?? this.x1,
      y1: y1 ?? this.y1,
      x2: x2 ?? this.x2,
      y2: y2 ?? this.y2,
      confidence: confidence ?? this.confidence,
      classId: classId ?? this.classId,
      label: label ?? this.label,
    );
  }

  /// Escala las coordenadas del bounding box por un factor.
  /// Útil cuando la imagen se redimensiona para visualización.
  ///
  /// Throws [ArgumentError] si los factores de escala son <= 0.
  Detection scale(double scaleX, double scaleY) {
    if (scaleX <= 0 || scaleY <= 0) {
      throw ArgumentError(
          'Los factores de escala deben ser positivos: scaleX=$scaleX, scaleY=$scaleY');
    }

    return Detection._internal(
      x1: x1 * scaleX,
      y1: y1 * scaleY,
      x2: x2 * scaleX,
      y2: y2 * scaleY,
      confidence: confidence,
      classId: classId,
      label: label,
    );
  }

  /// Traslada el bounding box por un offset.
  Detection translate(double offsetX, double offsetY) {
    return Detection._internal(
      x1: x1 + offsetX,
      y1: y1 + offsetY,
      x2: x2 + offsetX,
      y2: y2 + offsetY,
      confidence: confidence,
      classId: classId,
      label: label,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CONVERSIÓN Y DEBUG
  // ═══════════════════════════════════════════════════════════════════════════

  /// Convierte la detección a un Map para serialización JSON.
  Map<String, dynamic> toJson() {
    return {
      'x1': x1,
      'y1': y1,
      'x2': x2,
      'y2': y2,
      'width': width,
      'height': height,
      'confidence': confidence,
      'classId': classId,
      'label': label,
    };
  }

  /// Crea una Detection desde un Map (deserialización JSON).
  ///
  /// Throws [DetectionException] si el JSON es inválido o faltan campos.
  factory Detection.fromJson(Map<String, dynamic> json) {
    try {
      // Validar campos requeridos
      final requiredFields = [
        'x1',
        'y1',
        'x2',
        'y2',
        'confidence',
        'classId',
        'label'
      ];
      for (final field in requiredFields) {
        if (!json.containsKey(field)) {
          throw DetectionException(
            message: 'Campo requerido "$field" no encontrado en JSON',
            code: 'JSON_PARSE_ERROR',
          );
        }
      }

      return Detection(
        x1: (json['x1'] as num).toDouble(),
        y1: (json['y1'] as num).toDouble(),
        x2: (json['x2'] as num).toDouble(),
        y2: (json['y2'] as num).toDouble(),
        confidence: (json['confidence'] as num).toDouble(),
        classId: json['classId'] as int,
        label: json['label'] as String,
      );
    } on NutriVisionException {
      rethrow;
    } catch (e) {
      throw DetectionException(
        message: 'Error parseando Detection desde JSON: $e',
        code: 'JSON_PARSE_ERROR',
        originalError: e,
      );
    }
  }

  /// Intenta crear una Detection desde JSON, retornando null si es inválido.
  static Detection? tryFromJson(Map<String, dynamic> json) {
    try {
      return Detection.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  @override
  String toString() {
    return 'Detection($label: $confidenceFormatted @ [${x1.toInt()}, ${y1.toInt()}, ${x2.toInt()}, ${y2.toInt()}])';
  }

  /// Representación detallada para debugging
  String toDetailedString() {
    return '''Detection {
  label: $label,
  confidence: $confidenceFormatted ($confidenceLevel),
  classId: $classId,
  bbox: [x1: ${x1.toStringAsFixed(1)}, y1: ${y1.toStringAsFixed(1)}, x2: ${x2.toStringAsFixed(1)}, y2: ${y2.toStringAsFixed(1)}],
  size: ${width.toStringAsFixed(1)} x ${height.toStringAsFixed(1)} (area: ${area.toStringAsFixed(1)}),
  center: (${centerX.toStringAsFixed(1)}, ${centerY.toStringAsFixed(1)}),
  aspectRatio: ${aspectRatio.toStringAsFixed(2)}
}''';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Detection &&
        other.x1 == x1 &&
        other.y1 == y1 &&
        other.x2 == x2 &&
        other.y2 == y2 &&
        other.confidence == confidence &&
        other.classId == classId &&
        other.label == label;
  }

  @override
  int get hashCode {
    return Object.hash(x1, y1, x2, y2, confidence, classId, label);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ENUMS Y TIPOS AUXILIARES
// ═══════════════════════════════════════════════════════════════════════════════

/// Niveles de confianza para clasificar detecciones.
enum ConfidenceLevel {
  /// Alta confianza (>= 70%)
  high,

  /// Confianza media (50% - 70%)
  medium,

  /// Baja confianza (< 50%)
  low;

  /// Nombre legible del nivel
  String get displayName {
    switch (this) {
      case ConfidenceLevel.high:
        return 'Alta';
      case ConfidenceLevel.medium:
        return 'Media';
      case ConfidenceLevel.low:
        return 'Baja';
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// EXTENSIONES PARA LISTAS DE DETECCIONES
// ═══════════════════════════════════════════════════════════════════════════════

/// Extensiones útiles para trabajar con listas de detecciones.
extension DetectionListExtension on List<Detection> {
  /// Filtra detecciones por umbral de confianza mínimo.
  List<Detection> filterByConfidence(double minConfidence) {
    if (minConfidence < 0 || minConfidence > 1) {
      throw ArgumentError('minConfidence debe estar entre 0.0 y 1.0');
    }
    return where((d) => d.confidence >= minConfidence).toList();
  }

  /// Filtra detecciones de una clase específica.
  List<Detection> filterByClass(int classId) {
    return where((d) => d.classId == classId).toList();
  }

  /// Filtra detecciones por etiqueta (nombre del ingrediente).
  /// La comparación es case-insensitive.
  List<Detection> filterByLabel(String label) {
    final lowerLabel = label.toLowerCase();
    return where((d) => d.label.toLowerCase() == lowerLabel).toList();
  }

  /// Filtra detecciones por nivel de confianza.
  List<Detection> filterByConfidenceLevel(ConfidenceLevel level) {
    return where((d) => d.confidenceLevel == level).toList();
  }

  /// Filtra solo detecciones de alta confianza.
  List<Detection> get highConfidenceOnly =>
      where((d) => d.isHighConfidence).toList();

  /// Filtra detecciones con área mínima.
  List<Detection> filterByMinArea(double minArea) {
    return where((d) => d.area >= minArea).toList();
  }

  /// Ordena las detecciones por confianza (mayor a menor).
  List<Detection> sortedByConfidence({bool ascending = false}) {
    final sorted = [...this];
    sorted.sort((a, b) => ascending
        ? a.confidence.compareTo(b.confidence)
        : b.confidence.compareTo(a.confidence));
    return sorted;
  }

  /// Ordena las detecciones por área (mayor a menor).
  List<Detection> sortedByArea({bool ascending = false}) {
    final sorted = [...this];
    sorted.sort((a, b) =>
        ascending ? a.area.compareTo(b.area) : b.area.compareTo(a.area));
    return sorted;
  }

  /// Agrupa las detecciones por clase.
  Map<int, List<Detection>> groupByClass() {
    final Map<int, List<Detection>> grouped = {};
    for (final detection in this) {
      grouped.putIfAbsent(detection.classId, () => []).add(detection);
    }
    return grouped;
  }

  /// Agrupa las detecciones por etiqueta.
  Map<String, List<Detection>> groupByLabel() {
    final Map<String, List<Detection>> grouped = {};
    for (final detection in this) {
      grouped.putIfAbsent(detection.label, () => []).add(detection);
    }
    return grouped;
  }

  /// Agrupa las detecciones por nivel de confianza.
  Map<ConfidenceLevel, List<Detection>> groupByConfidenceLevel() {
    final Map<ConfidenceLevel, List<Detection>> grouped = {};
    for (final detection in this) {
      grouped.putIfAbsent(detection.confidenceLevel, () => []).add(detection);
    }
    return grouped;
  }

  /// Obtiene las etiquetas únicas detectadas.
  Set<String> get uniqueLabels => map((d) => d.label).toSet();

  /// Obtiene los IDs de clase únicos detectados.
  Set<int> get uniqueClassIds => map((d) => d.classId).toSet();

  /// Obtiene el conteo de cada ingrediente detectado.
  Map<String, int> get ingredientCounts {
    final Map<String, int> counts = {};
    for (final detection in this) {
      counts[detection.label] = (counts[detection.label] ?? 0) + 1;
    }
    return counts;
  }

  /// Obtiene la detección con mayor confianza.
  Detection? get mostConfident {
    if (isEmpty) return null;
    return reduce((a, b) => a.confidence > b.confidence ? a : b);
  }

  /// Obtiene la detección con mayor área.
  Detection? get largest {
    if (isEmpty) return null;
    return reduce((a, b) => a.area > b.area ? a : b);
  }

  /// Calcula el promedio de confianza de todas las detecciones.
  double get averageConfidence {
    if (isEmpty) return 0;
    return map((d) => d.confidence).reduce((a, b) => a + b) / length;
  }

  /// Obtiene estadísticas resumidas de las detecciones.
  DetectionStats get stats => DetectionStats.fromDetections(this);

  /// Convierte la lista a JSON.
  List<Map<String, dynamic>> toJson() {
    return map((d) => d.toJson()).toList();
  }

  /// Crea una lista de detecciones desde JSON.
  static List<Detection> fromJson(List<dynamic> jsonList) {
    return jsonList
        .map((json) => Detection.tryFromJson(json as Map<String, dynamic>))
        .whereType<Detection>()
        .toList();
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ESTADÍSTICAS DE DETECCIONES
// ═══════════════════════════════════════════════════════════════════════════════

/// Estadísticas resumidas de un conjunto de detecciones.
class DetectionStats {
  /// Número total de detecciones
  final int total;

  /// Número de detecciones de alta confianza
  final int highConfidence;

  /// Número de detecciones de confianza media
  final int mediumConfidence;

  /// Número de detecciones de baja confianza
  final int lowConfidence;

  /// Número de ingredientes únicos detectados
  final int uniqueIngredients;

  /// Confianza promedio
  final double averageConfidence;

  /// Confianza máxima
  final double maxConfidence;

  /// Confianza mínima
  final double minConfidence;

  /// Ingrediente más frecuente
  final String? mostFrequentIngredient;

  /// Conteo del ingrediente más frecuente
  final int mostFrequentCount;

  const DetectionStats({
    required this.total,
    required this.highConfidence,
    required this.mediumConfidence,
    required this.lowConfidence,
    required this.uniqueIngredients,
    required this.averageConfidence,
    required this.maxConfidence,
    required this.minConfidence,
    this.mostFrequentIngredient,
    required this.mostFrequentCount,
  });

  /// Crea estadísticas desde una lista de detecciones.
  factory DetectionStats.fromDetections(List<Detection> detections) {
    if (detections.isEmpty) {
      return const DetectionStats(
        total: 0,
        highConfidence: 0,
        mediumConfidence: 0,
        lowConfidence: 0,
        uniqueIngredients: 0,
        averageConfidence: 0,
        maxConfidence: 0,
        minConfidence: 0,
        mostFrequentIngredient: null,
        mostFrequentCount: 0,
      );
    }

    final counts = detections.ingredientCounts;
    String? mostFrequent;
    int mostFrequentCount = 0;
    counts.forEach((label, count) {
      if (count > mostFrequentCount) {
        mostFrequent = label;
        mostFrequentCount = count;
      }
    });

    return DetectionStats(
      total: detections.length,
      highConfidence: detections.where((d) => d.isHighConfidence).length,
      mediumConfidence: detections.where((d) => d.isMediumConfidence).length,
      lowConfidence: detections.where((d) => d.isLowConfidence).length,
      uniqueIngredients: detections.uniqueLabels.length,
      averageConfidence: detections.averageConfidence,
      maxConfidence:
          detections.map((d) => d.confidence).reduce((a, b) => a > b ? a : b),
      minConfidence:
          detections.map((d) => d.confidence).reduce((a, b) => a < b ? a : b),
      mostFrequentIngredient: mostFrequent,
      mostFrequentCount: mostFrequentCount,
    );
  }

  @override
  String toString() {
    return '''DetectionStats {
  total: $total,
  highConfidence: $highConfidence,
  mediumConfidence: $mediumConfidence,
  lowConfidence: $lowConfidence,
  uniqueIngredients: $uniqueIngredients,
  averageConfidence: ${(averageConfidence * 100).toStringAsFixed(1)}%,
  range: ${(minConfidence * 100).toStringAsFixed(1)}% - ${(maxConfidence * 100).toStringAsFixed(1)}%,
  mostFrequent: $mostFrequentIngredient ($mostFrequentCount)
}''';
  }
}

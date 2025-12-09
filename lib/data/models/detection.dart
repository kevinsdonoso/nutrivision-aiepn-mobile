// ╔═══════════════════════════════════════════════════════════════════════════════╗
// ║                         detection.dart                                        ║
// ║                   Modelo de datos para detecciones                            ║
// ╠═══════════════════════════════════════════════════════════════════════════════╣
// ║  Representa una detección individual de ingrediente alimenticio.              ║
// ║  Contiene: bounding box, confianza, clase detectada y etiqueta.               ║
// ╚═══════════════════════════════════════════════════════════════════════════════╝

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
class Detection {
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

  /// Crea una nueva instancia de Detection.
  ///
  /// Todos los parámetros son requeridos para garantizar datos completos.
  const Detection({
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
    required this.confidence,
    required this.classId,
    required this.label,
  });

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

  // ═══════════════════════════════════════════════════════════════════════════
  // PROPIEDADES CALCULADAS - CONFIANZA
  // ═══════════════════════════════════════════════════════════════════════════

  /// Confianza expresada como porcentaje (0 - 100)
  double get confidencePercent => confidence * 100;

  /// Confianza formateada como string con 1 decimal
  /// Ejemplo: "85.3%"
  String get confidenceFormatted => '${confidencePercent.toStringAsFixed(1)}%';

  /// Indica si la detección tiene alta confianza (>= 70%)
  bool get isHighConfidence => confidence >= 0.70;

  /// Indica si la detección tiene confianza media (50% - 70%)
  bool get isMediumConfidence => confidence >= 0.50 && confidence < 0.70;

  /// Indica si la detección tiene baja confianza (< 50%)
  bool get isLowConfidence => confidence < 0.50;

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
    final intersectWidth = (intersectX2 - intersectX1) > 0 ? (intersectX2 - intersectX1) : 0;
    final intersectHeight = (intersectY2 - intersectY1) > 0 ? (intersectY2 - intersectY1) : 0;
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

  /// Crea una copia de esta detección con valores modificados.
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
  Detection scale(double scaleX, double scaleY) {
    return Detection(
      x1: x1 * scaleX,
      y1: y1 * scaleY,
      x2: x2 * scaleX,
      y2: y2 * scaleY,
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
  factory Detection.fromJson(Map<String, dynamic> json) {
    return Detection(
      x1: (json['x1'] as num).toDouble(),
      y1: (json['y1'] as num).toDouble(),
      x2: (json['x2'] as num).toDouble(),
      y2: (json['y2'] as num).toDouble(),
      confidence: (json['confidence'] as num).toDouble(),
      classId: json['classId'] as int,
      label: json['label'] as String,
    );
  }

  @override
  String toString() {
    return 'Detection($label: $confidenceFormatted @ [${x1.toInt()}, ${y1.toInt()}, ${x2.toInt()}, ${y2.toInt()}])';
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
// EXTENSIONES PARA LISTAS DE DETECCIONES
// ═══════════════════════════════════════════════════════════════════════════════

/// Extensiones útiles para trabajar con listas de detecciones.
extension DetectionListExtension on List<Detection> {
  /// Filtra detecciones por umbral de confianza mínimo.
  List<Detection> filterByConfidence(double minConfidence) {
    return where((d) => d.confidence >= minConfidence).toList();
  }

  /// Filtra detecciones de una clase específica.
  List<Detection> filterByClass(int classId) {
    return where((d) => d.classId == classId).toList();
  }

  /// Filtra detecciones por etiqueta (nombre del ingrediente).
  List<Detection> filterByLabel(String label) {
    return where((d) => d.label.toLowerCase() == label.toLowerCase()).toList();
  }

  /// Ordena las detecciones por confianza (mayor a menor).
  List<Detection> sortedByConfidence() {
    return [...this]..sort((a, b) => b.confidence.compareTo(a.confidence));
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

  /// Obtiene las etiquetas únicas detectadas.
  Set<String> get uniqueLabels => map((d) => d.label).toSet();

  /// Obtiene el conteo de cada ingrediente detectado.
  Map<String, int> get ingredientCounts {
    final Map<String, int> counts = {};
    for (final detection in this) {
      counts[detection.label] = (counts[detection.label] ?? 0) + 1;
    }
    return counts;
  }
}

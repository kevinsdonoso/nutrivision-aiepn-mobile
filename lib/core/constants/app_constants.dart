// ╔═══════════════════════════════════════════════════════════════════════════════╗
// ║                         app_constants.dart                                    ║
// ║              Constantes globales de NutriVisionAIEPN                          ║
// ╠═══════════════════════════════════════════════════════════════════════════════╣
// ║  Centraliza valores constantes usados en toda la aplicación.                  ║
// ║  Incluye: configuración del modelo, rutas, dimensiones y textos.              ║
// ╚═══════════════════════════════════════════════════════════════════════════════╝

/// Constantes de la aplicación NutriVision.
abstract class AppConstants {
  // ═══════════════════════════════════════════════════════════════════════════
  // INFORMACIÓN DE LA APP
  // ═══════════════════════════════════════════════════════════════════════════

  /// Nombre de la aplicación
  static const String appName = 'NutriVision AI';

  /// Nombre completo
  static const String appFullName = 'NutriVisionAIEPN Mobile';

  /// Versión de la aplicación
  static const String appVersion = '1.0.0';

  /// Descripción corta
  static const String appDescription =
      'Detección inteligente de ingredientes alimenticios';

  // ═══════════════════════════════════════════════════════════════════════════
  // CONFIGURACIÓN DEL MODELO ML
  // ═══════════════════════════════════════════════════════════════════════════

  /// Tamaño de entrada del modelo (640x640)
  static const int modelInputSize = 640;

  /// Número de clases del modelo
  static const int modelNumClasses = 83;

  /// Número de predicciones del modelo
  static const int modelNumPredictions = 8400;

  /// Umbral de confianza por defecto
  static const double defaultConfidenceThreshold = 0.40;

  /// Umbral de IoU para NMS por defecto
  static const double defaultIouThreshold = 0.45;

  /// Umbral de confianza alta
  static const double highConfidenceThreshold = 0.70;

  /// Umbral de confianza media
  static const double mediumConfidenceThreshold = 0.50;

  // ═══════════════════════════════════════════════════════════════════════════
  // RUTAS DE ASSETS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Ruta del modelo TFLite
  static const String modelPath = 'assets/models/yolov11n_float32.tflite';

  /// Ruta del archivo de etiquetas
  static const String labelsPath = 'assets/labels/labels.txt';

  /// Ruta de la base de datos de nutrientes
  static const String databasePath = 'assets/database/nutrients.db';

  // ═══════════════════════════════════════════════════════════════════════════
  // DIMENSIONES UI
  // ═══════════════════════════════════════════════════════════════════════════

  /// Padding estándar
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;

  /// Border radius estándar
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 24.0;

  /// Elevación de cards
  static const double elevationSmall = 2.0;
  static const double elevationMedium = 4.0;
  static const double elevationLarge = 8.0;

  /// Tamaños de íconos
  static const double iconSmall = 20.0;
  static const double iconMedium = 24.0;
  static const double iconLarge = 32.0;
  static const double iconXLarge = 48.0;

  // ═══════════════════════════════════════════════════════════════════════════
  // ANIMACIONES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Duración corta (botones, feedback)
  static const Duration animationFast = Duration(milliseconds: 150);

  /// Duración normal (transiciones)
  static const Duration animationNormal = Duration(milliseconds: 300);

  /// Duración larga (pantallas, modales)
  static const Duration animationSlow = Duration(milliseconds: 500);

  // ═══════════════════════════════════════════════════════════════════════════
  // PLATOS SOPORTADOS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Lista de platos que el modelo puede detectar
  static const List<String> supportedDishes = [
    'Ensalada Caprese',
    'Ceviche ecuatoriano',
    'Pizza',
    'Menestra ecuatoriana',
    'Paella',
    'Fritada ecuatoriana',
  ];

  /// Número de platos soportados
  static const int numSupportedDishes = 6;

  // ═══════════════════════════════════════════════════════════════════════════
  // CONFIGURACIÓN DE CÁMARA
  // ═══════════════════════════════════════════════════════════════════════════

  /// Frames a saltar entre inferencias (para rendimiento)
  static const int cameraFrameSkip = 3;

  /// Ancho máximo de imagen para procesamiento
  static const int maxImageWidth = 1920;

  /// Alto máximo de imagen para procesamiento
  static const int maxImageHeight = 1920;

  // ═══════════════════════════════════════════════════════════════════════════
  // MENSAJES DE UI
  // ═══════════════════════════════════════════════════════════════════════════

  /// Mensaje de carga del modelo
  static const String loadingModel = 'Cargando modelo de IA...';

  /// Mensaje de modelo cargado
  static const String modelLoaded = 'Modelo cargado correctamente';

  /// Mensaje de detección en progreso
  static const String detecting = 'Analizando imagen...';

  /// Mensaje sin detecciones
  static const String noDetections = 'No se detectaron ingredientes';

  /// Mensaje de error genérico
  static const String genericError = 'Ocurrió un error inesperado';

  // ═══════════════════════════════════════════════════════════════════════════
  // RUTAS DE NAVEGACIÓN
  // ═══════════════════════════════════════════════════════════════════════════

  /// Ruta de inicio
  static const String routeHome = '/';

  /// Ruta de detección desde galería
  static const String routeGallery = '/gallery';

  /// Ruta de detección desde cámara
  static const String routeCamera = '/camera';

  /// Ruta de resultados
  static const String routeResults = '/results';

  /// Ruta de historial
  static const String routeHistory = '/history';

  /// Ruta de configuración
  static const String routeSettings = '/settings';
}

/// Constantes específicas para desarrollo y debugging.
abstract class DevConstants {
  /// Habilitar logs de debug
  static const bool enableDebugLogs = true;

  /// Mostrar bounding boxes de debug
  static const bool showDebugBoundingBoxes = false;

  /// Tiempo máximo de inferencia antes de warning (ms)
  static const int inferenceWarningMs = 1000;
}

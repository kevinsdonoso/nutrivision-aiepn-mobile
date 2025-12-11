// ╔═══════════════════════════════════════════════════════════════════════════════╗
// ║                         app_exceptions.dart                                   ║
// ║              Excepciones personalizadas para NutriVisionAIEPN                 ║
// ╠═══════════════════════════════════════════════════════════════════════════════╣
// ║  Define excepciones específicas del dominio para mejor manejo de errores.     ║
// ║  Permite identificar y manejar errores de forma granular en toda la app.      ║
// ╚═══════════════════════════════════════════════════════════════════════════════╝

import 'package:flutter/foundation.dart' show debugPrint;

/// Excepción base para todas las excepciones de NutriVision.
///
/// Todas las excepciones personalizadas heredan de esta clase,
/// permitiendo capturar cualquier error de la app con un solo catch.
abstract class NutriVisionException implements Exception {
  /// Mensaje descriptivo del error
  final String message;

  /// Código de error único para identificación
  final String code;

  /// Error original que causó esta excepción (si existe)
  final Object? originalError;

  /// Stack trace del error original (si existe)
  final StackTrace? stackTrace;

  const NutriVisionException({
    required this.message,
    required this.code,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() => '[$code] $message';

  /// Retorna un mensaje amigable para mostrar al usuario
  String get userMessage => message;
}

// ═══════════════════════════════════════════════════════════════════════════════
// EXCEPCIONES DE MODELO ML
// ═══════════════════════════════════════════════════════════════════════════════

/// Excepción lanzada cuando hay errores relacionados con el modelo ML.
class ModelException extends NutriVisionException {
  const ModelException({
    required super.message,
    super.code = 'MODEL_ERROR',
    super.originalError,
    super.stackTrace,
  });

  @override
  String get userMessage => 'Error con el modelo de detección. Por favor reinicia la aplicación.';
}

/// Excepción cuando el modelo no se puede cargar.
class ModelLoadException extends ModelException {
  /// Ruta del modelo que falló al cargar
  final String? modelPath;

  const ModelLoadException({
    required super.message,
    this.modelPath,
    super.originalError,
    super.stackTrace,
  }) : super(code: 'MODEL_LOAD_ERROR');

  @override
  String get userMessage => 'No se pudo cargar el modelo de IA. Verifica que la app esté instalada correctamente.';
}

/// Excepción cuando las etiquetas no se pueden cargar.
class LabelsLoadException extends ModelException {
  /// Ruta del archivo de etiquetas que falló
  final String? labelsPath;

  const LabelsLoadException({
    required super.message,
    this.labelsPath,
    super.originalError,
    super.stackTrace,
  }) : super(code: 'LABELS_LOAD_ERROR');

  @override
  String get userMessage => 'No se pudieron cargar las etiquetas de ingredientes.';
}

/// Excepción cuando el modelo no está inicializado antes de usarse.
class ModelNotInitializedException extends ModelException {
  const ModelNotInitializedException({
    super.message = 'El detector no ha sido inicializado. Llama a initialize() primero.',
    super.originalError,
    super.stackTrace,
  }) : super(code: 'MODEL_NOT_INITIALIZED');

  @override
  String get userMessage => 'El detector no está listo. Por favor espera a que se cargue.';
}

/// Excepción cuando el modelo ya fue liberado/disposed.
class ModelDisposedException extends ModelException {
  const ModelDisposedException({
    super.message = 'El detector ya fue liberado y no puede ser usado.',
    super.originalError,
    super.stackTrace,
  }) : super(code: 'MODEL_DISPOSED');

  @override
  String get userMessage => 'El detector fue cerrado. Reinicia la detección.';
}

// ═══════════════════════════════════════════════════════════════════════════════
// EXCEPCIONES DE INFERENCIA
// ═══════════════════════════════════════════════════════════════════════════════

/// Excepción base para errores durante la inferencia.
class InferenceException extends NutriVisionException {
  const InferenceException({
    required super.message,
    super.code = 'INFERENCE_ERROR',
    super.originalError,
    super.stackTrace,
  });

  @override
  String get userMessage => 'Error al analizar la imagen. Intenta con otra imagen.';
}

/// Excepción durante el preprocesamiento de imagen.
class PreprocessingException extends InferenceException {
  const PreprocessingException({
    required super.message,
    super.originalError,
    super.stackTrace,
  }) : super(code: 'PREPROCESSING_ERROR');

  @override
  String get userMessage => 'Error al procesar la imagen. Verifica que el formato sea válido.';
}

/// Excepción durante el postprocesamiento de resultados.
class PostprocessingException extends InferenceException {
  const PostprocessingException({
    required super.message,
    super.originalError,
    super.stackTrace,
  }) : super(code: 'POSTPROCESSING_ERROR');

  @override
  String get userMessage => 'Error al procesar los resultados de detección.';
}

/// Excepción cuando la inferencia toma demasiado tiempo.
class InferenceTimeoutException extends InferenceException {
  /// Tiempo máximo permitido en milisegundos
  final int timeoutMs;

  /// Tiempo real que tomó en milisegundos
  final int actualMs;

  const InferenceTimeoutException({
    required this.timeoutMs,
    required this.actualMs,
    super.message = 'La inferencia excedió el tiempo límite',
    super.originalError,
    super.stackTrace,
  }) : super(code: 'INFERENCE_TIMEOUT');

  @override
  String get userMessage => 'El análisis está tardando demasiado. Intenta con una imagen más pequeña.';
}

// ═══════════════════════════════════════════════════════════════════════════════
// EXCEPCIONES DE IMAGEN
// ═══════════════════════════════════════════════════════════════════════════════

/// Excepción base para errores relacionados con imágenes.
class ImageException extends NutriVisionException {
  const ImageException({
    required super.message,
    super.code = 'IMAGE_ERROR',
    super.originalError,
    super.stackTrace,
  });

  @override
  String get userMessage => 'Error con la imagen. Intenta con otra.';
}

/// Excepción cuando la imagen no se puede decodificar.
class ImageDecodeException extends ImageException {
  /// Formato de imagen detectado (si se conoce)
  final String? detectedFormat;

  const ImageDecodeException({
    required super.message,
    this.detectedFormat,
    super.originalError,
    super.stackTrace,
  }) : super(code: 'IMAGE_DECODE_ERROR');

  @override
  String get userMessage => 'No se pudo leer la imagen. Asegúrate de que sea JPG, PNG o WEBP.';
}

/// Excepción cuando la imagen tiene dimensiones inválidas.
class ImageDimensionsException extends ImageException {
  /// Ancho de la imagen
  final int? width;

  /// Alto de la imagen
  final int? height;

  /// Ancho mínimo requerido
  final int? minWidth;

  /// Alto mínimo requerido
  final int? minHeight;

  const ImageDimensionsException({
    required super.message,
    this.width,
    this.height,
    this.minWidth,
    this.minHeight,
    super.originalError,
    super.stackTrace,
  }) : super(code: 'IMAGE_DIMENSIONS_ERROR');

  @override
  String get userMessage => 'La imagen es demasiado pequeña o tiene dimensiones inválidas.';
}

/// Excepción cuando no se puede acceder al archivo de imagen.
class ImageFileException extends ImageException {
  /// Ruta del archivo
  final String? filePath;

  const ImageFileException({
    required super.message,
    this.filePath,
    super.originalError,
    super.stackTrace,
  }) : super(code: 'IMAGE_FILE_ERROR');

  @override
  String get userMessage => 'No se pudo acceder al archivo de imagen.';
}

// ═══════════════════════════════════════════════════════════════════════════════
// EXCEPCIONES DE DETECCIÓN
// ═══════════════════════════════════════════════════════════════════════════════

/// Excepción base para errores en datos de detección.
class DetectionException extends NutriVisionException {
  const DetectionException({
    required super.message,
    super.code = 'DETECTION_ERROR',
    super.originalError,
    super.stackTrace,
  });

  @override
  String get userMessage => 'Error en los datos de detección.';
}

/// Excepción cuando las coordenadas del bounding box son inválidas.
class InvalidBoundingBoxException extends DetectionException {
  /// Coordenadas del bounding box
  final double? x1, y1, x2, y2;

  const InvalidBoundingBoxException({
    required super.message,
    this.x1,
    this.y1,
    this.x2,
    this.y2,
    super.originalError,
    super.stackTrace,
  }) : super(code: 'INVALID_BBOX');

  @override
  String get userMessage => 'Coordenadas de detección inválidas.';
}

/// Excepción cuando el ID de clase está fuera de rango.
class InvalidClassIdException extends DetectionException {
  /// ID de clase recibido
  final int classId;

  /// Número total de clases válidas
  final int totalClasses;

  const InvalidClassIdException({
    required this.classId,
    required this.totalClasses,
    super.message = 'ID de clase fuera de rango',
    super.originalError,
    super.stackTrace,
  }) : super(code: 'INVALID_CLASS_ID');

  @override
  String get userMessage => 'Se detectó una clase desconocida.';
}

/// Excepción cuando la confianza está fuera del rango válido.
class InvalidConfidenceException extends DetectionException {
  /// Valor de confianza recibido
  final double confidence;

  const InvalidConfidenceException({
    required this.confidence,
    super.message = 'Valor de confianza debe estar entre 0.0 y 1.0',
    super.originalError,
    super.stackTrace,
  }) : super(code: 'INVALID_CONFIDENCE');
}

// ═══════════════════════════════════════════════════════════════════════════════
// EXCEPCIONES DE PERMISOS
// ═══════════════════════════════════════════════════════════════════════════════

/// Excepción cuando faltan permisos necesarios.
class PermissionException extends NutriVisionException {
  /// Tipo de permiso que falta
  final String permissionType;

  const PermissionException({
    required super.message,
    required this.permissionType,
    super.code = 'PERMISSION_DENIED',
    super.originalError,
    super.stackTrace,
  });

  @override
  String get userMessage => 'Se requiere permiso de $permissionType para continuar.';
}

/// Excepción cuando el permiso de cámara es denegado.
class CameraPermissionException extends PermissionException {
  const CameraPermissionException({
    super.message = 'Permiso de cámara denegado',
    super.originalError,
    super.stackTrace,
  }) : super(permissionType: 'cámara', code: 'CAMERA_PERMISSION_DENIED');

  @override
  String get userMessage => 'Necesitamos acceso a la cámara para detectar ingredientes.';
}

/// Excepción cuando el permiso de galería es denegado.
class GalleryPermissionException extends PermissionException {
  const GalleryPermissionException({
    super.message = 'Permiso de galería denegado',
    super.originalError,
    super.stackTrace,
  }) : super(permissionType: 'galería', code: 'GALLERY_PERMISSION_DENIED');

  @override
  String get userMessage => 'Necesitamos acceso a la galería para seleccionar imágenes.';
}

// ═══════════════════════════════════════════════════════════════════════════════
// EXCEPCIONES DE BASE DE DATOS
// ═══════════════════════════════════════════════════════════════════════════════

/// Excepción base para errores de base de datos.
class DatabaseException extends NutriVisionException {
  const DatabaseException({
    required super.message,
    super.code = 'DATABASE_ERROR',
    super.originalError,
    super.stackTrace,
  });

  @override
  String get userMessage => 'Error al acceder a los datos. Intenta de nuevo.';
}

/// Excepción cuando no se encuentra un ingrediente en la base de datos.
class IngredientNotFoundException extends DatabaseException {
  /// Nombre del ingrediente buscado
  final String ingredientName;

  const IngredientNotFoundException({
    required this.ingredientName,
    super.message = 'Ingrediente no encontrado en la base de datos',
    super.originalError,
    super.stackTrace,
  }) : super(code: 'INGREDIENT_NOT_FOUND');

  @override
  String get userMessage => 'No tenemos información nutricional para "$ingredientName".';
}

/// Excepción para errores de datos nutricionales.
class NutritionDataException extends DatabaseException {
  const NutritionDataException({
    required super.message,
    super.originalError,
    super.stackTrace,
  }) : super(code: 'NUTRITION_DATA_ERROR');

  @override
  String get userMessage => 'Error cargando datos nutricionales.';
}

/// Excepción cuando el archivo JSON de nutrición está malformado.
class NutritionJsonParseException extends NutritionDataException {
  const NutritionJsonParseException({
    required super.message,
    super.originalError,
    super.stackTrace,
  });

  @override
  String get userMessage => 'El archivo de datos nutricionales está corrupto.';
}

// ═══════════════════════════════════════════════════════════════════════════════
// UTILIDADES PARA MANEJO DE EXCEPCIONES
// ═══════════════════════════════════════════════════════════════════════════════

/// Utilidades para manejo centralizado de excepciones.
class ExceptionHandler {
  /// Convierte cualquier excepción a una NutriVisionException.
  ///
  /// Si ya es una NutriVisionException, la retorna sin cambios.
  /// Si no, la envuelve en una excepción genérica.
  static NutriVisionException wrap(Object error, [StackTrace? stackTrace]) {
    if (error is NutriVisionException) {
      return error;
    }

    return NutriVisionGenericException(
      message: error.toString(),
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  /// Obtiene un mensaje amigable para cualquier error.
  static String getUserMessage(Object error) {
    if (error is NutriVisionException) {
      return error.userMessage;
    }
    return 'Ocurrió un error inesperado. Por favor intenta de nuevo.';
  }

  /// Registra el error para debugging.
  ///
  /// Nota: Para producción, considerar integración con Firebase Crashlytics
  /// o similar servicio de crash reporting.
  static void logError(Object error, [StackTrace? stackTrace]) {
    // Solo se ejecuta en debug mode (assert se elimina en release)
    assert(() {
      debugPrint('🔴 ERROR: $error');
      if (stackTrace != null) {
        debugPrint('📍 Stack trace: $stackTrace');
      }
      return true;
    }());
  }
}

/// Excepción genérica para errores no categorizados.
class NutriVisionGenericException extends NutriVisionException {
  const NutriVisionGenericException({
    required super.message,
    super.originalError,
    super.stackTrace,
  }) : super(code: 'GENERIC_ERROR');

  @override
  String get userMessage => 'Ocurrió un error inesperado. Por favor intenta de nuevo.';
}

// ═══════════════════════════════════════════════════════════════════════════════
// EXCEPCIONES DE CÁMARA
// ═══════════════════════════════════════════════════════════════════════════════

/// Excepción cuando la cámara no se puede inicializar.
class CameraInitializationException extends NutriVisionException {
  const CameraInitializationException({
    required super.message,
    super.originalError,
    super.stackTrace,
  }) : super(code: 'CAMERA_INIT_ERROR');

  @override
  String get userMessage =>
      'No se pudo inicializar la cámara. Verifica los permisos en configuración.';
}

/// Excepción cuando falla el streaming de frames.
class CameraStreamException extends NutriVisionException {
  const CameraStreamException({
    required super.message,
    super.originalError,
    super.stackTrace,
  }) : super(code: 'CAMERA_STREAM_ERROR');

  @override
  String get userMessage =>
      'Error en la transmisión de la cámara. Intenta reiniciar la aplicación.';
}

/// Excepción cuando falla la conversión de frame YUV a RGB.
class FrameConversionException extends NutriVisionException {
  const FrameConversionException({
    required super.message,
    super.originalError,
    super.stackTrace,
  }) : super(code: 'FRAME_CONVERSION_ERROR');

  @override
  String get userMessage =>
      'Error procesando el frame de cámara.';
}

/// Excepción cuando no hay cámaras disponibles.
class NoCameraAvailableException extends NutriVisionException {
  const NoCameraAvailableException({
    super.message = 'No se encontraron cámaras disponibles',
    super.originalError,
    super.stackTrace,
  }) : super(code: 'NO_CAMERA_AVAILABLE');

  @override
  String get userMessage =>
      'No se encontraron cámaras en el dispositivo.';
}

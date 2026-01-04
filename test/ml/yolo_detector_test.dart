// ╔═══════════════════════════════════════════════════════════════════════════════╗
// ║                      yolo_detector_test.dart                                  ║
// ║          Tests para el detector YOLO11n - NutriVisionAIEPN                    ║
// ╠═══════════════════════════════════════════════════════════════════════════════╣
// ║  Verifica que el detector YOLO funciona correctamente.                        ║
// ║  Usa las imágenes de prueba en test/test_assets/test_images/                  ║
// ║                                                                               ║
// ║  Ejecutar con: flutter test test/ml/yolo_detector_test.dart                   ║
// ║                                                                               ║
// ║  v2.0 - Actualizado para usar excepciones personalizadas                      ║
// ╚═══════════════════════════════════════════════════════════════════════════════╝

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'package:nutrivision_aiepn_mobile/core/exceptions/app_exceptions.dart';
import 'package:nutrivision_aiepn_mobile/core/logging/log_config.dart';
import 'package:nutrivision_aiepn_mobile/data/models/detection.dart';
import 'package:nutrivision_aiepn_mobile/features/detection/services/yolo_detector.dart';

/// Configuración del test
class TestConfig {
  /// Ruta a la carpeta con imágenes de prueba
  static const String testImagesPath = 'test/test_assets/test_images';

  /// Umbral de confianza para las pruebas
  static const double confidenceThreshold = 0.40;

  /// Umbral de IoU para NMS
  static const double iouThreshold = 0.45;
}

void main() {
  // ═══════════════════════════════════════════════════════════════════════════
  // ⚠️ IMPORTANTE: Inicializar el binding de Flutter para tests
  // ═══════════════════════════════════════════════════════════════════════════
  TestWidgetsFlutterBinding.ensureInitialized();

  // ═══════════════════════════════════════════════════════════════════════════
  // CONFIGURACIÓN INICIAL
  // ═══════════════════════════════════════════════════════════════════════════

  late YoloDetector detector;
  late bool hasTestImages;

  setUpAll(() async {
    // Silenciar logs durante tests
    LogConfig.configureForTests();

    // Verificar si existen las imágenes de prueba
    final testDir = Directory(TestConfig.testImagesPath);
    hasTestImages = await testDir.exists();

    if (!hasTestImages) {
      // ignore: avoid_print
      print('');
      // ignore: avoid_print
      print('⚠️  NOTA: No se encontraron imágenes de prueba');
      // ignore: avoid_print
      print('   Ruta esperada: ${TestConfig.testImagesPath}');
      // ignore: avoid_print
      print('');
    }

    // Inicializar detector
    detector = YoloDetector();
    await detector.initialize();
  });

  tearDownAll(() {
    detector.dispose();
    LogConfig.reset();
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GRUPO 1: INICIALIZACIÓN DEL DETECTOR
  // ═══════════════════════════════════════════════════════════════════════════

  group('YoloDetector - Inicialización', () {
    test('Se inicializa correctamente', () async {
      final testDetector = YoloDetector();

      expect(testDetector.isInitialized, isFalse);

      await testDetector.initialize();

      expect(testDetector.isInitialized, isTrue);
      expect(testDetector.labelCount, equals(83));
      expect(testDetector.labels, isNotEmpty);

      testDetector.dispose();
      expect(testDetector.isInitialized, isFalse);
    });

    test('Carga exactamente 83 clases de ingredientes', () async {
      final testDetector = YoloDetector();
      await testDetector.initialize();

      expect(testDetector.labelCount, equals(83),
          reason:
              'El modelo NutriVisionAIEPN debe tener exactamente 83 clases');

      testDetector.dispose();
    });

    test('Inicialización múltiple es segura (idempotente)', () async {
      final testDetector = YoloDetector();

      await testDetector.initialize();
      await testDetector.initialize();
      await testDetector.initialize();

      expect(testDetector.isInitialized, isTrue);
      expect(testDetector.labelCount, equals(83));

      testDetector.dispose();
    });

    // ═══════════════════════════════════════════════════════════════════════
    // ✅ CORREGIDO: Ahora espera ModelNotInitializedException
    // ═══════════════════════════════════════════════════════════════════════
    test('Detectar sin inicializar lanza ModelNotInitializedException',
        () async {
      final testDetector = YoloDetector();
      final dummyImage = img.Image(width: 100, height: 100);

      expect(
        () async => await testDetector.detect(dummyImage),
        throwsA(isA<ModelNotInitializedException>()),
      );
    });

    // ═══════════════════════════════════════════════════════════════════════
    // ✅ NUEVO: Test para ModelDisposedException
    // ═══════════════════════════════════════════════════════════════════════
    test('Detectar después de dispose lanza ModelDisposedException', () async {
      final testDetector = YoloDetector();
      await testDetector.initialize();
      testDetector.dispose();

      final dummyImage = img.Image(width: 100, height: 100);

      expect(
        () async => await testDetector.detect(dummyImage),
        throwsA(isA<ModelDisposedException>()),
      );
    });

    // ═══════════════════════════════════════════════════════════════════════
    // ✅ NUEVO: Test para inicializar después de dispose
    // ═══════════════════════════════════════════════════════════════════════
    test('Inicializar después de dispose lanza ModelDisposedException',
        () async {
      final testDetector = YoloDetector();
      await testDetector.initialize();
      testDetector.dispose();

      expect(
        () async => await testDetector.initialize(),
        throwsA(isA<ModelDisposedException>()),
      );
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GRUPO 2: MODELO DETECTION - PROPIEDADES
  // ═══════════════════════════════════════════════════════════════════════════

  group('Detection - Propiedades', () {
    test('Calcula dimensiones correctamente', () {
      final detection = Detection(
        x1: 100,
        y1: 100,
        x2: 200,
        y2: 150,
        confidence: 0.85,
        classId: 5,
        label: 'tomate',
      );

      expect(detection.width, equals(100));
      expect(detection.height, equals(50));
      expect(detection.area, equals(5000));
      expect(detection.centerX, equals(150));
      expect(detection.centerY, equals(125));
      expect(detection.aspectRatio, equals(2.0));
    });

    test('Calcula propiedades de confianza correctamente', () {
      final highConf = Detection(
        x1: 0,
        y1: 0,
        x2: 10,
        y2: 10,
        confidence: 0.85,
        classId: 0,
        label: 'test',
      );
      final medConf = Detection(
        x1: 0,
        y1: 0,
        x2: 10,
        y2: 10,
        confidence: 0.55,
        classId: 0,
        label: 'test',
      );
      final lowConf = Detection(
        x1: 0,
        y1: 0,
        x2: 10,
        y2: 10,
        confidence: 0.35,
        classId: 0,
        label: 'test',
      );

      expect(highConf.isHighConfidence, isTrue);
      expect(highConf.isMediumConfidence, isFalse);
      expect(highConf.isLowConfidence, isFalse);
      expect(highConf.confidencePercent, equals(85.0));

      expect(medConf.isHighConfidence, isFalse);
      expect(medConf.isMediumConfidence, isTrue);

      expect(lowConf.isHighConfidence, isFalse);
      expect(lowConf.isLowConfidence, isTrue);
    });

    test('calculateIoU - Cajas idénticas = IoU 1.0', () {
      final det1 = Detection(
        x1: 0,
        y1: 0,
        x2: 100,
        y2: 100,
        confidence: 0.9,
        classId: 0,
        label: 'test',
      );
      final det2 = Detection(
        x1: 0,
        y1: 0,
        x2: 100,
        y2: 100,
        confidence: 0.9,
        classId: 0,
        label: 'test',
      );

      expect(det1.calculateIoU(det2), closeTo(1.0, 0.001));
    });

    test('calculateIoU - Sin overlap = IoU 0.0', () {
      final det1 = Detection(
        x1: 0,
        y1: 0,
        x2: 100,
        y2: 100,
        confidence: 0.9,
        classId: 0,
        label: 'test',
      );
      final det2 = Detection(
        x1: 200,
        y1: 200,
        x2: 300,
        y2: 300,
        confidence: 0.9,
        classId: 0,
        label: 'test',
      );

      expect(det1.calculateIoU(det2), equals(0.0));
    });

    test('calculateIoU - Overlap parcial', () {
      final det1 = Detection(
        x1: 0,
        y1: 0,
        x2: 100,
        y2: 100,
        confidence: 0.9,
        classId: 0,
        label: 'test',
      );
      final det2 = Detection(
        x1: 50,
        y1: 0,
        x2: 150,
        y2: 100,
        confidence: 0.9,
        classId: 0,
        label: 'test',
      );

      expect(det1.calculateIoU(det2), closeTo(0.333, 0.01));
    });

    test('toJson y fromJson son inversos', () {
      final original = Detection(
        x1: 10.5,
        y1: 20.3,
        x2: 100.7,
        y2: 200.9,
        confidence: 0.756,
        classId: 42,
        label: 'albahaca',
      );

      final jsonMap = original.toJson();
      final restored = Detection.fromJson(jsonMap);

      expect(restored.x1, equals(original.x1));
      expect(restored.y1, equals(original.y1));
      expect(restored.x2, equals(original.x2));
      expect(restored.y2, equals(original.y2));
      expect(restored.confidence, equals(original.confidence));
      expect(restored.classId, equals(original.classId));
      expect(restored.label, equals(original.label));
    });

    test('copyWith crea copia modificada', () {
      final original = Detection(
        x1: 10,
        y1: 20,
        x2: 100,
        y2: 200,
        confidence: 0.8,
        classId: 5,
        label: 'tomate',
      );

      final modified =
          original.copyWith(confidence: 0.95, label: 'tomate_maduro');

      expect(modified.confidence, equals(0.95));
      expect(modified.label, equals('tomate_maduro'));
      expect(modified.x1, equals(original.x1));
      expect(modified.classId, equals(original.classId));
    });

    test('scale escala coordenadas', () {
      final original = Detection(
        x1: 100,
        y1: 100,
        x2: 200,
        y2: 200,
        confidence: 0.8,
        classId: 5,
        label: 'tomate',
      );

      final scaled = original.scale(0.5, 2.0);

      expect(scaled.x1, equals(50));
      expect(scaled.y1, equals(200));
      expect(scaled.x2, equals(100));
      expect(scaled.y2, equals(400));
    });

    // ═══════════════════════════════════════════════════════════════════════
    // ✅ NUEVOS: Tests para validaciones de Detection
    // ═══════════════════════════════════════════════════════════════════════
    test('Constructor lanza InvalidBoundingBoxException si x2 <= x1', () {
      expect(
        () => Detection(
          x1: 100, y1: 0, x2: 50, y2: 100, // x2 < x1
          confidence: 0.8, classId: 0, label: 'test',
        ),
        throwsA(isA<InvalidBoundingBoxException>()),
      );
    });

    test('Constructor lanza InvalidBoundingBoxException si y2 <= y1', () {
      expect(
        () => Detection(
          x1: 0, y1: 100, x2: 100, y2: 50, // y2 < y1
          confidence: 0.8, classId: 0, label: 'test',
        ),
        throwsA(isA<InvalidBoundingBoxException>()),
      );
    });

    test(
        'Constructor lanza InvalidConfidenceException si confianza fuera de rango',
        () {
      expect(
        () => Detection(
          x1: 0, y1: 0, x2: 100, y2: 100,
          confidence: 1.5, // > 1.0
          classId: 0, label: 'test',
        ),
        throwsA(isA<InvalidConfidenceException>()),
      );

      expect(
        () => Detection(
          x1: 0, y1: 0, x2: 100, y2: 100,
          confidence: -0.1, // < 0.0
          classId: 0, label: 'test',
        ),
        throwsA(isA<InvalidConfidenceException>()),
      );
    });

    test('Constructor lanza InvalidClassIdException si classId negativo', () {
      expect(
        () => Detection(
          x1: 0, y1: 0, x2: 100, y2: 100,
          confidence: 0.8,
          classId: -1, // negativo
          label: 'test',
        ),
        throwsA(isA<InvalidClassIdException>()),
      );
    });

    test('Detection.fromModelOutput normaliza valores inválidos', () {
      // Valores que serían inválidos en el constructor normal
      final detection = Detection.fromModelOutput(
        x1: -10, // negativo
        y1: -5, // negativo
        x2: 100,
        y2: 200,
        confidence: 1.5, // > 1.0
        classId: -1, // negativo
        label: '', // vacío
        imageWidth: 640,
        imageHeight: 480,
      );

      // Debe normalizar a valores válidos
      expect(detection.x1, greaterThanOrEqualTo(0));
      expect(detection.y1, greaterThanOrEqualTo(0));
      expect(detection.confidence, lessThanOrEqualTo(1.0));
      expect(detection.classId, greaterThanOrEqualTo(0));
      expect(detection.label, isNotEmpty);
    });

    test('Detection.tryCreate retorna null para datos inválidos', () {
      final result = Detection.tryCreate(
        x1: 100, y1: 0, x2: 50, y2: 100, // x2 < x1 - inválido
        confidence: 0.8, classId: 0, label: 'test',
      );

      expect(result, isNull);
    });

    test('Detection.tryCreate retorna Detection para datos válidos', () {
      final result = Detection.tryCreate(
        x1: 0,
        y1: 0,
        x2: 100,
        y2: 100,
        confidence: 0.8,
        classId: 0,
        label: 'test',
      );

      expect(result, isNotNull);
      expect(result!.label, equals('test'));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GRUPO 3: EXTENSIONES DE LISTA
  // ═══════════════════════════════════════════════════════════════════════════

  group('DetectionListExtension', () {
    late List<Detection> testDetections;

    setUp(() {
      testDetections = [
        Detection(
            x1: 0,
            y1: 0,
            x2: 10,
            y2: 10,
            confidence: 0.90,
            classId: 0,
            label: 'tomate'),
        Detection(
            x1: 0,
            y1: 0,
            x2: 10,
            y2: 10,
            confidence: 0.50,
            classId: 0,
            label: 'tomate'),
        Detection(
            x1: 0,
            y1: 0,
            x2: 10,
            y2: 10,
            confidence: 0.80,
            classId: 1,
            label: 'cebolla'),
        Detection(
            x1: 0,
            y1: 0,
            x2: 10,
            y2: 10,
            confidence: 0.30,
            classId: 2,
            label: 'ajo'),
      ];
    });

    test('filterByConfidence filtra correctamente', () {
      final highConf = testDetections.filterByConfidence(0.7);
      expect(highConf.length, equals(2));
      expect(highConf.every((d) => d.confidence >= 0.7), isTrue);
    });

    test('filterByClass filtra por classId', () {
      final class0 = testDetections.filterByClass(0);
      expect(class0.length, equals(2));
    });

    test('filterByLabel filtra por etiqueta', () {
      final tomates = testDetections.filterByLabel('tomate');
      expect(tomates.length, equals(2));
    });

    test('sortedByConfidence ordena de mayor a menor', () {
      final sorted = testDetections.sortedByConfidence();
      expect(sorted.first.confidence, equals(0.90));
      expect(sorted.last.confidence, equals(0.30));
    });

    test('uniqueLabels retorna etiquetas únicas', () {
      expect(testDetections.uniqueLabels, equals({'tomate', 'cebolla', 'ajo'}));
    });

    test('ingredientCounts cuenta correctamente', () {
      final counts = testDetections.ingredientCounts;
      expect(counts['tomate'], equals(2));
      expect(counts['cebolla'], equals(1));
      expect(counts['ajo'], equals(1));
    });

    test('groupByLabel agrupa correctamente', () {
      final grouped = testDetections.groupByLabel();
      expect(grouped.keys.length, equals(3));
      expect(grouped['tomate']!.length, equals(2));
    });

    test('mostConfident retorna la detección con mayor confianza', () {
      final most = testDetections.mostConfident;
      expect(most, isNotNull);
      expect(most!.confidence, equals(0.90));
      expect(most.label, equals('tomate'));
    });

    test('averageConfidence calcula el promedio', () {
      final avg = testDetections.averageConfidence;
      expect(avg, closeTo(0.625, 0.001)); // (0.90 + 0.50 + 0.80 + 0.30) / 4
    });

    test('stats retorna estadísticas correctas', () {
      final stats = testDetections.stats;
      expect(stats.total, equals(4));
      expect(stats.uniqueIngredients, equals(3));
      expect(stats.highConfidence, equals(2)); // 0.90 y 0.80
      expect(stats.mediumConfidence, equals(1)); // 0.50
      expect(stats.lowConfidence, equals(1)); // 0.30
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GRUPO 4: DETECCIÓN BÁSICA
  // ═══════════════════════════════════════════════════════════════════════════

  group('YoloDetector - Detección', () {
    test('Maneja imagen sólida sin ingredientes', () async {
      final testDetector = YoloDetector();
      await testDetector.initialize();

      final solidImage = img.Image(width: 640, height: 640);
      img.fill(solidImage, color: img.ColorRgb8(128, 128, 128));

      final detections = await testDetector.detect(solidImage);

      expect(detections.length, lessThan(5),
          reason: 'Imagen sólida no debería generar muchas detecciones');

      testDetector.dispose();
    });

    test('Maneja diferentes tamaños de imagen', () async {
      final testDetector = YoloDetector();
      await testDetector.initialize();

      final sizes = [(100, 100), (640, 480), (480, 640), (1920, 1080)];

      for (final (width, height) in sizes) {
        final testImage = img.Image(width: width, height: height);
        img.fill(testImage, color: img.ColorRgb8(200, 150, 100));

        final detections = await testDetector.detect(testImage);
        expect(detections, isA<List<Detection>>(),
            reason: 'Debe procesar imagen ${width}x$height');
      }

      testDetector.dispose();
    });

    test('Umbrales de confianza funcionan', () async {
      if (!hasTestImages) {
        // ignore: avoid_print
        print('⏭️ Saltando: no hay imágenes de prueba');
        return;
      }

      final testDir = Directory(TestConfig.testImagesPath);
      final files = await testDir.list().toList();
      final jpgFile = files.whereType<File>().firstWhere(
            (f) =>
                f.path.toLowerCase().endsWith('.jpg') ||
                f.path.toLowerCase().endsWith('.jpeg'),
            orElse: () => throw Exception('No hay imágenes'),
          );

      final bytes = await jpgFile.readAsBytes();
      final image = img.decodeImage(bytes)!;

      final low = await detector.detect(image, confidenceThreshold: 0.20);
      final mid = await detector.detect(image, confidenceThreshold: 0.50);
      final high = await detector.detect(image, confidenceThreshold: 0.80);

      expect(low.length, greaterThanOrEqualTo(mid.length));
      expect(mid.length, greaterThanOrEqualTo(high.length));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GRUPO 5: CONSISTENCIA
  // ═══════════════════════════════════════════════════════════════════════════

  group('YoloDetector - Consistencia', () {
    test('Misma imagen = mismos resultados (determinismo)', () async {
      if (!hasTestImages) {
        // ignore: avoid_print
        print('⏭️ Saltando: no hay imágenes de prueba');
        return;
      }

      final testDir = Directory(TestConfig.testImagesPath);
      final files = await testDir.list().toList();
      final jpgFile = files.whereType<File>().firstWhere(
            (f) => f.path.toLowerCase().endsWith('.jpg'),
            orElse: () => throw Exception('No hay archivos JPG'),
          );

      final bytes = await jpgFile.readAsBytes();
      final image = img.decodeImage(bytes)!;

      final results1 = await detector.detect(image);
      final results2 = await detector.detect(image);
      final results3 = await detector.detect(image);

      expect(results1.length, equals(results2.length));
      expect(results2.length, equals(results3.length));

      final labels1 = results1.map((d) => d.label).toSet();
      final labels2 = results2.map((d) => d.label).toSet();

      expect(labels1, equals(labels2));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GRUPO 6: IMÁGENES DE PRUEBA
  // ═══════════════════════════════════════════════════════════════════════════

  group('YoloDetector - Imágenes de Kaggle', () {
    test(
      'Todas las imágenes se procesan sin error',
      () async {
        if (!hasTestImages) {
          // ignore: avoid_print
          print('⏭️ Saltando: no hay imágenes de prueba');
          return;
        }

        final testDir = Directory(TestConfig.testImagesPath);
        final files = await testDir.list().toList();
        final imageFiles = files.whereType<File>().where((f) {
          final ext = f.path.toLowerCase();
          return ext.endsWith('.jpg') ||
              ext.endsWith('.jpeg') ||
              ext.endsWith('.png');
        }).toList();

        expect(imageFiles, isNotEmpty);

        int successCount = 0;

        for (final file in imageFiles) {
          final bytes = await file.readAsBytes();
          final image = img.decodeImage(bytes);

          if (image != null) {
            final detections = await detector.detect(image);
            expect(detections, isA<List<Detection>>());
            successCount++;

            final fileName = file.path.split(Platform.pathSeparator).last;
            // ignore: avoid_print
            print('   ✓ $fileName: ${detections.length} detecciones');
          }
        }

        expect(successCount, equals(imageFiles.length));
      },
      timeout: Timeout(Duration(minutes: 5)),
    );

    test('Detecta ingredientes en imágenes de comida', () async {
      if (!hasTestImages) {
        // ignore: avoid_print
        print('⏭️ Saltando: no hay imágenes de prueba');
        return;
      }

      final testDir = Directory(TestConfig.testImagesPath);
      final files = await testDir.list().toList();
      final imageFiles = files.whereType<File>().where((f) {
        final ext = f.path.toLowerCase();
        return ext.endsWith('.jpg') || ext.endsWith('.jpeg');
      }).toList();

      if (imageFiles.isEmpty) return;

      final bytes = await imageFiles.first.readAsBytes();
      final image = img.decodeImage(bytes)!;

      final detections = await detector.detect(image);

      expect(detections, isNotEmpty,
          reason: 'Imágenes de comida deben tener al menos 1 detección');

      final ingredients = detections.ingredientCounts;
      // ignore: avoid_print
      print('   Ingredientes: $ingredients');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GRUPO 7: RENDIMIENTO
  // ═══════════════════════════════════════════════════════════════════════════

  group('YoloDetector - Rendimiento', () {
    test('Inferencia en menos de 10 segundos', () async {
      if (!hasTestImages) {
        // ignore: avoid_print
        print('⏭️ Saltando: no hay imágenes de prueba');
        return;
      }

      final testDir = Directory(TestConfig.testImagesPath);
      final files = await testDir.list().toList();
      final jpgFile = files.whereType<File>().firstWhere(
            (f) => f.path.toLowerCase().endsWith('.jpg'),
            orElse: () => throw Exception('No hay archivos JPG'),
          );

      final bytes = await jpgFile.readAsBytes();
      final image = img.decodeImage(bytes)!;

      final stopwatch = Stopwatch()..start();
      await detector.detect(image);
      stopwatch.stop();

      // ignore: avoid_print
      print('   ⏱️ Tiempo: ${stopwatch.elapsedMilliseconds}ms');

      expect(stopwatch.elapsedMilliseconds, lessThan(10000));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GRUPO 8: EXCEPCIONES PERSONALIZADAS
  // ═══════════════════════════════════════════════════════════════════════════

  group('Excepciones - Comportamiento', () {
    test('NutriVisionException.toString incluye código y mensaje', () {
      const exception = ModelNotInitializedException();
      final str = exception.toString();

      expect(str, contains('MODEL_NOT_INITIALIZED'));
      expect(str, contains('inicializado'));
    });

    test('ExceptionHandler.wrap envuelve excepciones genéricas', () {
      final genericError = Exception('Error genérico');
      final wrapped = ExceptionHandler.wrap(genericError);

      expect(wrapped, isA<NutriVisionGenericException>());
      expect(wrapped.originalError, equals(genericError));
    });

    test('ExceptionHandler.wrap no re-envuelve NutriVisionException', () {
      const original = ModelLoadException(message: 'Test');
      final wrapped = ExceptionHandler.wrap(original);

      expect(wrapped, same(original));
    });

    test('ExceptionHandler.getUserMessage retorna mensaje amigable', () {
      const exception =
          ImageDecodeException(message: 'Technical error details');
      final userMessage = ExceptionHandler.getUserMessage(exception);

      expect(userMessage, isNot(contains('Technical')));
      expect(userMessage, contains('imagen'));
    });
  });
}

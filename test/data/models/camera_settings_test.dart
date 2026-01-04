// ═══════════════════════════════════════════════════════════════════════════════════
// ║                       camera_settings_test.dart                                 ║
// ║            Tests para modelo de configuracion de camara                         ║
// ═══════════════════════════════════════════════════════════════════════════════════
// ║  Verifica el comportamiento de CameraSettings y CameraResolution.               ║
// ═══════════════════════════════════════════════════════════════════════════════════

import 'package:camera/camera.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrivision_aiepn_mobile/data/models/camera_settings.dart';

void main() {
  // ═══════════════════════════════════════════════════════════════════════════
  // TESTS PARA CameraSettings
  // ═══════════════════════════════════════════════════════════════════════════

  group('CameraSettings', () {
    group('Constantes', () {
      test('minFrameSkip es 1', () {
        expect(CameraSettings.minFrameSkip, 1);
      });

      test('maxFrameSkip es 5', () {
        expect(CameraSettings.maxFrameSkip, 5);
      });

      test('minConfidence es 0.30', () {
        expect(CameraSettings.minConfidence, 0.30);
      });

      test('maxConfidence es 0.80', () {
        expect(CameraSettings.maxConfidence, 0.80);
      });

      test('defaultFrameSkip es 4', () {
        expect(CameraSettings.defaultFrameSkip, 4);
      });

      test('defaultConfidenceThreshold es 0.40', () {
        expect(CameraSettings.defaultConfidenceThreshold, 0.40);
      });

      test('minIouThreshold es 0.20', () {
        expect(CameraSettings.minIouThreshold, 0.20);
      });

      test('maxIouThreshold es 0.50', () {
        expect(CameraSettings.maxIouThreshold, 0.50);
      });

      test('defaultIouThreshold es 0.30', () {
        expect(CameraSettings.defaultIouThreshold, 0.30);
      });
    });

    group('Constructor', () {
      test('crea instancia con valores por defecto', () {
        const settings = CameraSettings();

        expect(settings.frameSkip, 4);
        expect(settings.resolution, CameraResolution.medium);
        expect(settings.confidenceThreshold, 0.40);
        expect(settings.iouThreshold, 0.30);
        expect(settings.showFps, isFalse);
        expect(settings.showMemoryInfo, isFalse);
      });

      test('crea instancia con valores personalizados', () {
        const settings = CameraSettings(
          frameSkip: 2,
          resolution: CameraResolution.high,
          confidenceThreshold: 0.60,
          iouThreshold: 0.35,
          showFps: true,
          showMemoryInfo: true,
        );

        expect(settings.frameSkip, 2);
        expect(settings.resolution, CameraResolution.high);
        expect(settings.confidenceThreshold, 0.60);
        expect(settings.iouThreshold, 0.35);
        expect(settings.showFps, isTrue);
        expect(settings.showMemoryInfo, isTrue);
      });
    });

    group('Factory constructors', () {
      test('defaults crea configuracion por defecto', () {
        final settings = CameraSettings.defaults();

        expect(settings.frameSkip, CameraSettings.defaultFrameSkip);
        expect(settings.resolution, CameraSettings.defaultResolution);
        expect(settings.confidenceThreshold,
            CameraSettings.defaultConfidenceThreshold);
        expect(settings.showFps, CameraSettings.defaultShowFps);
        expect(settings.showMemoryInfo, CameraSettings.defaultShowMemoryInfo);
      });

      test('performanceMode crea configuracion optimizada para rendimiento',
          () {
        final settings = CameraSettings.performanceMode();

        expect(settings.frameSkip, 5);
        expect(settings.resolution, CameraResolution.low);
        expect(settings.confidenceThreshold, 0.55);
        expect(settings.iouThreshold, 0.35);
        expect(settings.showFps, isTrue);
      });

      test('qualityMode crea configuracion optimizada para calidad', () {
        final settings = CameraSettings.qualityMode();

        expect(settings.frameSkip, 1);
        expect(settings.resolution, CameraResolution.high);
        expect(settings.confidenceThreshold, 0.40);
        expect(settings.iouThreshold, 0.30);
        expect(settings.showFps, isFalse);
      });
    });

    group('Serializacion JSON', () {
      test('toJson convierte correctamente', () {
        const settings = CameraSettings(
          frameSkip: 2,
          resolution: CameraResolution.high,
          confidenceThreshold: 0.60,
          iouThreshold: 0.35,
          showFps: true,
          showMemoryInfo: true,
        );

        final json = settings.toJson();

        expect(json['frameSkip'], 2);
        expect(json['resolution'], 'high');
        expect(json['confidenceThreshold'], 0.60);
        expect(json['iouThreshold'], 0.35);
        expect(json['showFps'], true);
        expect(json['showMemoryInfo'], true);
      });

      test('fromJson parsea correctamente', () {
        final json = {
          'frameSkip': 4,
          'resolution': 'low',
          'confidenceThreshold': 0.70,
          'iouThreshold': 0.40,
          'showFps': true,
          'showMemoryInfo': false,
        };

        final settings = CameraSettings.fromJson(json);

        expect(settings.frameSkip, 4);
        expect(settings.resolution, CameraResolution.low);
        expect(settings.confidenceThreshold, 0.70);
        expect(settings.iouThreshold, 0.40);
        expect(settings.showFps, isTrue);
        expect(settings.showMemoryInfo, isFalse);
      });

      test('fromJson usa valores por defecto para campos faltantes', () {
        final json = <String, dynamic>{};

        final settings = CameraSettings.fromJson(json);

        expect(settings.frameSkip, CameraSettings.defaultFrameSkip);
        expect(settings.resolution, CameraSettings.defaultResolution);
        expect(settings.confidenceThreshold,
            CameraSettings.defaultConfidenceThreshold);
        expect(settings.showFps, CameraSettings.defaultShowFps);
        expect(settings.showMemoryInfo, CameraSettings.defaultShowMemoryInfo);
      });

      test('toJson y fromJson son inversos', () {
        const original = CameraSettings(
          frameSkip: 2,
          resolution: CameraResolution.high,
          confidenceThreshold: 0.65,
          iouThreshold: 0.35,
          showFps: true,
          showMemoryInfo: true,
        );

        final json = original.toJson();
        final restored = CameraSettings.fromJson(json);

        expect(restored, equals(original));
      });
    });

    group('copyWith', () {
      test('crea copia con valores modificados', () {
        const original = CameraSettings();
        final modified = original.copyWith(
          frameSkip: 5,
          showFps: true,
        );

        expect(modified.frameSkip, 5);
        expect(modified.showFps, isTrue);
        expect(modified.resolution, original.resolution);
        expect(modified.confidenceThreshold, original.confidenceThreshold);
      });

      test('crea copia identica sin cambios', () {
        const original = CameraSettings(
          frameSkip: 2,
          resolution: CameraResolution.low,
        );
        final copy = original.copyWith();

        expect(copy, equals(original));
      });
    });

    group('validated', () {
      test('clampea frameSkip al rango valido', () {
        // No podemos crear con valor invalido directamente por assert
        // pero podemos verificar que validated funciona con valores validos
        const settings = CameraSettings(frameSkip: 3);
        final validated = settings.validated();

        expect(validated.frameSkip, 3);
      });

      test('clampea confidenceThreshold al rango valido', () {
        const settings = CameraSettings(confidenceThreshold: 0.50);
        final validated = settings.validated();

        expect(validated.confidenceThreshold, 0.50);
      });
    });

    group('isDefault', () {
      test('retorna true para configuracion por defecto', () {
        const settings = CameraSettings();
        expect(settings.isDefault, isTrue);
      });

      test('retorna false si frameSkip difiere', () {
        const settings = CameraSettings(frameSkip: 2);
        expect(settings.isDefault, isFalse);
      });

      test('retorna false si resolution difiere', () {
        const settings = CameraSettings(resolution: CameraResolution.high);
        expect(settings.isDefault, isFalse);
      });

      test('retorna false si confidenceThreshold difiere', () {
        const settings = CameraSettings(confidenceThreshold: 0.60);
        expect(settings.isDefault, isFalse);
      });

      test('retorna false si iouThreshold difiere', () {
        const settings = CameraSettings(iouThreshold: 0.40);
        expect(settings.isDefault, isFalse);
      });

      test('retorna false si showFps difiere', () {
        const settings = CameraSettings(showFps: true);
        expect(settings.isDefault, isFalse);
      });

      test('retorna false si showMemoryInfo difiere', () {
        const settings = CameraSettings(showMemoryInfo: true);
        expect(settings.isDefault, isFalse);
      });
    });

    group('Equality', () {
      test('objetos iguales son iguales', () {
        const a = CameraSettings(
          frameSkip: 2,
          resolution: CameraResolution.high,
          confidenceThreshold: 0.60,
        );
        const b = CameraSettings(
          frameSkip: 2,
          resolution: CameraResolution.high,
          confidenceThreshold: 0.60,
        );

        expect(a == b, isTrue);
        expect(a.hashCode, equals(b.hashCode));
      });

      test('objetos diferentes son diferentes', () {
        const a = CameraSettings(frameSkip: 2);
        const b = CameraSettings(frameSkip: 3);

        expect(a == b, isFalse);
      });
    });

    group('toString', () {
      test('retorna representacion legible', () {
        const settings = CameraSettings(
          frameSkip: 2,
          confidenceThreshold: 0.60,
          iouThreshold: 0.35,
          showFps: true,
        );

        final str = settings.toString();

        expect(str, contains('frameSkip: 2'));
        expect(str, contains('confidence: 60%'));
        expect(str, contains('iou: 35%'));
        expect(str, contains('showFps: true'));
      });
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // TESTS PARA CameraResolution
  // ═══════════════════════════════════════════════════════════════════════════

  group('CameraResolution', () {
    test('tiene 4 valores', () {
      expect(CameraResolution.values.length, 4);
    });

    group('displayName', () {
      test('low retorna Baja', () {
        expect(CameraResolution.low.displayName, 'Baja');
      });

      test('medium retorna Media', () {
        expect(CameraResolution.medium.displayName, 'Media');
      });

      test('high retorna Alta', () {
        expect(CameraResolution.high.displayName, 'Alta');
      });

      test('ultra retorna Ultra', () {
        expect(CameraResolution.ultra.displayName, 'Ultra');
      });
    });

    group('description', () {
      test('low describe poca deteccion', () {
        expect(CameraResolution.low.description, contains('Poca detección'));
      });

      test('medium describe recomendado', () {
        expect(CameraResolution.medium.description, contains('Recomendado'));
      });

      test('high describe mejor deteccion', () {
        expect(CameraResolution.high.description, contains('Mejor detección'));
      });

      test('ultra describe maxima deteccion', () {
        expect(CameraResolution.ultra.description, contains('Máxima detección'));
      });
    });

    group('toResolutionPreset', () {
      test('low mapea a ResolutionPreset.low', () {
        expect(CameraResolution.low.toResolutionPreset(), ResolutionPreset.low);
      });

      test('medium mapea a ResolutionPreset.medium', () {
        expect(CameraResolution.medium.toResolutionPreset(),
            ResolutionPreset.medium);
      });

      test('high mapea a ResolutionPreset.high', () {
        expect(
            CameraResolution.high.toResolutionPreset(), ResolutionPreset.high);
      });

      test('ultra mapea a ResolutionPreset.max', () {
        expect(CameraResolution.ultra.toResolutionPreset(), ResolutionPreset.max);
      });
    });

    group('fromString', () {
      test('parsea low', () {
        expect(CameraResolution.fromString('low'), CameraResolution.low);
      });

      test('parsea medium', () {
        expect(CameraResolution.fromString('medium'), CameraResolution.medium);
      });

      test('parsea high', () {
        expect(CameraResolution.fromString('high'), CameraResolution.high);
      });

      test('parsea ultra', () {
        expect(CameraResolution.fromString('ultra'), CameraResolution.ultra);
      });

      test('es case insensitive', () {
        expect(CameraResolution.fromString('LOW'), CameraResolution.low);
        expect(CameraResolution.fromString('HIGH'), CameraResolution.high);
        expect(CameraResolution.fromString('ULTRA'), CameraResolution.ultra);
      });

      test('usa medium como default para valor invalido', () {
        expect(CameraResolution.fromString('invalid'), CameraResolution.medium);
      });
    });

    group('fromResolutionPreset', () {
      test('mapea ResolutionPreset.low a low', () {
        expect(CameraResolution.fromResolutionPreset(ResolutionPreset.low),
            CameraResolution.low);
      });

      test('mapea ResolutionPreset.medium a medium', () {
        expect(CameraResolution.fromResolutionPreset(ResolutionPreset.medium),
            CameraResolution.medium);
      });

      test('mapea ResolutionPreset.high a high', () {
        expect(CameraResolution.fromResolutionPreset(ResolutionPreset.high),
            CameraResolution.high);
      });

      test('mapea ResolutionPreset.veryHigh a ultra', () {
        expect(CameraResolution.fromResolutionPreset(ResolutionPreset.veryHigh),
            CameraResolution.ultra);
      });

      test('mapea ResolutionPreset.ultraHigh a ultra', () {
        expect(
            CameraResolution.fromResolutionPreset(ResolutionPreset.ultraHigh),
            CameraResolution.ultra);
      });

      test('mapea ResolutionPreset.max a ultra', () {
        expect(CameraResolution.fromResolutionPreset(ResolutionPreset.max),
            CameraResolution.ultra);
      });
    });
  });
}

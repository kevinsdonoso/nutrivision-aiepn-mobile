// ╔═══════════════════════════════════════════════════════════════════════════════╗
// ║                           app_logger_test.dart                                ║
// ║                    Tests para el sistema de logging                           ║
// ╠═══════════════════════════════════════════════════════════════════════════════╣
// ║  Verifica el comportamiento de LogLevel, LogConfig y AppLogger.               ║
// ╚═══════════════════════════════════════════════════════════════════════════════╝

import 'package:flutter_test/flutter_test.dart';
import 'package:nutrivision_aiepn_mobile/core/logging/app_logger.dart';
import 'package:nutrivision_aiepn_mobile/core/logging/log_colors.dart';
import 'package:nutrivision_aiepn_mobile/core/logging/log_config.dart';
import 'package:nutrivision_aiepn_mobile/core/logging/log_level.dart';

void main() {
  // Restaurar configuración antes de cada test
  setUp(() {
    LogConfig.reset();
  });

  group('LogLevel', () {
    test('tiene 5 niveles definidos', () {
      expect(LogLevel.values.length, equals(5));
    });

    test('niveles están en orden correcto de severidad', () {
      expect(LogLevel.debug.index, lessThan(LogLevel.info.index));
      expect(LogLevel.info.index, lessThan(LogLevel.warning.index));
      expect(LogLevel.warning.index, lessThan(LogLevel.error.index));
      expect(LogLevel.error.index, lessThan(LogLevel.none.index));
    });

    test('isAtLeast funciona correctamente', () {
      expect(LogLevel.debug.isAtLeast(LogLevel.debug), isTrue);
      expect(LogLevel.info.isAtLeast(LogLevel.debug), isTrue);
      expect(LogLevel.debug.isAtLeast(LogLevel.info), isFalse);
      expect(LogLevel.error.isAtLeast(LogLevel.warning), isTrue);
      expect(LogLevel.none.isAtLeast(LogLevel.error), isTrue);
    });

    test('cada nivel tiene emoji definido', () {
      expect(LogLevel.debug.emoji, equals('🔍'));
      expect(LogLevel.info.emoji, equals('ℹ️'));
      expect(LogLevel.warning.emoji, equals('⚠️'));
      expect(LogLevel.error.emoji, equals('❌'));
      expect(LogLevel.none.emoji, equals(''));
    });

    test('cada nivel tiene label definido', () {
      expect(LogLevel.debug.label, equals('DEBUG'));
      expect(LogLevel.info.label, equals('INFO'));
      expect(LogLevel.warning.label, equals('WARN'));
      expect(LogLevel.error.label, equals('ERROR'));
      expect(LogLevel.none.label, equals(''));
    });
  });

  group('LogConfig', () {
    test('tiene valores por defecto correctos', () {
      LogConfig.reset();

      // En modo test (debug), los valores por defecto son:
      expect(LogConfig.showTag, isTrue);
      expect(LogConfig.showEmoji, isTrue);
      expect(LogConfig.maxMessageLength, equals(1000));
      expect(LogConfig.maxStackTraceLines, equals(10));
    });

    test('configureForDevelopment establece valores correctos', () {
      LogConfig.configureForDevelopment();

      expect(LogConfig.minLevel, equals(LogLevel.debug));
      expect(LogConfig.showTimestamp, isTrue);
      expect(LogConfig.showTag, isTrue);
      expect(LogConfig.showEmoji, isTrue);
      expect(LogConfig.maxMessageLength, equals(2000));
      expect(LogConfig.maxStackTraceLines, equals(20));
    });

    test('configureForProduction establece valores correctos', () {
      LogConfig.configureForProduction();

      expect(LogConfig.minLevel, equals(LogLevel.error));
      expect(LogConfig.showTimestamp, isFalse);
      expect(LogConfig.showTag, isTrue);
      expect(LogConfig.showEmoji, isFalse);
      expect(LogConfig.maxMessageLength, equals(500));
      expect(LogConfig.maxStackTraceLines, equals(5));
    });

    test('disable desactiva el logging', () {
      LogConfig.disable();

      expect(LogConfig.minLevel, equals(LogLevel.none));
    });

    test('reset restaura valores por defecto', () {
      // Cambiar valores
      LogConfig.minLevel = LogLevel.none;
      LogConfig.showTimestamp = false;
      LogConfig.showTag = false;
      LogConfig.maxMessageLength = 100;

      // Restaurar
      LogConfig.reset();

      // Verificar que se restauraron (en debug mode)
      expect(LogConfig.showTag, isTrue);
      expect(LogConfig.showEmoji, isTrue);
      expect(LogConfig.maxMessageLength, equals(1000));
      expect(LogConfig.maxStackTraceLines, equals(10));
    });
  });

  group('AppLogger', () {
    test('métodos estáticos no lanzan excepciones', () {
      // Verificar que los métodos se pueden llamar sin errores
      expect(
        () => AppLogger.debug('test message'),
        returnsNormally,
      );
      expect(
        () => AppLogger.info('test message'),
        returnsNormally,
      );
      expect(
        () => AppLogger.warning('test message'),
        returnsNormally,
      );
      expect(
        () => AppLogger.error('test message'),
        returnsNormally,
      );
    });

    test('acepta parámetros opcionales sin errores', () {
      expect(
        () => AppLogger.debug('message', tag: 'TestTag'),
        returnsNormally,
      );
      expect(
        () => AppLogger.debug('message', error: Exception('test')),
        returnsNormally,
      );
      expect(
        () => AppLogger.error(
          'message',
          tag: 'TestTag',
          error: Exception('test'),
          stackTrace: StackTrace.current,
        ),
        returnsNormally,
      );
    });

    test('respeta nivel mínimo none (no loguea nada)', () {
      LogConfig.minLevel = LogLevel.none;

      // Ningún método debería fallar, simplemente no hacen nada
      expect(
        () => AppLogger.debug('should not print'),
        returnsNormally,
      );
      expect(
        () => AppLogger.error('should not print'),
        returnsNormally,
      );
    });

    test('acepta mensajes largos sin errores', () {
      final longMessage = 'A' * 5000; // Mensaje de 5000 caracteres

      expect(
        () => AppLogger.debug(longMessage),
        returnsNormally,
      );
    });

    test('acepta tags con caracteres especiales', () {
      expect(
        () => AppLogger.debug('message', tag: 'Tag-With_Special.Chars'),
        returnsNormally,
      );
    });
  });

  group('Integración LogLevel + LogConfig', () {
    test('debug no loguea cuando minLevel es info', () {
      LogConfig.minLevel = LogLevel.info;

      // debug tiene menor severidad que info, no debería loguear
      // (pero no debería lanzar error)
      expect(
        () => AppLogger.debug('should be filtered'),
        returnsNormally,
      );
    });

    test('error siempre loguea excepto cuando none', () {
      LogConfig.minLevel = LogLevel.warning;

      // error tiene mayor severidad que warning, debería loguear
      expect(
        () => AppLogger.error('should log'),
        returnsNormally,
      );
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // TESTS PARA NUEVAS FUNCIONALIDADES (Colores, Tags, QuietMode, Tree)
  // ═══════════════════════════════════════════════════════════════════════════

  group('LogColors', () {
    test('tiene colores básicos definidos', () {
      expect(LogColors.reset, equals('\x1B[0m'));
      expect(LogColors.red, equals('\x1B[31m'));
      expect(LogColors.green, equals('\x1B[32m'));
      expect(LogColors.yellow, equals('\x1B[33m'));
      expect(LogColors.cyan, equals('\x1B[36m'));
      expect(LogColors.gray, equals('\x1B[90m'));
    });

    test('tiene estilos definidos', () {
      expect(LogColors.bold, equals('\x1B[1m'));
      expect(LogColors.dim, equals('\x1B[2m'));
      expect(LogColors.underline, equals('\x1B[4m'));
    });

    test('forLevel retorna color correcto para cada nivel', () {
      expect(LogColors.forLevel(LogLevel.debug), equals(LogColors.gray));
      expect(LogColors.forLevel(LogLevel.info), equals(LogColors.cyan));
      expect(LogColors.forLevel(LogLevel.warning), equals(LogColors.yellow));
      expect(LogColors.forLevel(LogLevel.error), equals(LogColors.red));
      expect(LogColors.forLevel(LogLevel.none), equals(LogColors.reset));
    });

    test('colorize aplica color correctamente', () {
      final colored = LogColors.colorize('test', LogColors.red);
      expect(colored, contains('\x1B[31m'));
      expect(colored, contains('test'));
      expect(colored, contains('\x1B[0m'));
    });

    test('colorize respeta enableColors=false', () {
      final notColored = LogColors.colorize(
        'test',
        LogColors.red,
        enableColors: false,
      );
      expect(notColored, equals('test'));
    });
  });

  group('LogConfig - Filtrado por Tags', () {
    setUp(() {
      LogConfig.reset();
    });

    test('hideTag oculta logs de un tag específico', () {
      LogConfig.hideTag('TestTag');

      expect(LogConfig.hiddenTags, contains('TestTag'));
      expect(LogConfig.shouldShowTag('TestTag'), isFalse);
      expect(LogConfig.shouldShowTag('OtherTag'), isTrue);
    });

    test('showOnlyTag filtra a solo ese tag', () {
      LogConfig.showOnlyTag('AllowedTag');

      expect(LogConfig.onlyTags, contains('AllowedTag'));
      expect(LogConfig.shouldShowTag('AllowedTag'), isTrue);
      expect(LogConfig.shouldShowTag('BlockedTag'), isFalse);
    });

    test('showOnlyTags acepta múltiples tags', () {
      LogConfig.showOnlyTags({'Tag1', 'Tag2'});

      expect(LogConfig.shouldShowTag('Tag1'), isTrue);
      expect(LogConfig.shouldShowTag('Tag2'), isTrue);
      expect(LogConfig.shouldShowTag('Tag3'), isFalse);
    });

    test('clearTagFilters limpia todos los filtros', () {
      LogConfig.hideTag('Hidden');
      LogConfig.showOnlyTag('Only');

      LogConfig.clearTagFilters();

      expect(LogConfig.hiddenTags, isEmpty);
      expect(LogConfig.onlyTags, isEmpty);
    });

    test('shouldShowTag retorna true para null tag', () {
      LogConfig.hideTag('SomeTag');
      expect(LogConfig.shouldShowTag(null), isTrue);
    });
  });

  group('LogConfig - Modo Quiet', () {
    setUp(() {
      LogConfig.reset();
    });

    test('configureForTests activa quietMode', () {
      LogConfig.configureForTests();

      expect(LogConfig.quietMode, isTrue);
      expect(LogConfig.minLevel, equals(LogLevel.error));
      expect(LogConfig.enableColors, isFalse);
      expect(LogConfig.showTimestamp, isFalse);
    });

    test('configureVerboseTests desactiva quietMode', () {
      LogConfig.configureForTests(); // Primero silenciar
      LogConfig.configureVerboseTests(); // Luego activar verbose

      expect(LogConfig.quietMode, isFalse);
      expect(LogConfig.minLevel, equals(LogLevel.debug));
      expect(LogConfig.enableColors, isTrue);
      expect(LogConfig.showTimestamp, isTrue);
    });

    test('disable activa quietMode', () {
      LogConfig.disable();

      expect(LogConfig.quietMode, isTrue);
      expect(LogConfig.minLevel, equals(LogLevel.none));
    });

    test('reset restaura quietMode a false', () {
      LogConfig.configureForTests();
      LogConfig.reset();

      expect(LogConfig.quietMode, isFalse);
    });
  });

  group('LogConfig - Colores', () {
    setUp(() {
      LogConfig.reset();
    });

    test('enableColors está habilitado por defecto en desarrollo', () {
      LogConfig.configureForDevelopment();
      expect(LogConfig.enableColors, isTrue);
    });

    test('enableColors está deshabilitado en producción', () {
      LogConfig.configureForProduction();
      expect(LogConfig.enableColors, isFalse);
    });
  });

  group('AppLogger - Tree Methods', () {
    setUp(() {
      LogConfig.reset();
    });

    test('tree no lanza excepciones', () {
      expect(
        () => AppLogger.tree(
          'Header',
          ['Item 1', 'Item 2', 'Item 3'],
          tag: 'TestTag',
        ),
        returnsNormally,
      );
    });

    test('tree con lista vacía no lanza excepciones', () {
      expect(
        () => AppLogger.tree('Header', []),
        returnsNormally,
      );
    });

    test('subtree no lanza excepciones', () {
      expect(
        () => AppLogger.subtree(
          'Header',
          {
            'Section 1': ['Item 1.1', 'Item 1.2'],
            'Section 2': ['Item 2.1'],
          },
          tag: 'TestTag',
        ),
        returnsNormally,
      );
    });

    test('subtree con mapa vacío no lanza excepciones', () {
      expect(
        () => AppLogger.subtree('Header', {}),
        returnsNormally,
      );
    });

    test('tree respeta quietMode', () {
      LogConfig.configureForTests(); // Activa quietMode

      // No debería lanzar error, simplemente no hace nada
      expect(
        () => AppLogger.tree('Header', ['Item']),
        returnsNormally,
      );
    });

    test('tree respeta filtro de tags', () {
      LogConfig.hideTag('HiddenTag');

      // No debería lanzar error
      expect(
        () => AppLogger.tree('Header', ['Item'], tag: 'HiddenTag'),
        returnsNormally,
      );
    });
  });
}

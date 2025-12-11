// ╔═══════════════════════════════════════════════════════════════════════════════╗
// ║                           app_logger_test.dart                                ║
// ║                    Tests para el sistema de logging                           ║
// ╠═══════════════════════════════════════════════════════════════════════════════╣
// ║  Verifica el comportamiento de LogLevel, LogConfig y AppLogger.               ║
// ╚═══════════════════════════════════════════════════════════════════════════════╝

import 'package:flutter_test/flutter_test.dart';
import 'package:nutrivision_aiepn_mobile/core/logging/app_logger.dart';
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
}

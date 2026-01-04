// ═══════════════════════════════════════════════════════════════════════════════════
// ║                        input_validator_test.dart                                ║
// ║                  Tests para validador de entrada InputValidator                 ║
// ═══════════════════════════════════════════════════════════════════════════════════
// ║  Verifica la validacion y sanitizacion de inputs del usuario.                   ║
// ║  Incluye tests de seguridad para prevenir inyecciones.                          ║
// ═══════════════════════════════════════════════════════════════════════════════════

import 'package:flutter_test/flutter_test.dart';
import 'package:nutrivision_aiepn_mobile/core/security/input_validator.dart';

void main() {
  // ═══════════════════════════════════════════════════════════════════════════
  // TESTS PARA validateEmail
  // ═══════════════════════════════════════════════════════════════════════════

  group('validateEmail', () {
    group('emails validos', () {
      test('acepta email basico', () {
        expect(InputValidator.validateEmail('test@example.com'), isNull);
      });

      test('acepta email con subdominios', () {
        expect(InputValidator.validateEmail('user@mail.example.com'), isNull);
      });

      test('acepta email con numeros', () {
        expect(InputValidator.validateEmail('user123@example.com'), isNull);
      });

      test('acepta email con punto en local part', () {
        expect(InputValidator.validateEmail('user.name@example.com'), isNull);
      });

      test('acepta email con guion bajo', () {
        expect(InputValidator.validateEmail('user_name@example.com'), isNull);
      });

      test('acepta email con mas en local part', () {
        expect(InputValidator.validateEmail('user+tag@example.com'), isNull);
      });

      test('ignora espacios al inicio y final', () {
        expect(InputValidator.validateEmail('  test@example.com  '), isNull);
      });
    });

    group('emails invalidos', () {
      test('rechaza null', () {
        expect(InputValidator.validateEmail(null), isNotNull);
        expect(InputValidator.validateEmail(null), contains('requerido'));
      });

      test('rechaza string vacio', () {
        expect(InputValidator.validateEmail(''), isNotNull);
        expect(InputValidator.validateEmail(''), contains('requerido'));
      });

      test('rechaza string con solo espacios', () {
        expect(InputValidator.validateEmail('   '), isNotNull);
      });

      test('rechaza email sin @', () {
        expect(InputValidator.validateEmail('testexample.com'), isNotNull);
        expect(InputValidator.validateEmail('testexample.com'),
            contains('válido'));
      });

      test('rechaza email sin dominio', () {
        expect(InputValidator.validateEmail('test@'), isNotNull);
      });

      test('rechaza email sin TLD', () {
        expect(InputValidator.validateEmail('test@example'), isNotNull);
      });

      test('rechaza email con TLD muy corto', () {
        expect(InputValidator.validateEmail('test@example.c'), isNotNull);
      });

      test('rechaza email demasiado largo', () {
        final longEmail = 'a' * 300 + '@example.com';
        expect(InputValidator.validateEmail(longEmail), isNotNull);
        expect(InputValidator.validateEmail(longEmail), contains('largo'));
      });

      test('rechaza email con local part muy largo', () {
        final longLocal = 'a' * 65 + '@example.com';
        expect(InputValidator.validateEmail(longLocal), isNotNull);
      });
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // TESTS PARA validatePassword
  // ═══════════════════════════════════════════════════════════════════════════

  group('validatePassword', () {
    group('contrasenas validas', () {
      test('acepta contrasena con todos los requisitos', () {
        expect(InputValidator.validatePassword('Password123'), isNull);
      });

      test('acepta contrasena con caracteres especiales', () {
        expect(InputValidator.validatePassword('Password123!@#'), isNull);
      });

      test('acepta contrasena de exactamente 8 caracteres', () {
        expect(InputValidator.validatePassword('Passw0rd'), isNull);
      });
    });

    group('contrasenas invalidas', () {
      test('rechaza null', () {
        expect(InputValidator.validatePassword(null), isNotNull);
        expect(InputValidator.validatePassword(null), contains('requerida'));
      });

      test('rechaza string vacio', () {
        expect(InputValidator.validatePassword(''), isNotNull);
        expect(InputValidator.validatePassword(''), contains('requerida'));
      });

      test('rechaza contrasena muy corta', () {
        expect(InputValidator.validatePassword('Pass1'), isNotNull);
        expect(
            InputValidator.validatePassword('Pass1'), contains('8 caracteres'));
      });

      test('rechaza contrasena demasiado larga', () {
        final longPassword = 'Aa1${'a' * 130}';
        expect(InputValidator.validatePassword(longPassword), isNotNull);
        expect(
            InputValidator.validatePassword(longPassword), contains('larga'));
      });

      test('rechaza contrasena sin mayuscula', () {
        expect(InputValidator.validatePassword('password123'), isNotNull);
        expect(InputValidator.validatePassword('password123'),
            contains('mayúscula'));
      });

      test('rechaza contrasena sin minuscula', () {
        expect(InputValidator.validatePassword('PASSWORD123'), isNotNull);
        expect(InputValidator.validatePassword('PASSWORD123'),
            contains('minúscula'));
      });

      test('rechaza contrasena sin numero', () {
        expect(InputValidator.validatePassword('PasswordAbc'), isNotNull);
        expect(
            InputValidator.validatePassword('PasswordAbc'), contains('número'));
      });
    });

    group('minLength personalizado', () {
      test('acepta minLength diferente', () {
        expect(InputValidator.validatePassword('Pass1', minLength: 5), isNull);
      });

      test('rechaza si no cumple minLength personalizado', () {
        expect(InputValidator.validatePassword('Pa1', minLength: 5), isNotNull);
      });
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // TESTS PARA validatePasswordMatch
  // ═══════════════════════════════════════════════════════════════════════════

  group('validatePasswordMatch', () {
    test('acepta contrasenas que coinciden', () {
      expect(InputValidator.validatePasswordMatch('Password123', 'Password123'),
          isNull);
    });

    test('rechaza null', () {
      expect(
          InputValidator.validatePasswordMatch(null, 'Password123'), isNotNull);
      expect(InputValidator.validatePasswordMatch(null, 'Password123'),
          contains('Confirma'));
    });

    test('rechaza string vacio', () {
      expect(
          InputValidator.validatePasswordMatch('', 'Password123'), isNotNull);
    });

    test('rechaza contrasenas diferentes', () {
      expect(InputValidator.validatePasswordMatch('Password123', 'Password456'),
          isNotNull);
      expect(InputValidator.validatePasswordMatch('Password123', 'Password456'),
          contains('no coinciden'));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // TESTS PARA validateName
  // ═══════════════════════════════════════════════════════════════════════════

  group('validateName', () {
    group('nombres validos', () {
      test('acepta nombre simple', () {
        expect(InputValidator.validateName('Juan'), isNull);
      });

      test('acepta nombre compuesto', () {
        expect(InputValidator.validateName('Juan Carlos'), isNull);
      });

      test('acepta nombre con acentos', () {
        expect(InputValidator.validateName('Jose Maria'), isNull);
        expect(InputValidator.validateName('Maria'), isNull);
      });

      test('acepta nombre con n con tilde', () {
        expect(InputValidator.validateName('Nino Perez'), isNull);
      });

      test('acepta nombre con apostrofo', () {
        expect(InputValidator.validateName("O'Connor"), isNull);
      });

      test('acepta nombre con guion', () {
        expect(InputValidator.validateName('Ana-Maria'), isNull);
      });
    });

    group('nombres invalidos', () {
      test('rechaza null', () {
        expect(InputValidator.validateName(null), isNotNull);
        expect(InputValidator.validateName(null), contains('requerido'));
      });

      test('rechaza string vacio', () {
        expect(InputValidator.validateName(''), isNotNull);
      });

      test('rechaza nombre muy corto', () {
        expect(InputValidator.validateName('A'), isNotNull);
        expect(InputValidator.validateName('A'), contains('2 caracteres'));
      });

      test('rechaza nombre muy largo', () {
        final longName = 'A' * 101;
        expect(InputValidator.validateName(longName), isNotNull);
        expect(InputValidator.validateName(longName), contains('largo'));
      });

      test('rechaza nombre con numeros', () {
        expect(InputValidator.validateName('Juan123'), isNotNull);
        expect(
            InputValidator.validateName('Juan123'), contains('no permitidos'));
      });

      test('rechaza nombre con caracteres especiales', () {
        expect(InputValidator.validateName('Juan@#\$'), isNotNull);
      });
    });

    group('seguridad', () {
      test('rechaza nombre con script HTML', () {
        expect(InputValidator.validateName('<script>alert("xss")</script>'),
            isNotNull);
        expect(InputValidator.validateName('<script>alert("xss")</script>'),
            contains('no permitido'));
      });

      test('rechaza nombre con inyeccion SQL', () {
        expect(
            InputValidator.validateName("'; DROP TABLE users; --"), isNotNull);
      });
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // TESTS PARA validateNumber
  // ═══════════════════════════════════════════════════════════════════════════

  group('validateNumber', () {
    test('acepta numero valido dentro del rango', () {
      expect(InputValidator.validateNumber('50', min: 0, max: 100), isNull);
    });

    test('acepta numero decimal', () {
      expect(InputValidator.validateNumber('50.5', min: 0, max: 100), isNull);
    });

    test('acepta valor en limite inferior', () {
      expect(InputValidator.validateNumber('0', min: 0, max: 100), isNull);
    });

    test('acepta valor en limite superior', () {
      expect(InputValidator.validateNumber('100', min: 0, max: 100), isNull);
    });

    test('rechaza valor fuera de rango', () {
      expect(InputValidator.validateNumber('150', min: 0, max: 100), isNotNull);
      expect(InputValidator.validateNumber('150', min: 0, max: 100),
          contains('entre'));
    });

    test('rechaza valor menor al minimo', () {
      expect(InputValidator.validateNumber('-5', min: 0, max: 100), isNotNull);
    });

    test('rechaza texto no numerico', () {
      expect(InputValidator.validateNumber('abc', min: 0, max: 100), isNotNull);
      expect(InputValidator.validateNumber('abc', min: 0, max: 100),
          contains('número válido'));
    });

    test('acepta null si no es requerido', () {
      expect(InputValidator.validateNumber(null, min: 0, max: 100), isNull);
    });

    test('rechaza null si es requerido', () {
      expect(
          InputValidator.validateNumber(null, min: 0, max: 100, required: true),
          isNotNull);
    });

    test('usa fieldName en mensaje de error', () {
      expect(
          InputValidator.validateNumber(null,
              min: 0, max: 100, required: true, fieldName: 'peso'),
          contains('peso'));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // TESTS PARA validateInteger
  // ═══════════════════════════════════════════════════════════════════════════

  group('validateInteger', () {
    test('acepta entero valido dentro del rango', () {
      expect(InputValidator.validateInteger('50', min: 0, max: 100), isNull);
    });

    test('rechaza decimal', () {
      expect(
          InputValidator.validateInteger('50.5', min: 0, max: 100), isNotNull);
      expect(InputValidator.validateInteger('50.5', min: 0, max: 100),
          contains('entero'));
    });

    test('acepta valor en limite inferior', () {
      expect(InputValidator.validateInteger('0', min: 0, max: 100), isNull);
    });

    test('rechaza valor fuera de rango', () {
      expect(
          InputValidator.validateInteger('150', min: 0, max: 100), isNotNull);
    });

    test('acepta null si no es requerido', () {
      expect(InputValidator.validateInteger(null, min: 0, max: 100), isNull);
    });

    test('rechaza null si es requerido', () {
      expect(
          InputValidator.validateInteger(null,
              min: 0, max: 100, required: true),
          isNotNull);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // TESTS PARA validateText
  // ═══════════════════════════════════════════════════════════════════════════

  group('validateText', () {
    test('acepta texto valido', () {
      expect(InputValidator.validateText('Texto normal'), isNull);
    });

    test('acepta null si no es requerido', () {
      expect(InputValidator.validateText(null), isNull);
    });

    test('rechaza null si es requerido', () {
      expect(InputValidator.validateText(null, required: true), isNotNull);
    });

    test('rechaza texto muy corto', () {
      expect(InputValidator.validateText('a', minLength: 5), isNotNull);
      expect(InputValidator.validateText('a', minLength: 5),
          contains('5 caracteres'));
    });

    test('rechaza texto muy largo', () {
      final longText = 'a' * 600;
      expect(InputValidator.validateText(longText, maxLength: 500), isNotNull);
      expect(InputValidator.validateText(longText, maxLength: 500),
          contains('máximo'));
    });

    test('rechaza texto con scripts', () {
      expect(InputValidator.validateText('<script>alert("xss")</script>'),
          isNotNull);
      expect(InputValidator.validateText('<script>alert("xss")</script>'),
          contains('no permitido'));
    });

    test('usa fieldName en mensaje de error', () {
      expect(
          InputValidator.validateText(null,
              required: true, fieldName: 'descripcion'),
          contains('descripcion'));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // TESTS PARA sanitize
  // ═══════════════════════════════════════════════════════════════════════════

  group('sanitize', () {
    test('remueve caracteres de control', () {
      final sanitized = InputValidator.sanitize('test\x00\x01\x02');
      expect(sanitized, 'test');
    });

    test('remueve scripts', () {
      final sanitized =
          InputValidator.sanitize('<script>alert("xss")</script>');
      expect(sanitized.contains('script'), isFalse);
    });

    test('escapa caracteres HTML', () {
      final sanitized = InputValidator.sanitize('<div>test</div>');
      expect(sanitized, contains('&lt;'));
      expect(sanitized, contains('&gt;'));
    });

    test('escapa ampersand', () {
      final sanitized = InputValidator.sanitize('test & test');
      expect(sanitized, contains('&amp;'));
    });

    test('escapa comillas', () {
      final sanitized = InputValidator.sanitize('test "quoted"');
      expect(sanitized, contains('&quot;'));
    });

    test('limita longitud a 10000 caracteres', () {
      final longInput = 'a' * 15000;
      final sanitized = InputValidator.sanitize(longInput);
      expect(sanitized.length, lessThanOrEqualTo(10000));
    });

    test('trim espacios al inicio y final', () {
      final sanitized = InputValidator.sanitize('  test  ');
      expect(sanitized, 'test');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // TESTS PARA sanitizeForFirestore
  // ═══════════════════════════════════════════════════════════════════════════

  group('sanitizeForFirestore', () {
    test('remueve slash', () {
      final sanitized = InputValidator.sanitizeForFirestore('path/to/doc');
      expect(sanitized.contains('/'), isFalse);
    });

    test('remueve corchetes', () {
      final sanitized = InputValidator.sanitizeForFirestore('test[0]');
      expect(sanitized.contains('['), isFalse);
      expect(sanitized.contains(']'), isFalse);
    });

    test('remueve punto', () {
      final sanitized = InputValidator.sanitizeForFirestore('test.field');
      expect(sanitized.contains('.'), isFalse);
    });

    test('remueve hash', () {
      final sanitized = InputValidator.sanitizeForFirestore('test#field');
      expect(sanitized.contains('#'), isFalse);
    });

    test('remueve dolar', () {
      final sanitized = InputValidator.sanitizeForFirestore('test\$field');
      expect(sanitized.contains('\$'), isFalse);
    });

    test('aplica sanitizacion basica primero', () {
      final sanitized =
          InputValidator.sanitizeForFirestore('<script>test</script>');
      expect(sanitized.contains('script'), isFalse);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // TESTS PARA sanitizeEmail
  // ═══════════════════════════════════════════════════════════════════════════

  group('sanitizeEmail', () {
    test('convierte a minusculas', () {
      final sanitized = InputValidator.sanitizeEmail('TEST@EXAMPLE.COM');
      expect(sanitized, 'test@example.com');
    });

    test('trim espacios', () {
      final sanitized = InputValidator.sanitizeEmail('  test@example.com  ');
      expect(sanitized, 'test@example.com');
    });

    test('remueve caracteres de control', () {
      final sanitized = InputValidator.sanitizeEmail('test\x00@example.com');
      expect(sanitized, 'test@example.com');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // TESTS PARA sanitizeName
  // ═══════════════════════════════════════════════════════════════════════════

  group('sanitizeName', () {
    test('trim espacios', () {
      final sanitized = InputValidator.sanitizeName('  Juan  ');
      expect(sanitized, 'Juan');
    });

    test('normaliza espacios multiples', () {
      final sanitized = InputValidator.sanitizeName('Juan    Carlos');
      expect(sanitized, 'Juan Carlos');
    });

    test('remueve caracteres de control', () {
      final sanitized = InputValidator.sanitizeName('Juan\x00Carlos');
      expect(sanitized, 'JuanCarlos');
    });

    test('remueve scripts', () {
      final sanitized =
          InputValidator.sanitizeName('Juan<script>alert(1)</script>');
      expect(sanitized.contains('script'), isFalse);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // TESTS PARA StringSanitization extension
  // ═══════════════════════════════════════════════════════════════════════════

  group('StringSanitization extension', () {
    test('sanitized aplica sanitize', () {
      expect('<script>test</script>'.sanitized.contains('script'), isFalse);
    });

    test('sanitizedForFirestore aplica sanitizeForFirestore', () {
      expect('path/to/doc'.sanitizedForFirestore.contains('/'), isFalse);
    });

    test('sanitizedEmail aplica sanitizeEmail', () {
      expect('TEST@EXAMPLE.COM'.sanitizedEmail, 'test@example.com');
    });

    test('sanitizedName aplica sanitizeName', () {
      expect('  Juan  Carlos  '.sanitizedName, 'Juan Carlos');
    });

    test('isValidEmail verifica email', () {
      expect('test@example.com'.isValidEmail, isTrue);
      expect('invalid'.isValidEmail, isFalse);
    });

    test('isValidName verifica nombre', () {
      expect('Juan Carlos'.isValidName, isTrue);
      expect('Juan123'.isValidName, isFalse);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // TESTS DE SEGURIDAD ADICIONALES
  // ═══════════════════════════════════════════════════════════════════════════

  group('Seguridad - Inyecciones', () {
    test('detecta javascript: protocol', () {
      final sanitized = InputValidator.sanitize('javascript:alert(1)');
      expect(sanitized.contains('javascript:'), isFalse);
    });

    test('detecta event handlers', () {
      final sanitized = InputValidator.sanitize('onclick=alert(1)');
      expect(sanitized.contains('onclick'), isFalse);
    });

    test('detecta SQL SELECT', () {
      final result = InputValidator.validateName('SELECT * FROM users');
      expect(result, isNotNull);
    });

    test('detecta SQL DROP', () {
      final result = InputValidator.validateName('DROP TABLE users');
      expect(result, isNotNull);
    });

    test('detecta SQL comment injection', () {
      final result = InputValidator.validateName("'; -- comment");
      expect(result, isNotNull);
    });

    test('detecta SQL OR injection', () {
      final result = InputValidator.validateName("' OR 1=1");
      expect(result, isNotNull);
    });
  });
}

// ╔═══════════════════════════════════════════════════════════════════════════════╗
// ║                          input_validator.dart                                 ║
// ║                  Validadores de entrada para seguridad                        ║
// ╠═══════════════════════════════════════════════════════════════════════════════╣
// ║  Provee validación y sanitización de inputs del usuario.                      ║
// ║  Previene inyecciones, XSS y otros ataques de seguridad.                      ║
// ╚═══════════════════════════════════════════════════════════════════════════════╝

/// Clase de utilidades para validación de inputs.
///
/// Proporciona métodos estáticos para:
/// - Validar formatos (email, teléfono, etc.)
/// - Sanitizar strings (remover caracteres peligrosos)
/// - Validar rangos numéricos
/// - Validar longitudes de texto
abstract class InputValidator {
  // ═══════════════════════════════════════════════════════════════════════════
  // PATRONES REGEX
  // ═══════════════════════════════════════════════════════════════════════════

  /// Patrón para email válido (RFC 5322 simplificado).
  static final RegExp _emailPattern = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  /// Patrón para nombre válido (letras, espacios, acentos).
  static final RegExp _namePattern = RegExp(
    r"^[a-zA-ZáéíóúüñÁÉÍÓÚÜÑ\s'-]+$",
  );

  /// Patrón para detectar scripts maliciosos.
  static final RegExp _scriptPattern = RegExp(
    r'<script[^>]*>.*?</script>|javascript:|on\w+\s*=',
    caseSensitive: false,
  );

  /// Patrón para detectar caracteres de control.
  static final RegExp _controlCharsPattern = RegExp(
    r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]',
  );

  /// Patrón para detectar inyección SQL básica.
  static final RegExp _sqlInjectionPattern = RegExp(
    r"(\b(SELECT|INSERT|UPDATE|DELETE|DROP|UNION|ALTER|CREATE)\b)|(';\s*--)|(\bOR\b\s+\d+\s*=\s*\d+)",
    caseSensitive: false,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // VALIDADORES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Valida un email.
  ///
  /// Retorna `null` si es válido, mensaje de error si no lo es.
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El email es requerido';
    }

    final trimmed = value.trim().toLowerCase();

    if (trimmed.length > 254) {
      return 'El email es demasiado largo';
    }

    if (!_emailPattern.hasMatch(trimmed)) {
      return 'Ingresa un email válido';
    }

    // Verificar partes del email
    final parts = trimmed.split('@');
    if (parts[0].length > 64 || parts[1].length > 253) {
      return 'El email no tiene un formato válido';
    }

    return null;
  }

  /// Valida una contraseña con requisitos de seguridad.
  ///
  /// Requisitos:
  /// - Mínimo 8 caracteres
  /// - Al menos una mayúscula
  /// - Al menos una minúscula
  /// - Al menos un número
  static String? validatePassword(String? value, {int minLength = 8}) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es requerida';
    }

    if (value.length < minLength) {
      return 'La contraseña debe tener al menos $minLength caracteres';
    }

    if (value.length > 128) {
      return 'La contraseña es demasiado larga';
    }

    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Debe incluir al menos una mayúscula';
    }

    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Debe incluir al menos una minúscula';
    }

    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Debe incluir al menos un número';
    }

    return null;
  }

  /// Valida que las contraseñas coincidan.
  static String? validatePasswordMatch(String? value, String? original) {
    if (value == null || value.isEmpty) {
      return 'Confirma tu contraseña';
    }

    if (value != original) {
      return 'Las contraseñas no coinciden';
    }

    return null;
  }

  /// Valida un nombre de persona.
  static String? validateName(String? value,
      {int minLength = 2, int maxLength = 100}) {
    if (value == null || value.trim().isEmpty) {
      return 'El nombre es requerido';
    }

    final trimmed = value.trim();

    if (trimmed.length < minLength) {
      return 'El nombre debe tener al menos $minLength caracteres';
    }

    if (trimmed.length > maxLength) {
      return 'El nombre es demasiado largo';
    }

    if (!_namePattern.hasMatch(trimmed)) {
      return 'El nombre contiene caracteres no permitidos';
    }

    if (_containsMaliciousContent(trimmed)) {
      return 'El nombre contiene contenido no permitido';
    }

    return null;
  }

  /// Valida un número dentro de un rango.
  static String? validateNumber(
    String? value, {
    required double min,
    required double max,
    bool required = false,
    String? fieldName,
  }) {
    final name = fieldName ?? 'valor';

    if (value == null || value.trim().isEmpty) {
      return required ? 'El $name es requerido' : null;
    }

    final number = double.tryParse(value.trim());
    if (number == null) {
      return 'Ingresa un número válido';
    }

    if (number < min || number > max) {
      return 'El $name debe estar entre $min y $max';
    }

    return null;
  }

  /// Valida un entero dentro de un rango.
  static String? validateInteger(
    String? value, {
    required int min,
    required int max,
    bool required = false,
    String? fieldName,
  }) {
    final name = fieldName ?? 'valor';

    if (value == null || value.trim().isEmpty) {
      return required ? 'El $name es requerido' : null;
    }

    final number = int.tryParse(value.trim());
    if (number == null) {
      return 'Ingresa un número entero válido';
    }

    if (number < min || number > max) {
      return 'El $name debe estar entre $min y $max';
    }

    return null;
  }

  /// Valida texto genérico con límites de longitud.
  static String? validateText(
    String? value, {
    int minLength = 0,
    int maxLength = 500,
    bool required = false,
    String? fieldName,
  }) {
    final name = fieldName ?? 'campo';

    if (value == null || value.trim().isEmpty) {
      return required ? 'El $name es requerido' : null;
    }

    final trimmed = value.trim();

    if (trimmed.length < minLength) {
      return 'El $name debe tener al menos $minLength caracteres';
    }

    if (trimmed.length > maxLength) {
      return 'El $name es demasiado largo (máximo $maxLength caracteres)';
    }

    if (_containsMaliciousContent(trimmed)) {
      return 'El $name contiene contenido no permitido';
    }

    return null;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SANITIZACIÓN
  // ═══════════════════════════════════════════════════════════════════════════

  /// Sanitiza un string removiendo caracteres peligrosos.
  ///
  /// - Remueve scripts HTML/JavaScript
  /// - Remueve caracteres de control
  /// - Escapa caracteres HTML básicos
  static String sanitize(String input) {
    String result = input;

    // Remover caracteres de control
    result = result.replaceAll(_controlCharsPattern, '');

    // Remover scripts
    result = result.replaceAll(_scriptPattern, '');

    // Escapar caracteres HTML básicos
    result = _escapeHtml(result);

    // Limitar longitud máxima
    if (result.length > 10000) {
      result = result.substring(0, 10000);
    }

    return result.trim();
  }

  /// Sanitiza específicamente para uso en Firestore.
  ///
  /// Firestore no permite ciertos caracteres en claves.
  static String sanitizeForFirestore(String input) {
    String result = sanitize(input);

    // Remover caracteres no permitidos en Firestore paths
    result = result.replaceAll(RegExp(r'[/\[\].#$]'), '');

    return result;
  }

  /// Sanitiza un email.
  static String sanitizeEmail(String email) {
    return email.trim().toLowerCase().replaceAll(_controlCharsPattern, '');
  }

  /// Sanitiza un nombre.
  static String sanitizeName(String name) {
    String result = name.trim();

    // Remover caracteres de control
    result = result.replaceAll(_controlCharsPattern, '');

    // Remover HTML/scripts
    result = result.replaceAll(_scriptPattern, '');

    // Normalizar espacios múltiples
    result = result.replaceAll(RegExp(r'\s+'), ' ');

    return result;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS PRIVADOS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Verifica si el contenido contiene patrones maliciosos.
  static bool _containsMaliciousContent(String value) {
    // Verificar scripts
    if (_scriptPattern.hasMatch(value)) {
      return true;
    }

    // Verificar inyección SQL básica
    if (_sqlInjectionPattern.hasMatch(value)) {
      return true;
    }

    // Verificar caracteres de control
    if (_controlCharsPattern.hasMatch(value)) {
      return true;
    }

    return false;
  }

  /// Escapa caracteres HTML básicos.
  static String _escapeHtml(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }
}

/// Extensión para strings con métodos de sanitización.
extension StringSanitization on String {
  /// Sanitiza el string.
  String get sanitized => InputValidator.sanitize(this);

  /// Sanitiza para Firestore.
  String get sanitizedForFirestore => InputValidator.sanitizeForFirestore(this);

  /// Sanitiza como email.
  String get sanitizedEmail => InputValidator.sanitizeEmail(this);

  /// Sanitiza como nombre.
  String get sanitizedName => InputValidator.sanitizeName(this);

  /// Verifica si es un email válido.
  bool get isValidEmail => InputValidator.validateEmail(this) == null;

  /// Verifica si es un nombre válido.
  bool get isValidName => InputValidator.validateName(this) == null;
}

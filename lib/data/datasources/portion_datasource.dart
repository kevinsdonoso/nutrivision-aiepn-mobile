// ╔═══════════════════════════════════════════════════════════════════════════════╗
// ║                         portion_datasource.dart                               ║
// ║              Datasource para cargar porciones estándar                        ║
// ╠═══════════════════════════════════════════════════════════════════════════════╣
// ║  Carga y parsea el archivo JSON de porciones estándar desde los assets.       ║
// ║  Proporciona equivalencias de porciones comunes en gramos.                    ║
// ╚═══════════════════════════════════════════════════════════════════════════════╝

import 'dart:convert';

import 'package:flutter/services.dart';

import '../../core/exceptions/app_exceptions.dart';
import '../models/standard_portion.dart';

/// Datasource para acceder a porciones estándar desde assets.
///
/// Carga el archivo JSON de porciones estándar y lo parsea a objetos Dart.
///
/// Ejemplo de uso:
/// ```dart
/// final datasource = PortionDatasource();
/// final portions = await datasource.loadPortionData();
/// print('Cargadas porciones para ${portions.length} ingredientes');
/// ```
class PortionDatasource {
  // ═══════════════════════════════════════════════════════════════════════════
  // CONSTANTES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Ruta del archivo JSON en assets.
  static const String assetPath = 'assets/data/standard_portions.json';

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS PÚBLICOS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Carga las porciones estándar desde el archivo JSON.
  ///
  /// Retorna un mapa de ingrediente → lista de porciones.
  ///
  /// Formato esperado del JSON:
  /// ```json
  /// {
  ///   "tomate": [
  ///     {"name": "1 unidad pequeña", "grams": 90},
  ///     {"name": "1 unidad mediana", "grams": 150}
  ///   ],
  ///   "queso_mozzarella": [...]
  /// }
  /// ```
  ///
  /// Throws [DatabaseException] si el archivo no existe o no se puede leer.
  Future<Map<String, List<StandardPortion>>> loadPortionData() async {
    try {
      // Cargar el archivo JSON desde assets
      final jsonString = await rootBundle.loadString(assetPath);

      // Parsear JSON
      final jsonMap = json.decode(jsonString) as Map<String, dynamic>;

      // Convertir a mapa de porciones
      return _parsePortionData(jsonMap);
    } on FormatException catch (e, stackTrace) {
      throw DatabaseException(
        message: 'JSON malformado en $assetPath: ${e.message}',
        originalError: e,
        stackTrace: stackTrace,
      );
    } catch (e, stackTrace) {
      throw DatabaseException(
        message: 'Error cargando datos de porciones: $e',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Verifica si el archivo de datos existe.
  ///
  /// Útil para diagnóstico antes de intentar cargar.
  Future<bool> dataFileExists() async {
    try {
      await rootBundle.loadString(assetPath);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS PRIVADOS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Parsea el mapa JSON a objetos StandardPortion.
  Map<String, List<StandardPortion>> _parsePortionData(
    Map<String, dynamic> jsonMap,
  ) {
    final result = <String, List<StandardPortion>>{};

    for (final entry in jsonMap.entries) {
      final ingredientLabel = entry.key;
      final portionsJson = entry.value as List<dynamic>;

      final portions = portionsJson
          .map((portionJson) => StandardPortion.fromJson(
                portionJson as Map<String, dynamic>,
                ingredientLabel,
              ))
          .toList();

      result[ingredientLabel] = portions;
    }

    return result;
  }
}

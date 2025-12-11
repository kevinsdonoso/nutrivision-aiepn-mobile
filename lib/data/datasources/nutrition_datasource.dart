// ╔═══════════════════════════════════════════════════════════════════════════════╗
// ║                         nutrition_datasource.dart                             ║
// ║              Datasource para cargar datos nutricionales                       ║
// ╠═══════════════════════════════════════════════════════════════════════════════╣
// ║  Carga y parsea el archivo JSON de nutrición desde los assets.                ║
// ║  Fuente de datos: USDA FoodData Central.                                      ║
// ╚═══════════════════════════════════════════════════════════════════════════════╝

import 'dart:convert';

import 'package:flutter/services.dart';

import '../../core/exceptions/app_exceptions.dart';
import '../models/nutrition_data.dart';

/// Datasource para acceder a datos nutricionales desde assets.
///
/// Carga el archivo JSON de nutrición y lo parsea a objetos Dart.
///
/// Ejemplo de uso:
/// ```dart
/// final datasource = NutritionDatasource();
/// final data = await datasource.loadNutritionData();
/// print('Cargados ${data.totalCount} alimentos');
/// ```
class NutritionDatasource {
  // ═══════════════════════════════════════════════════════════════════════════
  // CONSTANTES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Ruta del archivo JSON en assets.
  static const String assetPath = 'assets/data/nutrition_fdc.json';

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS PÚBLICOS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Carga los datos nutricionales desde el archivo JSON.
  ///
  /// Throws [NutritionDataException] si el archivo no existe o no se puede leer.
  /// Throws [NutritionJsonParseException] si el JSON está malformado.
  Future<NutritionData> loadNutritionData() async {
    try {
      // Cargar el archivo JSON desde assets
      final jsonString = await rootBundle.loadString(assetPath);

      // Parsear JSON
      final jsonMap = json.decode(jsonString) as Map<String, dynamic>;

      // Convertir a modelo
      return NutritionData.fromJson(jsonMap);
    } on FormatException catch (e, stackTrace) {
      throw NutritionJsonParseException(
        message: 'JSON malformado en $assetPath: ${e.message}',
        originalError: e,
        stackTrace: stackTrace,
      );
    } catch (e, stackTrace) {
      throw NutritionDataException(
        message: 'Error cargando datos nutricionales: $e',
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
}

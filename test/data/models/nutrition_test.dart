// ╔═══════════════════════════════════════════════════════════════════════════════╗
// ║                           nutrition_test.dart                                 ║
// ║                   Tests para modelos de nutrición                             ║
// ╠═══════════════════════════════════════════════════════════════════════════════╣
// ║  Verifica el comportamiento de NutrientsPer100g, NutritionInfo               ║
// ║  y NutritionData.                                                             ║
// ╚═══════════════════════════════════════════════════════════════════════════════╝

import 'package:flutter_test/flutter_test.dart';
import 'package:nutrivision_aiepn_mobile/data/models/nutrients_per_100g.dart';
import 'package:nutrivision_aiepn_mobile/data/models/nutrition_info.dart';
import 'package:nutrivision_aiepn_mobile/data/models/nutrition_data.dart';

void main() {
  // ═══════════════════════════════════════════════════════════════════════════
  // TESTS PARA NutrientsPer100g
  // ═══════════════════════════════════════════════════════════════════════════

  group('NutrientsPer100g', () {
    test('constructor crea instancia con valores correctos', () {
      const nutrients = NutrientsPer100g(
        energyKcal: 100,
        proteinG: 10,
        fatG: 5,
        carbohydratesG: 15,
        fiberG: 2,
        sugarsG: 3,
      );

      expect(nutrients.energyKcal, 100);
      expect(nutrients.proteinG, 10);
      expect(nutrients.fatG, 5);
      expect(nutrients.carbohydratesG, 15);
      expect(nutrients.fiberG, 2);
      expect(nutrients.sugarsG, 3);
    });

    test('zero() crea instancia con todos los valores en cero', () {
      const nutrients = NutrientsPer100g.zero();

      expect(nutrients.energyKcal, 0);
      expect(nutrients.proteinG, 0);
      expect(nutrients.fatG, 0);
      expect(nutrients.carbohydratesG, 0);
      expect(nutrients.fiberG, 0);
      expect(nutrients.sugarsG, 0);
      expect(nutrients.isEmpty, isTrue);
    });

    test('fromJson parsea correctamente', () {
      final json = {
        'energy_kcal': 200.0,
        'protein_g': 20.0,
        'fat_g': 10.0,
        'carbohydrates_g': 30.0,
        'fiber_g': 5.0,
        'sugars_g': 8.0,
      };

      final nutrients = NutrientsPer100g.fromJson(json);

      expect(nutrients.energyKcal, 200);
      expect(nutrients.proteinG, 20);
      expect(nutrients.fatG, 10);
      expect(nutrients.carbohydratesG, 30);
      expect(nutrients.fiberG, 5);
      expect(nutrients.sugarsG, 8);
    });

    test('fromJson maneja valores faltantes con cero', () {
      final json = <String, dynamic>{
        'energy_kcal': 100.0,
        // otros campos faltantes
      };

      final nutrients = NutrientsPer100g.fromJson(json);

      expect(nutrients.energyKcal, 100);
      expect(nutrients.proteinG, 0);
      expect(nutrients.fatG, 0);
    });

    test('operador + suma nutrientes correctamente', () {
      const a = NutrientsPer100g(
        energyKcal: 100,
        proteinG: 10,
        fatG: 5,
        carbohydratesG: 15,
        fiberG: 2,
        sugarsG: 3,
      );
      const b = NutrientsPer100g(
        energyKcal: 50,
        proteinG: 5,
        fatG: 3,
        carbohydratesG: 10,
        fiberG: 1,
        sugarsG: 2,
      );

      final result = a + b;

      expect(result.energyKcal, 150);
      expect(result.proteinG, 15);
      expect(result.fatG, 8);
      expect(result.carbohydratesG, 25);
      expect(result.fiberG, 3);
      expect(result.sugarsG, 5);
    });

    test('operador * multiplica nutrientes correctamente', () {
      const nutrients = NutrientsPer100g(
        energyKcal: 100,
        proteinG: 10,
        fatG: 5,
        carbohydratesG: 20,
        fiberG: 2,
        sugarsG: 4,
      );

      final result = nutrients * 1.5;

      expect(result.energyKcal, 150);
      expect(result.proteinG, 15);
      expect(result.fatG, 7.5);
      expect(result.carbohydratesG, 30);
      expect(result.fiberG, 3);
      expect(result.sugarsG, 6);
    });

    test('totalMacros calcula suma correcta', () {
      const nutrients = NutrientsPer100g(
        energyKcal: 100,
        proteinG: 10,
        fatG: 5,
        carbohydratesG: 20,
        fiberG: 2,
        sugarsG: 3,
      );

      expect(nutrients.totalMacros, 35); // 10 + 5 + 20
    });

    test('isEmpty y isNotEmpty funcionan correctamente', () {
      const zero = NutrientsPer100g.zero();
      const nonZero = NutrientsPer100g(
        energyKcal: 1,
        proteinG: 0,
        fatG: 0,
        carbohydratesG: 0,
        fiberG: 0,
        sugarsG: 0,
      );

      expect(zero.isEmpty, isTrue);
      expect(zero.isNotEmpty, isFalse);
      expect(nonZero.isEmpty, isFalse);
      expect(nonZero.isNotEmpty, isTrue);
    });

    test('toJson convierte correctamente', () {
      const nutrients = NutrientsPer100g(
        energyKcal: 100,
        proteinG: 10,
        fatG: 5,
        carbohydratesG: 15,
        fiberG: 2,
        sugarsG: 3,
      );

      final json = nutrients.toJson();

      expect(json['energy_kcal'], 100);
      expect(json['protein_g'], 10);
      expect(json['fat_g'], 5);
      expect(json['carbohydrates_g'], 15);
      expect(json['fiber_g'], 2);
      expect(json['sugars_g'], 3);
    });

    test('copyWith crea copia con valores modificados', () {
      const original = NutrientsPer100g(
        energyKcal: 100,
        proteinG: 10,
        fatG: 5,
        carbohydratesG: 15,
        fiberG: 2,
        sugarsG: 3,
      );

      final copy = original.copyWith(energyKcal: 200, proteinG: 20);

      expect(copy.energyKcal, 200);
      expect(copy.proteinG, 20);
      expect(copy.fatG, 5); // sin cambios
      expect(copy.carbohydratesG, 15); // sin cambios
    });

    test('equality funciona correctamente', () {
      const a = NutrientsPer100g(
        energyKcal: 100,
        proteinG: 10,
        fatG: 5,
        carbohydratesG: 15,
        fiberG: 2,
        sugarsG: 3,
      );
      const b = NutrientsPer100g(
        energyKcal: 100,
        proteinG: 10,
        fatG: 5,
        carbohydratesG: 15,
        fiberG: 2,
        sugarsG: 3,
      );
      const c = NutrientsPer100g(
        energyKcal: 200,
        proteinG: 10,
        fatG: 5,
        carbohydratesG: 15,
        fiberG: 2,
        sugarsG: 3,
      );

      expect(a == b, isTrue);
      expect(a == c, isFalse);
      expect(a.hashCode == b.hashCode, isTrue);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // TESTS PARA NutritionInfo
  // ═══════════════════════════════════════════════════════════════════════════

  group('NutritionInfo', () {
    test('constructor crea instancia correcta', () {
      const info = NutritionInfo(
        label: 'tomate',
        fdcId: 12345,
        fdcDescription: 'Tomatoes, raw',
        matchScore: 95,
        status: NutritionStatus.found,
        isDish: false,
        nutrients: NutrientsPer100g(
          energyKcal: 20,
          proteinG: 0.8,
          fatG: 0.3,
          carbohydratesG: 4,
          fiberG: 1.2,
          sugarsG: 2.6,
        ),
      );

      expect(info.label, 'tomate');
      expect(info.fdcId, 12345);
      expect(info.fdcDescription, 'Tomatoes, raw');
      expect(info.matchScore, 95);
      expect(info.status, NutritionStatus.found);
      expect(info.isDish, isFalse);
    });

    test('notFound() crea instancia con valores por defecto', () {
      const info = NutritionInfo.notFound('unknown');

      expect(info.label, 'unknown');
      expect(info.fdcId, isNull);
      expect(info.matchScore, 0);
      expect(info.status, NutritionStatus.notFound);
      expect(info.isDish, isFalse);
      expect(info.nutrients.isEmpty, isTrue);
    });

    test('fromJsonIngredient parsea correctamente', () {
      final json = {
        'fdc_id': 12345,
        'fdc_description': 'Tomatoes, raw',
        'match_score': 95.0,
        'status': 'found',
        'nutrients_per_100g': {
          'energy_kcal': 20.0,
          'protein_g': 0.8,
          'fat_g': 0.3,
          'carbohydrates_g': 4.0,
          'fiber_g': 1.2,
          'sugars_g': 2.6,
        },
      };

      final info = NutritionInfo.fromJsonIngredient('tomate', json);

      expect(info.label, 'tomate');
      expect(info.fdcId, 12345);
      expect(info.matchScore, 95);
      expect(info.status, NutritionStatus.found);
      expect(info.isDish, isFalse);
    });

    test('fromJsonDish parsea correctamente', () {
      final json = {
        'components': {
          'tomate': 40,
          'queso': 35,
          'albahaca': 5,
        },
        'missing_components': <String>[],
        'nutrients_per_100g': {
          'energy_kcal': 200.0,
          'protein_g': 8.0,
          'fat_g': 17.0,
          'carbohydrates_g': 4.0,
          'fiber_g': 1.0,
          'sugars_g': 1.0,
        },
      };

      final info = NutritionInfo.fromJsonDish('caprese_salad', json);

      expect(info.label, 'caprese_salad');
      expect(info.isDish, isTrue);
      expect(info.matchScore, 100); // Platos siempre 100%
      expect(info.components, isNotNull);
      expect(info.components!['tomate'], 40);
      expect(info.componentCount, 3);
    });

    test('isHighMatch identifica coincidencia alta', () {
      const high = NutritionInfo(
        label: 'test',
        matchScore: 85,
        status: NutritionStatus.found,
        isDish: false,
        nutrients: NutrientsPer100g.zero(),
      );
      const medium = NutritionInfo(
        label: 'test',
        matchScore: 70,
        status: NutritionStatus.found,
        isDish: false,
        nutrients: NutrientsPer100g.zero(),
      );

      expect(high.isHighMatch, isTrue);
      expect(medium.isHighMatch, isFalse);
      expect(medium.isMediumMatch, isTrue);
    });

    test('displayLabel formatea correctamente', () {
      const info = NutritionInfo(
        label: 'queso_mozzarella',
        matchScore: 100,
        status: NutritionStatus.found,
        isDish: false,
        nutrients: NutrientsPer100g.zero(),
      );

      expect(info.displayLabel, 'Queso Mozzarella');
    });

    test('hasNutritionData verifica status correctamente', () {
      const found = NutritionInfo(
        label: 'test',
        matchScore: 90,
        status: NutritionStatus.found,
        isDish: false,
        nutrients: NutrientsPer100g.zero(),
      );
      const notFound = NutritionInfo.notFound('test');

      expect(found.hasNutritionData, isTrue);
      expect(notFound.hasNutritionData, isFalse);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // TESTS PARA NutritionStatus
  // ═══════════════════════════════════════════════════════════════════════════

  group('NutritionStatus', () {
    test('displayName retorna nombres correctos', () {
      expect(NutritionStatus.found.displayName, 'Encontrado');
      expect(NutritionStatus.lowScore.displayName, 'Coincidencia baja');
      expect(NutritionStatus.notFound.displayName, 'No encontrado');
    });

    test('hasData verifica disponibilidad de datos', () {
      expect(NutritionStatus.found.hasData, isTrue);
      expect(NutritionStatus.lowScore.hasData, isTrue);
      expect(NutritionStatus.notFound.hasData, isFalse);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // TESTS PARA NutritionData
  // ═══════════════════════════════════════════════════════════════════════════

  group('NutritionData', () {
    late NutritionData testData;

    setUp(() {
      final json = {
        'metadata': {
          'version': '1.0',
          'generated': '2025-12-10T12:00:00.000Z',
          'source': 'Test',
          'num_ingredients': 2,
          'num_dishes': 1,
          'num_total': 3,
          'nutrients_included': ['energy_kcal', 'protein_g'],
          'stats': {
            'avg_match_score': 90.0,
            'ingredients_found': 2,
            'ingredients_not_found': 0,
          },
        },
        'foods': {
          'tomate': {
            'type': 'ingredient',
            'fdc_id': 12345,
            'fdc_description': 'Tomatoes',
            'match_score': 95.0,
            'status': 'found',
            'nutrients_per_100g': {
              'energy_kcal': 20.0,
              'protein_g': 0.8,
              'fat_g': 0.3,
              'carbohydrates_g': 4.0,
              'fiber_g': 1.2,
              'sugars_g': 2.6,
            },
          },
          'queso': {
            'type': 'ingredient',
            'fdc_id': 67890,
            'fdc_description': 'Cheese',
            'match_score': 85.0,
            'status': 'found',
            'nutrients_per_100g': {
              'energy_kcal': 300.0,
              'protein_g': 22.0,
              'fat_g': 22.0,
              'carbohydrates_g': 2.0,
              'fiber_g': 0.0,
              'sugars_g': 0.0,
            },
          },
          'caprese': {
            'type': 'dish',
            'components': {'tomate': 50, 'queso': 50},
            'missing_components': <String>[],
            'nutrients_per_100g': {
              'energy_kcal': 160.0,
              'protein_g': 11.4,
              'fat_g': 11.15,
              'carbohydrates_g': 3.0,
              'fiber_g': 0.6,
              'sugars_g': 1.3,
            },
          },
        },
      };

      testData = NutritionData.fromJson(json);
    });

    test('fromJson parsea metadata correctamente', () {
      expect(testData.metadata.version, '1.0');
      expect(testData.metadata.source, 'Test');
      expect(testData.metadata.numIngredients, 2);
      expect(testData.metadata.numDishes, 1);
    });

    test('getByLabel encuentra ingredientes', () {
      final tomate = testData.getByLabel('tomate');

      expect(tomate, isNotNull);
      expect(tomate!.label, 'tomate');
      expect(tomate.fdcId, 12345);
    });

    test('getByLabel encuentra platos', () {
      final caprese = testData.getByLabel('caprese');

      expect(caprese, isNotNull);
      expect(caprese!.label, 'caprese');
      expect(caprese.isDish, isTrue);
    });

    test('getByLabel retorna null para inexistente', () {
      final unknown = testData.getByLabel('unknown');
      expect(unknown, isNull);
    });

    test('hasLabel verifica existencia', () {
      expect(testData.hasLabel('tomate'), isTrue);
      expect(testData.hasLabel('caprese'), isTrue);
      expect(testData.hasLabel('unknown'), isFalse);
    });

    test('getBatch retorna múltiples resultados', () {
      final results = testData.getBatch(['tomate', 'queso', 'unknown']);

      expect(results.length, 2);
      expect(results.map((e) => e.label), containsAll(['tomate', 'queso']));
    });

    test('allLabels contiene todos los labels', () {
      expect(testData.allLabels, containsAll(['tomate', 'queso', 'caprese']));
      expect(testData.allLabels.length, 3);
    });

    test('totalCount es correcto', () {
      expect(testData.totalCount, 3);
    });

    test('allIngredients retorna solo ingredientes', () {
      expect(testData.allIngredients.length, 2);
      expect(testData.allIngredients.every((i) => !i.isDish), isTrue);
    });

    test('allDishes retorna solo platos', () {
      expect(testData.allDishes.length, 1);
      expect(testData.allDishes.every((d) => d.isDish), isTrue);
    });

    test('stats calcula correctamente', () {
      final stats = testData.stats;

      expect(stats.totalIngredients, 2);
      expect(stats.totalDishes, 1);
      expect(stats.totalFoods, 3);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // TESTS PARA NutritionMetadata
  // ═══════════════════════════════════════════════════════════════════════════

  group('NutritionMetadata', () {
    test('fromJson parsea correctamente', () {
      final json = {
        'version': '2.0',
        'generated': '2025-12-10T15:00:00.000Z',
        'source': 'USDA FoodData Central',
        'api_url': 'https://api.example.com',
        'num_ingredients': 80,
        'num_dishes': 6,
        'num_total': 86,
        'nutrients_included': ['energy_kcal', 'protein_g', 'fat_g'],
        'stats': {
          'avg_match_score': 92.5,
          'ingredients_found': 68,
          'ingredients_not_found': 12,
        },
      };

      final metadata = NutritionMetadata.fromJson(json);

      expect(metadata.version, '2.0');
      expect(metadata.source, 'USDA FoodData Central');
      expect(metadata.apiUrl, 'https://api.example.com');
      expect(metadata.numIngredients, 80);
      expect(metadata.numDishes, 6);
      expect(metadata.numTotal, 86);
      expect(metadata.avgMatchScore, 92.5);
      expect(metadata.ingredientsFound, 68);
      expect(metadata.ingredientsNotFound, 12);
    });

    test('fromJson maneja valores faltantes', () {
      final json = <String, dynamic>{};

      final metadata = NutritionMetadata.fromJson(json);

      expect(metadata.version, '1.0');
      expect(metadata.source, 'Unknown');
      expect(metadata.numIngredients, 0);
    });
  });
}

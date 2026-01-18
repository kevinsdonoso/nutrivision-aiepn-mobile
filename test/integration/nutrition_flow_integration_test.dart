// ╔═══════════════════════════════════════════════════════════════════════════════╗
// ║                   nutrition_flow_integration_test.dart                        ║
// ║         Tests de integracion para el flujo completo de nutricion             ║
// ╠═══════════════════════════════════════════════════════════════════════════════╣
// ║  Verifica el flujo: Deteccion -> Cantidades -> Calculo de nutrientes         ║
// ║  Incluye tests para ajustes de cantidad y recalculo reactivo.                ║
// ╚═══════════════════════════════════════════════════════════════════════════════╝

import 'package:flutter_test/flutter_test.dart';
import 'package:nutrivision_aiepn_mobile/data/models/detection.dart';
import 'package:nutrivision_aiepn_mobile/data/models/ingredient_quantity.dart';
import 'package:nutrivision_aiepn_mobile/data/models/nutrients_per_100g.dart';
import 'package:nutrivision_aiepn_mobile/data/models/nutrition_data.dart';
import 'package:nutrivision_aiepn_mobile/data/models/quantity_enums.dart';
import 'package:nutrivision_aiepn_mobile/features/nutrition/state/ingredient_quantities_notifier.dart';

void main() {
  // ═══════════════════════════════════════════════════════════════════════════
  // DATOS DE PRUEBA
  // ═══════════════════════════════════════════════════════════════════════════

  late NutritionData testNutritionData;
  late List<Detection> testDetections;

  setUp(() {
    // Crear datos nutricionales de prueba
    final nutritionJson = {
      'metadata': {
        'version': '1.0',
        'generated': '2025-12-10T12:00:00.000Z',
        'source': 'Test',
        'num_ingredients': 3,
        'num_dishes': 1,
        'num_total': 4,
        'nutrients_included': [
          'energy_kcal',
          'protein_g',
          'fat_g',
          'carbohydrates_g'
        ],
        'stats': {
          'avg_match_score': 90.0,
          'ingredients_found': 3,
          'ingredients_not_found': 0,
        },
      },
      'foods': {
        'tomate': {
          'type': 'ingredient',
          'fdc_id': 12345,
          'fdc_description': 'Tomatoes, raw',
          'match_score': 95.0,
          'status': 'found',
          'nutrients_per_100g': {
            'energy_kcal': 18.0,
            'protein_g': 0.9,
            'fat_g': 0.2,
            'carbohydrates_g': 3.9,
            'fiber_g': 1.2,
            'sugars_g': 2.6,
          },
        },
        'queso_mozzarella': {
          'type': 'ingredient',
          'fdc_id': 67890,
          'fdc_description': 'Mozzarella cheese',
          'match_score': 92.0,
          'status': 'found',
          'nutrients_per_100g': {
            'energy_kcal': 280.0,
            'protein_g': 28.0,
            'fat_g': 17.0,
            'carbohydrates_g': 3.1,
            'fiber_g': 0.0,
            'sugars_g': 1.0,
          },
        },
        'albahaca': {
          'type': 'ingredient',
          'fdc_id': 11112,
          'fdc_description': 'Basil, fresh',
          'match_score': 88.0,
          'status': 'found',
          'nutrients_per_100g': {
            'energy_kcal': 23.0,
            'protein_g': 3.2,
            'fat_g': 0.6,
            'carbohydrates_g': 2.7,
            'fiber_g': 1.6,
            'sugars_g': 0.3,
          },
        },
        'caprese': {
          'type': 'dish',
          'components': {'tomate': 45, 'queso_mozzarella': 45, 'albahaca': 10},
          'missing_components': <String>[],
          'nutrients_per_100g': {
            'energy_kcal': 136.0,
            'protein_g': 13.0,
            'fat_g': 7.8,
            'carbohydrates_g': 3.2,
            'fiber_g': 0.7,
            'sugars_g': 1.6,
          },
        },
      },
    };

    testNutritionData = NutritionData.fromJson(nutritionJson);

    // Crear detecciones de prueba (simula salida del modelo YOLO)
    testDetections = [
      Detection(
        x1: 10,
        y1: 10,
        x2: 100,
        y2: 100,
        confidence: 0.95,
        classId: 0,
        label: 'tomate',
      ),
      Detection(
        x1: 120,
        y1: 10,
        x2: 200,
        y2: 100,
        confidence: 0.88,
        classId: 1,
        label: 'queso_mozzarella',
      ),
      Detection(
        x1: 220,
        y1: 10,
        x2: 280,
        y2: 50,
        confidence: 0.75,
        classId: 2,
        label: 'albahaca',
      ),
    ];
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // TESTS: FLUJO DETECCION -> NUTRICION
  // ═══════════════════════════════════════════════════════════════════════════

  group('Flujo Deteccion -> Nutricion', () {
    test('busca informacion nutricional por etiqueta de deteccion', () {
      for (final detection in testDetections) {
        final nutrition = testNutritionData.getByLabel(detection.label);

        expect(nutrition, isNotNull,
            reason: 'Debe encontrar nutricion para ${detection.label}');
        expect(nutrition!.label, detection.label);
        expect(nutrition.hasNutritionData, isTrue);
      }
    });

    test('retorna null para etiqueta no existente', () {
      final detection = Detection(
        x1: 0,
        y1: 0,
        x2: 50,
        y2: 50,
        confidence: 0.9,
        classId: 99,
        label: 'ingrediente_inexistente',
      );

      final nutrition = testNutritionData.getByLabel(detection.label);
      expect(nutrition, isNull);
    });

    test('getBatch retorna solo ingredientes encontrados', () {
      final labels = testDetections.map((d) => d.label).toList();
      labels.add('inexistente');

      final results = testNutritionData.getBatch(labels);

      expect(results.length, 3);
      expect(results.map((r) => r.label),
          containsAll(['tomate', 'queso_mozzarella', 'albahaca']));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // TESTS: FLUJO DETECCION -> CANTIDADES
  // ═══════════════════════════════════════════════════════════════════════════

  group('Flujo Deteccion -> Cantidades', () {
    late IngredientQuantitiesNotifier quantitiesNotifier;

    setUp(() {
      quantitiesNotifier = IngredientQuantitiesNotifier();
    });

    test('setFromDetections crea cantidades por defecto', () {
      quantitiesNotifier.setFromDetections(testDetections);

      expect(quantitiesNotifier.state.count, 3);

      for (final detection in testDetections) {
        final quantity = quantitiesNotifier.state.getQuantity(detection.label);
        expect(quantity, isNotNull);
        expect(quantity!.grams, 100); // valor por defecto
        expect(quantity.source, QuantitySource.defaultValue);
      }
    });

    test('cantidades unicas por label (sin duplicados)', () {
      final duplicatedDetections = [
        ...testDetections,
        Detection(
          x1: 50,
          y1: 50,
          x2: 150,
          y2: 150,
          confidence: 0.82,
          classId: 0,
          label: 'tomate', // duplicado
        ),
      ];

      quantitiesNotifier.setFromDetections(duplicatedDetections);

      expect(quantitiesNotifier.state.count, 3);
    });

    test('ajuste manual de cantidad actualiza correctamente', () {
      quantitiesNotifier.setFromDetections(testDetections);

      // Simular ajuste manual del usuario
      quantitiesNotifier.updateQuantityGrams('tomate', 150);

      final tomateQuantity =
          quantitiesNotifier.state.getQuantity('tomate');
      expect(tomateQuantity!.grams, 150);
      expect(tomateQuantity.source, QuantitySource.manual);
    });

    test('ajuste manual no afecta otros ingredientes', () {
      quantitiesNotifier.setFromDetections(testDetections);

      quantitiesNotifier.updateQuantityGrams('tomate', 200);

      expect(
          quantitiesNotifier.state.getQuantity('queso_mozzarella')!.grams, 100);
      expect(quantitiesNotifier.state.getQuantity('albahaca')!.grams, 100);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // TESTS: CALCULO DE NUTRIENTES CON CANTIDADES
  // ═══════════════════════════════════════════════════════════════════════════

  group('Calculo de Nutrientes con Cantidades', () {
    /// Funcion auxiliar para calcular nutrientes totales
    /// (simula NutritionRepository.calculateTotalNutrientsWithQuantities)
    NutrientsPer100g calculateTotalWithQuantities(
      NutritionData data,
      List<IngredientQuantity> quantities,
    ) {
      var total = const NutrientsPer100g.zero();

      for (final quantity in quantities) {
        final nutrition = data.getByLabel(quantity.label);
        if (nutrition != null && nutrition.hasNutritionData) {
          final factor = quantity.grams / 100.0;
          total = total + (nutrition.nutrients * factor);
        }
      }

      return total;
    }

    test('calcula total con cantidades por defecto (100g cada uno)', () {
      final quantities = [
        IngredientQuantity.fromGrams(label: 'tomate', grams: 100),
        IngredientQuantity.fromGrams(label: 'queso_mozzarella', grams: 100),
        IngredientQuantity.fromGrams(label: 'albahaca', grams: 100),
      ];

      final total = calculateTotalWithQuantities(testNutritionData, quantities);

      // tomate: 18 + queso: 280 + albahaca: 23 = 321 kcal
      expect(total.energyKcal, closeTo(321, 0.1));
      // tomate: 0.9 + queso: 28 + albahaca: 3.2 = 32.1g
      expect(total.proteinG, closeTo(32.1, 0.1));
    });

    test('calcula total con cantidades ajustadas', () {
      final quantities = [
        IngredientQuantity.fromGrams(label: 'tomate', grams: 150), // 1.5x
        IngredientQuantity.fromGrams(label: 'queso_mozzarella', grams: 50), // 0.5x
        IngredientQuantity.fromGrams(label: 'albahaca', grams: 10), // 0.1x
      ];

      final total = calculateTotalWithQuantities(testNutritionData, quantities);

      // tomate: 18*1.5 + queso: 280*0.5 + albahaca: 23*0.1 = 27+140+2.3 = 169.3 kcal
      expect(total.energyKcal, closeTo(169.3, 0.1));
    });

    test('ignora ingredientes no encontrados', () {
      final quantities = [
        IngredientQuantity.fromGrams(label: 'tomate', grams: 100),
        IngredientQuantity.fromGrams(label: 'ingrediente_inexistente', grams: 500),
      ];

      final total = calculateTotalWithQuantities(testNutritionData, quantities);

      // Solo tomate: 18 kcal
      expect(total.energyKcal, closeTo(18, 0.1));
    });

    test('calcula proporciones correctamente para cantidades pequenas', () {
      final quantities = [
        IngredientQuantity.fromGrams(label: 'queso_mozzarella', grams: 30),
      ];

      final total = calculateTotalWithQuantities(testNutritionData, quantities);

      // queso: 280 kcal * 0.30 = 84 kcal
      expect(total.energyKcal, closeTo(84, 0.1));
      // queso: 28g proteina * 0.30 = 8.4g
      expect(total.proteinG, closeTo(8.4, 0.1));
    });

    test('lista vacia retorna nutrientes en cero', () {
      final total =
          calculateTotalWithQuantities(testNutritionData, <IngredientQuantity>[]);

      expect(total.energyKcal, 0);
      expect(total.proteinG, 0);
      expect(total.fatG, 0);
      expect(total.carbohydratesG, 0);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // TESTS: FLUJO COMPLETO END-TO-END
  // ═══════════════════════════════════════════════════════════════════════════

  group('Flujo Completo: Deteccion -> Cantidades -> Nutrientes', () {
    late IngredientQuantitiesNotifier quantitiesNotifier;

    /// Simula el calculo como lo haria el provider
    NutrientsPer100g calculateTotal(
      NutritionData data,
      IngredientQuantitiesState state,
    ) {
      return state.allQuantities.fold(
        const NutrientsPer100g.zero(),
        (total, quantity) {
          final nutrition = data.getByLabel(quantity.label);
          if (nutrition != null && nutrition.hasNutritionData) {
            final factor = quantity.grams / 100.0;
            return total + (nutrition.nutrients * factor);
          }
          return total;
        },
      );
    }

    setUp(() {
      quantitiesNotifier = IngredientQuantitiesNotifier();
    });

    test('flujo completo: detectar -> inicializar cantidades -> calcular', () {
      // 1. Simular detecciones del modelo YOLO
      final detections = testDetections;

      // 2. Inicializar cantidades desde detecciones
      quantitiesNotifier.setFromDetections(detections);

      // 3. Calcular nutrientes totales
      final total = calculateTotal(testNutritionData, quantitiesNotifier.state);

      // 4. Verificar resultados
      expect(quantitiesNotifier.state.count, 3);
      expect(total.energyKcal, closeTo(321, 0.1));
    });

    test('flujo con ajuste: detectar -> ajustar -> recalcular', () {
      // 1. Inicializar desde detecciones
      quantitiesNotifier.setFromDetections(testDetections);

      // 2. Calcular inicial
      final initialTotal =
          calculateTotal(testNutritionData, quantitiesNotifier.state);

      // 3. Usuario ajusta cantidades
      quantitiesNotifier.updateQuantityGrams('tomate', 200); // +100g
      quantitiesNotifier.updateQuantityGrams('queso_mozzarella', 50); // -50g

      // 4. Recalcular
      final adjustedTotal =
          calculateTotal(testNutritionData, quantitiesNotifier.state);

      // 5. Verificar cambio
      expect(adjustedTotal.energyKcal, isNot(equals(initialTotal.energyKcal)));

      // tomate: 18*2 + queso: 280*0.5 + albahaca: 23*1 = 36+140+23 = 199 kcal
      expect(adjustedTotal.energyKcal, closeTo(199, 0.1));
    });

    test('reset restaura valores por defecto y recalcula', () {
      // 1. Inicializar y ajustar
      quantitiesNotifier.setFromDetections(testDetections);
      quantitiesNotifier.updateQuantityGrams('tomate', 500);

      final adjustedTotal =
          calculateTotal(testNutritionData, quantitiesNotifier.state);

      // 2. Reset
      quantitiesNotifier.resetAllToDefaults();

      final resetTotal =
          calculateTotal(testNutritionData, quantitiesNotifier.state);

      // 3. Verificar que volvio al valor inicial
      expect(resetTotal.energyKcal, isNot(equals(adjustedTotal.energyKcal)));
      expect(resetTotal.energyKcal, closeTo(321, 0.1));
    });

    test('remover ingrediente actualiza calculo', () {
      // 1. Inicializar
      quantitiesNotifier.setFromDetections(testDetections);
      final initialTotal =
          calculateTotal(testNutritionData, quantitiesNotifier.state);

      // 2. Remover queso (el mas calorico)
      quantitiesNotifier.removeIngredient('queso_mozzarella');

      final afterRemovalTotal =
          calculateTotal(testNutritionData, quantitiesNotifier.state);

      // 3. Verificar reduccion
      expect(quantitiesNotifier.state.count, 2);
      // Inicial era 321, sin queso (280) = 41 kcal
      expect(afterRemovalTotal.energyKcal,
          closeTo(initialTotal.energyKcal - 280, 0.1));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // TESTS: PLATOS (DISHES)
  // ═══════════════════════════════════════════════════════════════════════════

  group('Nutricion de Platos', () {
    test('obtiene nutricion de plato correctamente', () {
      final caprese = testNutritionData.getByLabel('caprese');

      expect(caprese, isNotNull);
      expect(caprese!.isDish, isTrue);
      expect(caprese.components, isNotNull);
      expect(caprese.componentCount, 3);
    });

    test('plato tiene nutrientes calculados', () {
      final caprese = testNutritionData.getByLabel('caprese');

      expect(caprese!.nutrients.energyKcal, closeTo(136, 0.1));
      expect(caprese.nutrients.proteinG, closeTo(13, 0.1));
    });

    test('calcula nutrientes para porcion de plato', () {
      final caprese = testNutritionData.getByLabel('caprese')!;

      // 250g de ensalada caprese
      const grams = 250.0;
      final factor = grams / 100.0;
      final nutrients = caprese.nutrients * factor;

      // 136 kcal * 2.5 = 340 kcal
      expect(nutrients.energyKcal, closeTo(340, 0.1));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // TESTS: VALIDACION DE CANTIDADES
  // ═══════════════════════════════════════════════════════════════════════════

  group('Validacion de Cantidades', () {
    test('rechaza cantidades fuera de rango', () {
      final notifier = IngredientQuantitiesNotifier();

      expect(
        () => notifier.updateQuantityGrams('tomate', 0),
        throwsArgumentError,
      );

      expect(
        () => notifier.updateQuantityGrams('tomate', 10001),
        throwsArgumentError,
      );

      expect(
        () => notifier.updateQuantityGrams('tomate', -50),
        throwsArgumentError,
      );
    });

    test('acepta cantidades validas', () {
      final notifier = IngredientQuantitiesNotifier();

      expect(
        () => notifier.updateQuantityGrams('tomate', 1),
        returnsNormally,
      );

      expect(
        () => notifier.updateQuantityGrams('tomate', 5000),
        returnsNormally,
      );

      expect(
        () => notifier.updateQuantityGrams('tomate', 10000),
        returnsNormally,
      );
    });

    test('isValidGrams valida correctamente', () {
      expect(IngredientQuantitiesNotifier.isValidGrams(1), isTrue);
      expect(IngredientQuantitiesNotifier.isValidGrams(100), isTrue);
      expect(IngredientQuantitiesNotifier.isValidGrams(10000), isTrue);

      expect(IngredientQuantitiesNotifier.isValidGrams(0), isFalse);
      expect(IngredientQuantitiesNotifier.isValidGrams(0.5), isFalse);
      expect(IngredientQuantitiesNotifier.isValidGrams(10001), isFalse);
    });
  });
}

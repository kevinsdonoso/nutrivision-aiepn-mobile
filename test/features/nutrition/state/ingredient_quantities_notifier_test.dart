// ═══════════════════════════════════════════════════════════════════════════════════════════════════════════════
// ║                    ingredient_quantities_notifier_test.dart                                                 ║
// ║              Tests para IngredientQuantitiesNotifier y estado                                               ║
// ═══════════════════════════════════════════════════════════════════════════════════════════════════════════════
// ║  Verifica el comportamiento del StateNotifier para cantidades de ingredientes.                              ║
// ║  Incluye tests para actualizacion, validacion y reset de cantidades.                                        ║
// ═══════════════════════════════════════════════════════════════════════════════════════════════════════════════

import 'package:flutter_test/flutter_test.dart';
import 'package:nutrivision_aiepn_mobile/data/models/detection.dart';
import 'package:nutrivision_aiepn_mobile/data/models/ingredient_quantity.dart';
import 'package:nutrivision_aiepn_mobile/data/models/quantity_enums.dart';
import 'package:nutrivision_aiepn_mobile/data/models/standard_portion.dart';
import 'package:nutrivision_aiepn_mobile/features/nutrition/state/ingredient_quantities_notifier.dart';

void main() {
  // ═══════════════════════════════════════════════════════════════════════════
  // TESTS PARA IngredientQuantitiesState
  // ═══════════════════════════════════════════════════════════════════════════

  group('IngredientQuantitiesState', () {
    test('constructor inicial crea estado vacio', () {
      const state = IngredientQuantitiesState.initial();

      expect(state.isEmpty, isTrue);
      expect(state.isNotEmpty, isFalse);
      expect(state.count, 0);
      expect(state.totalGrams, 0);
      expect(state.labels, isEmpty);
      expect(state.allQuantities, isEmpty);
    });

    test('constructor con cantidades crea estado correcto', () {
      final quantities = {
        'tomate': IngredientQuantity.defaultValue('tomate'),
        'queso': IngredientQuantity.fromGrams(label: 'queso', grams: 50),
      };

      final state = IngredientQuantitiesState(quantities: quantities);

      expect(state.isEmpty, isFalse);
      expect(state.isNotEmpty, isTrue);
      expect(state.count, 2);
      expect(state.labels, containsAll(['tomate', 'queso']));
    });

    test('getQuantity retorna cantidad correcta', () {
      final quantities = {
        'tomate': IngredientQuantity.fromGrams(label: 'tomate', grams: 150),
      };

      final state = IngredientQuantitiesState(quantities: quantities);

      expect(state.getQuantity('tomate'), isNotNull);
      expect(state.getQuantity('tomate')!.grams, 150);
      expect(state.getQuantity('inexistente'), isNull);
    });

    test('totalGrams calcula suma correctamente', () {
      final quantities = {
        'tomate': IngredientQuantity.fromGrams(label: 'tomate', grams: 100),
        'queso': IngredientQuantity.fromGrams(label: 'queso', grams: 50),
        'cebolla': IngredientQuantity.fromGrams(label: 'cebolla', grams: 30),
      };

      final state = IngredientQuantitiesState(quantities: quantities);

      expect(state.totalGrams, 180);
    });

    test('copyWith crea copia con nuevas cantidades', () {
      final original = IngredientQuantitiesState(
        quantities: {
          'tomate': IngredientQuantity.defaultValue('tomate'),
        },
      );

      final newQuantities = {
        'queso': IngredientQuantity.fromGrams(label: 'queso', grams: 50),
      };

      final copy = original.copyWith(quantities: newQuantities);

      expect(copy.count, 1);
      expect(copy.getQuantity('queso'), isNotNull);
      expect(copy.getQuantity('tomate'), isNull);
    });

    test('equality funciona correctamente', () {
      final a = IngredientQuantitiesState(
        quantities: {
          'tomate': IngredientQuantity.fromGrams(label: 'tomate', grams: 100),
        },
      );
      final b = IngredientQuantitiesState(
        quantities: {
          'tomate': IngredientQuantity.fromGrams(label: 'tomate', grams: 100),
        },
      );
      final c = IngredientQuantitiesState(
        quantities: {
          'tomate': IngredientQuantity.fromGrams(label: 'tomate', grams: 150),
        },
      );

      expect(a == b, isTrue);
      expect(a == c, isFalse);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // TESTS PARA IngredientQuantitiesNotifier
  // ═══════════════════════════════════════════════════════════════════════════

  group('IngredientQuantitiesNotifier', () {
    late IngredientQuantitiesNotifier notifier;

    setUp(() {
      notifier = IngredientQuantitiesNotifier();
    });

    group('updateQuantityGrams', () {
      test('actualiza cantidad correctamente', () {
        notifier.updateQuantityGrams('tomate', 150);

        expect(notifier.state.count, 1);
        expect(notifier.state.getQuantity('tomate')!.grams, 150);
        expect(notifier.state.getQuantity('tomate')!.source,
            QuantitySource.manual);
      });

      test('sobrescribe cantidad existente', () {
        notifier.updateQuantityGrams('tomate', 100);
        notifier.updateQuantityGrams('tomate', 200);

        expect(notifier.state.count, 1);
        expect(notifier.state.getQuantity('tomate')!.grams, 200);
      });

      test('permite minimo de 1g', () {
        notifier.updateQuantityGrams('tomate', 1);

        expect(notifier.state.getQuantity('tomate')!.grams, 1);
      });

      test('permite maximo de 10kg', () {
        notifier.updateQuantityGrams('tomate', 10000);

        expect(notifier.state.getQuantity('tomate')!.grams, 10000);
      });

      test('lanza error para cantidad menor a minimo', () {
        expect(
          () => notifier.updateQuantityGrams('tomate', 0.5),
          throwsArgumentError,
        );
      });

      test('lanza error para cantidad mayor a maximo', () {
        expect(
          () => notifier.updateQuantityGrams('tomate', 10001),
          throwsArgumentError,
        );
      });

      test('lanza error para cantidad negativa', () {
        expect(
          () => notifier.updateQuantityGrams('tomate', -1),
          throwsArgumentError,
        );
      });
    });

    group('updateQuantityFromPortion', () {
      test('actualiza cantidad desde porcion', () {
        const portion = StandardPortion(
          ingredientLabel: 'tomate',
          name: '1 unidad mediana',
          grams: 150,
        );

        notifier.updateQuantityFromPortion('tomate', portion);

        expect(notifier.state.getQuantity('tomate')!.grams, 150);
        expect(
            notifier.state.getQuantity('tomate')!.unit, QuantityUnit.portion);
        expect(notifier.state.getQuantity('tomate')!.portionLabel,
            '1 unidad mediana');
      });
    });

    group('updateQuantity', () {
      test('actualiza con IngredientQuantity completo', () {
        final quantity = IngredientQuantity.estimated(
          label: 'tomate',
          grams: 120,
        );

        notifier.updateQuantity(quantity);

        expect(notifier.state.getQuantity('tomate')!.grams, 120);
        expect(notifier.state.getQuantity('tomate')!.source,
            QuantitySource.estimated);
      });
    });

    group('updateMultiple', () {
      test('actualiza multiples cantidades', () {
        final quantities = {
          'tomate': IngredientQuantity.fromGrams(label: 'tomate', grams: 100),
          'queso': IngredientQuantity.fromGrams(label: 'queso', grams: 50),
        };

        notifier.updateMultiple(quantities);

        expect(notifier.state.count, 2);
        expect(notifier.state.getQuantity('tomate')!.grams, 100);
        expect(notifier.state.getQuantity('queso')!.grams, 50);
      });

      test('combina con cantidades existentes', () {
        notifier.updateQuantityGrams('cebolla', 30);

        final quantities = {
          'tomate': IngredientQuantity.fromGrams(label: 'tomate', grams: 100),
        };

        notifier.updateMultiple(quantities);

        expect(notifier.state.count, 2);
        expect(notifier.state.getQuantity('cebolla')!.grams, 30);
        expect(notifier.state.getQuantity('tomate')!.grams, 100);
      });
    });

    group('setFromDetections', () {
      test('crea cantidades por defecto para detecciones', () {
        final detections = [
          Detection(
            x1: 0,
            y1: 0,
            x2: 100,
            y2: 100,
            confidence: 0.9,
            classId: 0,
            label: 'tomate',
          ),
          Detection(
            x1: 100,
            y1: 0,
            x2: 200,
            y2: 100,
            confidence: 0.85,
            classId: 1,
            label: 'queso',
          ),
        ];

        notifier.setFromDetections(detections);

        expect(notifier.state.count, 2);
        expect(notifier.state.getQuantity('tomate')!.grams, 100); // default
        expect(notifier.state.getQuantity('queso')!.grams, 100); // default
        expect(notifier.state.getQuantity('tomate')!.source,
            QuantitySource.defaultValue);
      });

      test('no sobrescribe cantidades existentes por defecto', () {
        notifier.updateQuantityGrams('tomate', 200);

        final detections = [
          Detection(
            x1: 0,
            y1: 0,
            x2: 100,
            y2: 100,
            confidence: 0.9,
            classId: 0,
            label: 'tomate',
          ),
        ];

        notifier.setFromDetections(detections);

        expect(notifier.state.getQuantity('tomate')!.grams, 200); // mantiene
      });

      test('sobrescribe cantidades existentes con overwrite=true', () {
        notifier.updateQuantityGrams('tomate', 200);

        final detections = [
          Detection(
            x1: 0,
            y1: 0,
            x2: 100,
            y2: 100,
            confidence: 0.9,
            classId: 0,
            label: 'tomate',
          ),
        ];

        notifier.setFromDetections(detections, overwrite: true);

        expect(notifier.state.getQuantity('tomate')!.grams, 100); // default
      });

      test('maneja lista vacia', () {
        notifier.setFromDetections([]);

        expect(notifier.state.isEmpty, isTrue);
      });

      test('maneja detecciones duplicadas', () {
        final detections = [
          Detection(
            x1: 0,
            y1: 0,
            x2: 100,
            y2: 100,
            confidence: 0.9,
            classId: 0,
            label: 'tomate',
          ),
          Detection(
            x1: 100,
            y1: 0,
            x2: 200,
            y2: 100,
            confidence: 0.85,
            classId: 0,
            label: 'tomate',
          ),
        ];

        notifier.setFromDetections(detections);

        expect(notifier.state.count, 1); // solo una entrada
      });
    });

    group('setFromLabels', () {
      test('crea cantidades por defecto para etiquetas', () {
        notifier.setFromLabels(['tomate', 'queso', 'cebolla']);

        expect(notifier.state.count, 3);
        expect(notifier.state.getQuantity('tomate')!.grams, 100);
        expect(notifier.state.getQuantity('queso')!.grams, 100);
        expect(notifier.state.getQuantity('cebolla')!.grams, 100);
      });

      test('maneja lista vacia', () {
        notifier.setFromLabels([]);

        expect(notifier.state.isEmpty, isTrue);
      });
    });

    group('resetToDefault', () {
      test('resetea cantidad individual al valor por defecto', () {
        notifier.updateQuantityGrams('tomate', 200);

        notifier.resetToDefault('tomate');

        expect(notifier.state.getQuantity('tomate')!.grams, 100);
        expect(notifier.state.getQuantity('tomate')!.source,
            QuantitySource.defaultValue);
      });

      test('ignora ingrediente inexistente', () {
        notifier.resetToDefault('inexistente');

        expect(notifier.state.isEmpty, isTrue);
      });
    });

    group('resetAllToDefaults', () {
      test('resetea todas las cantidades al valor por defecto', () {
        notifier.updateQuantityGrams('tomate', 200);
        notifier.updateQuantityGrams('queso', 50);

        notifier.resetAllToDefaults();

        expect(notifier.state.getQuantity('tomate')!.grams, 100);
        expect(notifier.state.getQuantity('queso')!.grams, 100);
      });

      test('maneja estado vacio', () {
        notifier.resetAllToDefaults();

        expect(notifier.state.isEmpty, isTrue);
      });
    });

    group('removeIngredient', () {
      test('remueve ingrediente del estado', () {
        notifier.updateQuantityGrams('tomate', 100);
        notifier.updateQuantityGrams('queso', 50);

        notifier.removeIngredient('tomate');

        expect(notifier.state.count, 1);
        expect(notifier.state.getQuantity('tomate'), isNull);
        expect(notifier.state.getQuantity('queso'), isNotNull);
      });

      test('ignora ingrediente inexistente', () {
        notifier.updateQuantityGrams('tomate', 100);

        notifier.removeIngredient('inexistente');

        expect(notifier.state.count, 1);
      });
    });

    group('removeIngredients', () {
      test('remueve multiples ingredientes', () {
        notifier.updateQuantityGrams('tomate', 100);
        notifier.updateQuantityGrams('queso', 50);
        notifier.updateQuantityGrams('cebolla', 30);

        notifier.removeIngredients(['tomate', 'queso']);

        expect(notifier.state.count, 1);
        expect(notifier.state.getQuantity('cebolla'), isNotNull);
      });

      test('maneja lista vacia', () {
        notifier.updateQuantityGrams('tomate', 100);

        notifier.removeIngredients([]);

        expect(notifier.state.count, 1);
      });
    });

    group('clear', () {
      test('limpia todo el estado', () {
        notifier.updateQuantityGrams('tomate', 100);
        notifier.updateQuantityGrams('queso', 50);

        notifier.clear();

        expect(notifier.state.isEmpty, isTrue);
      });

      test('maneja estado vacio', () {
        notifier.clear();

        expect(notifier.state.isEmpty, isTrue);
      });
    });

    group('isValidGrams', () {
      test('retorna true para valores validos', () {
        expect(IngredientQuantitiesNotifier.isValidGrams(1), isTrue);
        expect(IngredientQuantitiesNotifier.isValidGrams(100), isTrue);
        expect(IngredientQuantitiesNotifier.isValidGrams(10000), isTrue);
      });

      test('retorna false para valores invalidos', () {
        expect(IngredientQuantitiesNotifier.isValidGrams(0), isFalse);
        expect(IngredientQuantitiesNotifier.isValidGrams(0.5), isFalse);
        expect(IngredientQuantitiesNotifier.isValidGrams(-1), isFalse);
        expect(IngredientQuantitiesNotifier.isValidGrams(10001), isFalse);
      });
    });
  });
}

// ═══════════════════════════════════════════════════════════════════════════════════
// ║                      ingredient_quantity_test.dart                              ║
// ║          Tests para modelos de cantidad de ingredientes                         ║
// ═══════════════════════════════════════════════════════════════════════════════════
// ║  Verifica el comportamiento de IngredientQuantity, StandardPortion,             ║
// ║  QuantityUnit y QuantitySource.                                                 ║
// ═══════════════════════════════════════════════════════════════════════════════════

import 'package:flutter_test/flutter_test.dart';
import 'package:nutrivision_aiepn_mobile/data/models/ingredient_quantity.dart';
import 'package:nutrivision_aiepn_mobile/data/models/quantity_enums.dart';
import 'package:nutrivision_aiepn_mobile/data/models/standard_portion.dart';

void main() {
  // ═══════════════════════════════════════════════════════════════════════════
  // TESTS PARA QuantityUnit
  // ═══════════════════════════════════════════════════════════════════════════

  group('QuantityUnit', () {
    test('displayName retorna nombres correctos', () {
      expect(QuantityUnit.grams.displayName, 'gramos');
      expect(QuantityUnit.portion.displayName, 'porción');
    });

    test('tiene 2 valores', () {
      expect(QuantityUnit.values.length, 2);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // TESTS PARA QuantitySource
  // ═══════════════════════════════════════════════════════════════════════════

  group('QuantitySource', () {
    test('displayName retorna nombres correctos', () {
      expect(QuantitySource.manual.displayName, 'Manual');
      expect(QuantitySource.estimated.displayName, 'Estimada');
      expect(QuantitySource.defaultValue.displayName, 'Por defecto');
    });

    test('requiresConfirmation solo es true para estimated', () {
      expect(QuantitySource.manual.requiresConfirmation, isFalse);
      expect(QuantitySource.estimated.requiresConfirmation, isTrue);
      expect(QuantitySource.defaultValue.requiresConfirmation, isFalse);
    });

    test('isReliable solo es true para manual', () {
      expect(QuantitySource.manual.isReliable, isTrue);
      expect(QuantitySource.estimated.isReliable, isFalse);
      expect(QuantitySource.defaultValue.isReliable, isFalse);
    });

    test('tiene 3 valores', () {
      expect(QuantitySource.values.length, 3);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // TESTS PARA StandardPortion
  // ═══════════════════════════════════════════════════════════════════════════

  group('StandardPortion', () {
    group('Constructor', () {
      test('crea instancia con valores correctos', () {
        const portion = StandardPortion(
          ingredientLabel: 'tomate',
          name: '1 unidad mediana',
          grams: 150,
          description: 'Un tomate de tamano mediano',
        );

        expect(portion.ingredientLabel, 'tomate');
        expect(portion.name, '1 unidad mediana');
        expect(portion.grams, 150);
        expect(portion.description, 'Un tomate de tamano mediano');
      });

      test('description es opcional', () {
        const portion = StandardPortion(
          ingredientLabel: 'queso',
          name: '1 taza rallado',
          grams: 110,
        );

        expect(portion.description, isNull);
      });
    });

    group('Propiedades', () {
      test('displayName formatea correctamente', () {
        const portion = StandardPortion(
          ingredientLabel: 'tomate',
          name: '1 unidad mediana',
          grams: 150,
        );

        expect(portion.displayName, '1 unidad mediana (150g)');
      });

      test('isValid retorna true para porcion valida', () {
        const portion = StandardPortion(
          ingredientLabel: 'tomate',
          name: '1 unidad',
          grams: 150,
        );

        expect(portion.isValid, isTrue);
      });

      test('isValid retorna false para ingredientLabel vacio', () {
        const portion = StandardPortion(
          ingredientLabel: '',
          name: '1 unidad',
          grams: 150,
        );

        expect(portion.isValid, isFalse);
      });

      test('isValid retorna false para name vacio', () {
        const portion = StandardPortion(
          ingredientLabel: 'tomate',
          name: '',
          grams: 150,
        );

        expect(portion.isValid, isFalse);
      });

      test('isValid retorna false para grams <= 0', () {
        const portion = StandardPortion(
          ingredientLabel: 'tomate',
          name: '1 unidad',
          grams: 0,
        );

        expect(portion.isValid, isFalse);
      });
    });

    group('Serializacion JSON', () {
      test('toJson convierte correctamente', () {
        const portion = StandardPortion(
          ingredientLabel: 'tomate',
          name: '1 unidad',
          grams: 150,
          description: 'Descripcion',
        );

        final json = portion.toJson();

        expect(json['name'], '1 unidad');
        expect(json['grams'], 150);
        expect(json['description'], 'Descripcion');
        // ingredientLabel no se incluye en toJson
        expect(json.containsKey('ingredientLabel'), isFalse);
      });

      test('toJson omite description si es null', () {
        const portion = StandardPortion(
          ingredientLabel: 'tomate',
          name: '1 unidad',
          grams: 150,
        );

        final json = portion.toJson();

        expect(json.containsKey('description'), isFalse);
      });

      test('fromJson parsea correctamente', () {
        final json = {
          'name': '1 taza',
          'grams': 110.0,
          'description': 'Una taza',
        };

        final portion = StandardPortion.fromJson(json, 'queso');

        expect(portion.ingredientLabel, 'queso');
        expect(portion.name, '1 taza');
        expect(portion.grams, 110);
        expect(portion.description, 'Una taza');
      });

      test('toJson y fromJson son inversos', () {
        const original = StandardPortion(
          ingredientLabel: 'tomate',
          name: '1 unidad mediana',
          grams: 150,
          description: 'Descripcion',
        );

        final json = original.toJson();
        final restored = StandardPortion.fromJson(json, 'tomate');

        expect(restored.ingredientLabel, original.ingredientLabel);
        expect(restored.name, original.name);
        expect(restored.grams, original.grams);
        expect(restored.description, original.description);
      });
    });

    group('Equality y copyWith', () {
      test('equality funciona correctamente', () {
        const a = StandardPortion(
          ingredientLabel: 'tomate',
          name: '1 unidad',
          grams: 150,
        );
        const b = StandardPortion(
          ingredientLabel: 'tomate',
          name: '1 unidad',
          grams: 150,
        );
        const c = StandardPortion(
          ingredientLabel: 'tomate',
          name: '1 unidad',
          grams: 200,
        );

        expect(a == b, isTrue);
        expect(a == c, isFalse);
        expect(a.hashCode, equals(b.hashCode));
      });

      test('copyWith crea copia modificada', () {
        const original = StandardPortion(
          ingredientLabel: 'tomate',
          name: '1 unidad',
          grams: 150,
        );

        final modified = original.copyWith(grams: 200);

        expect(modified.grams, 200);
        expect(modified.name, original.name);
        expect(modified.ingredientLabel, original.ingredientLabel);
      });

      test('toString retorna representacion correcta', () {
        const portion = StandardPortion(
          ingredientLabel: 'tomate',
          name: '1 unidad',
          grams: 150,
        );

        final str = portion.toString();

        expect(str, contains('tomate'));
        expect(str, contains('1 unidad'));
        expect(str, contains('150'));
      });
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // TESTS PARA IngredientQuantity
  // ═══════════════════════════════════════════════════════════════════════════

  group('IngredientQuantity', () {
    group('Constantes', () {
      test('minGrams es 1', () {
        expect(IngredientQuantity.minGrams, 1.0);
      });

      test('maxGrams es 10000', () {
        expect(IngredientQuantity.maxGrams, 10000.0);
      });

      test('defaultGrams es 100', () {
        expect(IngredientQuantity.defaultGrams, 100.0);
      });
    });

    group('Constructor principal', () {
      test('crea instancia con valores correctos', () {
        final quantity = IngredientQuantity(
          label: 'tomate',
          grams: 150,
          unit: QuantityUnit.grams,
          source: QuantitySource.manual,
        );

        expect(quantity.label, 'tomate');
        expect(quantity.grams, 150);
        expect(quantity.unit, QuantityUnit.grams);
        expect(quantity.source, QuantitySource.manual);
        expect(quantity.portionLabel, isNull);
      });

      test('lanza error para gramos menor al minimo', () {
        expect(
          () => IngredientQuantity(
            label: 'tomate',
            grams: 0.5,
            unit: QuantityUnit.grams,
            source: QuantitySource.manual,
          ),
          throwsArgumentError,
        );
      });

      test('lanza error para gramos mayor al maximo', () {
        expect(
          () => IngredientQuantity(
            label: 'tomate',
            grams: 10001,
            unit: QuantityUnit.grams,
            source: QuantitySource.manual,
          ),
          throwsArgumentError,
        );
      });

      test('lanza error para label vacio', () {
        expect(
          () => IngredientQuantity(
            label: '',
            grams: 100,
            unit: QuantityUnit.grams,
            source: QuantitySource.manual,
          ),
          throwsArgumentError,
        );
      });
    });

    group('Factory constructors', () {
      test('defaultValue crea con 100g', () {
        final quantity = IngredientQuantity.defaultValue('tomate');

        expect(quantity.label, 'tomate');
        expect(quantity.grams, 100);
        expect(quantity.unit, QuantityUnit.grams);
        expect(quantity.source, QuantitySource.defaultValue);
      });

      test('fromGrams crea correctamente', () {
        final quantity = IngredientQuantity.fromGrams(
          label: 'queso',
          grams: 50,
          source: QuantitySource.manual,
        );

        expect(quantity.label, 'queso');
        expect(quantity.grams, 50);
        expect(quantity.source, QuantitySource.manual);
      });

      test('estimated crea con source estimated', () {
        final quantity = IngredientQuantity.estimated(
          label: 'cebolla',
          grams: 80,
        );

        expect(quantity.label, 'cebolla');
        expect(quantity.grams, 80);
        expect(quantity.source, QuantitySource.estimated);
      });

      test('fromPortion crea desde porcion', () {
        const portion = StandardPortion(
          ingredientLabel: 'tomate',
          name: '1 unidad mediana',
          grams: 150,
        );

        final quantity = IngredientQuantity.fromPortion(
          label: 'tomate',
          portion: portion,
        );

        expect(quantity.label, 'tomate');
        expect(quantity.grams, 150);
        expect(quantity.unit, QuantityUnit.portion);
        expect(quantity.portionLabel, '1 unidad mediana');
        expect(quantity.source, QuantitySource.manual);
      });
    });

    group('Propiedades calculadas', () {
      test('nutrientFactor calcula correctamente', () {
        final q100 = IngredientQuantity.fromGrams(label: 'test', grams: 100);
        final q150 = IngredientQuantity.fromGrams(label: 'test', grams: 150);
        final q50 = IngredientQuantity.fromGrams(label: 'test', grams: 50);

        expect(q100.nutrientFactor, 1.0);
        expect(q150.nutrientFactor, 1.5);
        expect(q50.nutrientFactor, 0.5);
      });

      test('isDefault identifica correctamente', () {
        final def = IngredientQuantity.defaultValue('test');
        final manual = IngredientQuantity.fromGrams(label: 'test', grams: 100);

        expect(def.isDefault, isTrue);
        expect(manual.isDefault, isFalse);
      });

      test('isManual identifica correctamente', () {
        final manual = IngredientQuantity.fromGrams(
          label: 'test',
          grams: 100,
          source: QuantitySource.manual,
        );
        final estimated =
            IngredientQuantity.estimated(label: 'test', grams: 100);

        expect(manual.isManual, isTrue);
        expect(estimated.isManual, isFalse);
      });

      test('isEstimated identifica correctamente', () {
        final estimated =
            IngredientQuantity.estimated(label: 'test', grams: 100);
        final manual = IngredientQuantity.fromGrams(label: 'test', grams: 100);

        expect(estimated.isEstimated, isTrue);
        expect(manual.isEstimated, isFalse);
      });

      test('displayText formatea gramos correctamente', () {
        final quantity =
            IngredientQuantity.fromGrams(label: 'test', grams: 150);
        expect(quantity.displayText, '150g');
      });

      test('displayText formatea porcion correctamente', () {
        const portion = StandardPortion(
          ingredientLabel: 'tomate',
          name: '1 unidad mediana',
          grams: 150,
        );
        final quantity = IngredientQuantity.fromPortion(
          label: 'tomate',
          portion: portion,
        );

        expect(quantity.displayText, '1 unidad mediana (150g)');
      });

      test('shortDisplayText siempre muestra gramos', () {
        const portion = StandardPortion(
          ingredientLabel: 'tomate',
          name: '1 unidad mediana',
          grams: 150,
        );
        final quantity = IngredientQuantity.fromPortion(
          label: 'tomate',
          portion: portion,
        );

        expect(quantity.shortDisplayText, '150g');
      });

      test('isValid verifica todos los requisitos', () {
        final valid = IngredientQuantity.fromGrams(label: 'test', grams: 100);
        expect(valid.isValid, isTrue);

        // Porcion sin portionLabel seria invalido pero el constructor lo previene
        final validPortion = IngredientQuantity(
          label: 'test',
          grams: 100,
          unit: QuantityUnit.portion,
          portionLabel: 'porcion',
          source: QuantitySource.manual,
        );
        expect(validPortion.isValid, isTrue);
      });
    });

    group('Serializacion JSON', () {
      test('toJson convierte correctamente', () {
        final quantity = IngredientQuantity.fromGrams(
          label: 'tomate',
          grams: 150,
        );

        final json = quantity.toJson();

        expect(json['label'], 'tomate');
        expect(json['grams'], 150);
        expect(json['unit'], 'grams');
        expect(json['source'], 'manual');
      });

      test('toJson incluye portionLabel cuando existe', () {
        const portion = StandardPortion(
          ingredientLabel: 'tomate',
          name: '1 unidad',
          grams: 150,
        );
        final quantity = IngredientQuantity.fromPortion(
          label: 'tomate',
          portion: portion,
        );

        final json = quantity.toJson();

        expect(json['portionLabel'], '1 unidad');
      });

      test('fromJson parsea correctamente', () {
        final json = {
          'label': 'tomate',
          'grams': 150.0,
          'unit': 'grams',
          'source': 'manual',
        };

        final quantity = IngredientQuantity.fromJson(json);

        expect(quantity.label, 'tomate');
        expect(quantity.grams, 150);
        expect(quantity.unit, QuantityUnit.grams);
        expect(quantity.source, QuantitySource.manual);
      });

      test('fromJson usa defaults para valores invalidos', () {
        final json = {
          'label': 'tomate',
          'grams': 150.0,
          'unit': 'invalid_unit',
          'source': 'invalid_source',
        };

        final quantity = IngredientQuantity.fromJson(json);

        expect(quantity.unit, QuantityUnit.grams);
        expect(quantity.source, QuantitySource.defaultValue);
      });

      test('toJson y fromJson son inversos', () {
        final original = IngredientQuantity(
          label: 'tomate',
          grams: 150,
          unit: QuantityUnit.portion,
          portionLabel: '1 unidad',
          source: QuantitySource.manual,
        );

        final json = original.toJson();
        final restored = IngredientQuantity.fromJson(json);

        expect(restored.label, original.label);
        expect(restored.grams, original.grams);
        expect(restored.unit, original.unit);
        expect(restored.portionLabel, original.portionLabel);
        expect(restored.source, original.source);
      });
    });

    group('Equality y copyWith', () {
      test('equality funciona correctamente', () {
        final a = IngredientQuantity.fromGrams(label: 'tomate', grams: 150);
        final b = IngredientQuantity.fromGrams(label: 'tomate', grams: 150);
        final c = IngredientQuantity.fromGrams(label: 'tomate', grams: 200);

        expect(a == b, isTrue);
        expect(a == c, isFalse);
        expect(a.hashCode, equals(b.hashCode));
      });

      test('copyWith crea copia modificada', () {
        final original =
            IngredientQuantity.fromGrams(label: 'tomate', grams: 150);
        final modified = original.copyWith(grams: 200);

        expect(modified.grams, 200);
        expect(modified.label, original.label);
        expect(modified.source, original.source);
      });

      test('toString retorna representacion correcta', () {
        final quantity =
            IngredientQuantity.fromGrams(label: 'tomate', grams: 150);
        final str = quantity.toString();

        expect(str, contains('tomate'));
        expect(str, contains('150'));
        expect(str, contains('grams'));
      });
    });
  });
}

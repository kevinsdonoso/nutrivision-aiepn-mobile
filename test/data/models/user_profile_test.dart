// ═══════════════════════════════════════════════════════════════════════════════════
// ║                           user_profile_test.dart                                 ║
// ║                  Tests para modelo UserProfile y enums relacionados              ║
// ═══════════════════════════════════════════════════════════════════════════════════
// ║  Verifica el comportamiento de UserProfile, Gender, ActivityLevel,              ║
// ║  NutritionGoal y BmiCategory.                                                    ║
// ═══════════════════════════════════════════════════════════════════════════════════

import 'package:flutter_test/flutter_test.dart';
import 'package:nutrivision_aiepn_mobile/data/models/user_profile.dart';

void main() {
  // ═══════════════════════════════════════════════════════════════════════════
  // TESTS PARA UserProfile
  // ═══════════════════════════════════════════════════════════════════════════

  group('UserProfile', () {
    final now = DateTime.now();
    final birthDate = DateTime(1990, 5, 15);

    UserProfile createTestProfile({
      String id = 'test-id',
      String email = 'test@example.com',
      String displayName = 'Test User',
      String? photoUrl,
      DateTime? birthDateValue,
      Gender? gender,
      String? country,
      String? city,
      double? weightKg,
      double? heightCm,
      ActivityLevel? activityLevel,
      NutritionGoal? nutritionGoal,
      int? dailyCalorieTarget,
      bool onboardingCompleted = false,
    }) {
      return UserProfile(
        id: id,
        email: email,
        displayName: displayName,
        photoUrl: photoUrl,
        birthDate: birthDateValue,
        gender: gender,
        country: country,
        city: city,
        weightKg: weightKg,
        heightCm: heightCm,
        activityLevel: activityLevel,
        nutritionGoal: nutritionGoal,
        dailyCalorieTarget: dailyCalorieTarget,
        createdAt: now,
        updatedAt: now,
        onboardingCompleted: onboardingCompleted,
      );
    }

    group('Constructor y propiedades basicas', () {
      test('constructor crea instancia con valores correctos', () {
        final profile = createTestProfile(
          displayName: 'Juan Perez',
          gender: Gender.male,
        );

        expect(profile.id, 'test-id');
        expect(profile.email, 'test@example.com');
        expect(profile.displayName, 'Juan Perez');
        expect(profile.gender, Gender.male);
      });

      test('newUser factory crea perfil inicial', () {
        final profile = UserProfile.newUser(
          id: 'new-user-id',
          email: 'new@example.com',
          displayName: 'New User',
        );

        expect(profile.id, 'new-user-id');
        expect(profile.email, 'new@example.com');
        expect(profile.displayName, 'New User');
        expect(profile.onboardingCompleted, isFalse);
        expect(profile.photoUrl, isNull);
        expect(profile.weightKg, isNull);
      });
    });

    group('Propiedades calculadas - edad', () {
      test('age retorna null si birthDate es null', () {
        final profile = createTestProfile();
        expect(profile.age, isNull);
      });

      test('age calcula correctamente la edad', () {
        // Crear fecha de nacimiento hace 30 anios
        final thirtyYearsAgo = DateTime(
          now.year - 30,
          now.month,
          now.day,
        );
        final profile = createTestProfile(birthDateValue: thirtyYearsAgo);
        expect(profile.age, 30);
      });

      test('age considera mes y dia correctamente', () {
        // Si aun no ha cumplido anios este anio (mes futuro)
        final notYetBirthday = DateTime(now.year - 25, 12, 31);
        final profile = createTestProfile(birthDateValue: notYetBirthday);
        // Si hoy es antes de diciembre 31, la edad deberia ser 24
        // Si hoy es diciembre 31, la edad deberia ser 25
        final expectedAge =
            (now.month < 12 || (now.month == 12 && now.day < 31)) ? 24 : 25;
        expect(profile.age, expectedAge);
      });
    });

    group('Propiedades calculadas - IMC', () {
      test('bmi retorna null si faltan datos fisicos', () {
        final profile = createTestProfile();
        expect(profile.bmi, isNull);
      });

      test('bmi retorna null si altura es cero', () {
        final profile = createTestProfile(weightKg: 70, heightCm: 0);
        expect(profile.bmi, isNull);
      });

      test('bmi calcula correctamente', () {
        final profile = createTestProfile(weightKg: 70, heightCm: 175);
        // IMC = 70 / (1.75^2) = 70 / 3.0625 = 22.86
        expect(profile.bmi, closeTo(22.86, 0.01));
      });

      test('bmiCategory categoriza correctamente', () {
        final underweight =
            createTestProfile(weightKg: 50, heightCm: 180).bmiCategory;
        final normal =
            createTestProfile(weightKg: 70, heightCm: 175).bmiCategory;
        final overweight =
            createTestProfile(weightKg: 85, heightCm: 175).bmiCategory;
        final obese =
            createTestProfile(weightKg: 100, heightCm: 175).bmiCategory;

        expect(underweight, BmiCategory.underweight);
        expect(normal, BmiCategory.normal);
        expect(overweight, BmiCategory.overweight);
        expect(obese, BmiCategory.obese);
      });
    });

    group('Propiedades calculadas - metabolismo', () {
      test('bmr retorna null si faltan datos', () {
        final profile = createTestProfile();
        expect(profile.bmr, isNull);
      });

      test('bmr calcula correctamente para hombre', () {
        final maleProfile = createTestProfile(
          birthDateValue: DateTime(now.year - 30, now.month, now.day),
          gender: Gender.male,
          weightKg: 70,
          heightCm: 175,
        );
        // Mifflin-St Jeor: 10*70 + 6.25*175 - 5*30 + 5 = 700 + 1093.75 - 150 + 5 = 1648.75
        expect(maleProfile.bmr, closeTo(1648.75, 0.1));
      });

      test('bmr calcula correctamente para mujer', () {
        final femaleProfile = createTestProfile(
          birthDateValue: DateTime(now.year - 30, now.month, now.day),
          gender: Gender.female,
          weightKg: 60,
          heightCm: 165,
        );
        // Mifflin-St Jeor: 10*60 + 6.25*165 - 5*30 - 161 = 600 + 1031.25 - 150 - 161 = 1320.25
        expect(femaleProfile.bmr, closeTo(1320.25, 0.1));
      });

      test('tdee calcula correctamente con factor de actividad', () {
        final profile = createTestProfile(
          birthDateValue: DateTime(now.year - 30, now.month, now.day),
          gender: Gender.male,
          weightKg: 70,
          heightCm: 175,
          activityLevel: ActivityLevel.moderate,
        );
        // TDEE = BMR * 1.55 = 1648.75 * 1.55 = 2555.56
        expect(profile.tdee, closeTo(2555.56, 1));
      });

      test('recommendedCalories calcula correctamente segun meta', () {
        final baseProfile = createTestProfile(
          birthDateValue: DateTime(now.year - 30, now.month, now.day),
          gender: Gender.male,
          weightKg: 70,
          heightCm: 175,
          activityLevel: ActivityLevel.moderate,
        );

        final loseWeight =
            baseProfile.copyWith(nutritionGoal: NutritionGoal.loseWeight);
        final maintain =
            baseProfile.copyWith(nutritionGoal: NutritionGoal.maintain);
        final gainMuscle =
            baseProfile.copyWith(nutritionGoal: NutritionGoal.gainMuscle);

        // TDEE = ~2555.56
        expect(loseWeight.recommendedCalories, closeTo(2044, 5)); // -20%
        expect(maintain.recommendedCalories, closeTo(2556, 5)); // 0%
        expect(gainMuscle.recommendedCalories, closeTo(2939, 5)); // +15%
      });
    });

    group('Propiedades calculadas - completitud', () {
      test('hasPersonalData verifica datos personales', () {
        final incomplete = createTestProfile();
        final complete = createTestProfile(
          birthDateValue: birthDate,
          gender: Gender.male,
          country: 'Ecuador',
        );

        expect(incomplete.hasPersonalData, isFalse);
        expect(complete.hasPersonalData, isTrue);
      });

      test('hasPhysicalData verifica datos fisicos', () {
        final incomplete = createTestProfile();
        final complete = createTestProfile(
          weightKg: 70,
          heightCm: 175,
          activityLevel: ActivityLevel.moderate,
        );

        expect(incomplete.hasPhysicalData, isFalse);
        expect(complete.hasPhysicalData, isTrue);
      });

      test('hasNutritionData verifica datos nutricionales', () {
        final incomplete = createTestProfile();
        final complete = createTestProfile(
          nutritionGoal: NutritionGoal.maintain,
          dailyCalorieTarget: 2000,
        );

        expect(incomplete.hasNutritionData, isFalse);
        expect(complete.hasNutritionData, isTrue);
      });

      test('profileCompletionPercent calcula porcentaje correcto', () {
        final empty = createTestProfile();
        final partial = createTestProfile(
          photoUrl: 'url',
          birthDateValue: birthDate,
          gender: Gender.male,
          country: 'Ecuador',
          city: 'Quito',
        );
        final complete = createTestProfile(
          photoUrl: 'url',
          birthDateValue: birthDate,
          gender: Gender.male,
          country: 'Ecuador',
          city: 'Quito',
          weightKg: 70,
          heightCm: 175,
          activityLevel: ActivityLevel.moderate,
          nutritionGoal: NutritionGoal.maintain,
          dailyCalorieTarget: 2000,
        );

        expect(empty.profileCompletionPercent, 0);
        expect(partial.profileCompletionPercent, 50);
        expect(complete.profileCompletionPercent, 100);
      });
    });

    group('Propiedades de display', () {
      test('initials genera iniciales correctas', () {
        expect(createTestProfile(displayName: 'Juan Perez').initials, 'JP');
        expect(createTestProfile(displayName: 'Maria').initials, 'M');
        expect(
            createTestProfile(displayName: 'Ana Maria Lopez').initials, 'AL');
      });

      test('locationFormatted formatea ubicacion', () {
        expect(
            createTestProfile(city: 'Quito', country: 'Ecuador')
                .locationFormatted,
            'Quito, Ecuador');
        expect(
            createTestProfile(country: 'Ecuador').locationFormatted, 'Ecuador');
        expect(createTestProfile(city: 'Quito').locationFormatted, 'Quito');
        expect(createTestProfile().locationFormatted, isNull);
      });
    });

    group('Serializacion JSON', () {
      test('toJson convierte correctamente', () {
        final profile = createTestProfile(
          displayName: 'Test User',
          gender: Gender.male,
          activityLevel: ActivityLevel.moderate,
        );

        final json = profile.toJson();

        expect(json['id'], 'test-id');
        expect(json['email'], 'test@example.com');
        expect(json['displayName'], 'Test User');
        expect(json['gender'], 'male');
        expect(json['activityLevel'], 'moderate');
      });

      test('fromJson parsea correctamente', () {
        final json = {
          'id': 'json-id',
          'email': 'json@example.com',
          'displayName': 'JSON User',
          'gender': 'female',
          'weightKg': 65.0,
          'heightCm': 165.0,
          'activityLevel': 'light',
          'nutritionGoal': 'maintain',
          'createdAt': now.toIso8601String(),
          'updatedAt': now.toIso8601String(),
          'onboardingCompleted': true,
        };

        final profile = UserProfile.fromJson(json);

        expect(profile.id, 'json-id');
        expect(profile.email, 'json@example.com');
        expect(profile.displayName, 'JSON User');
        expect(profile.gender, Gender.female);
        expect(profile.weightKg, 65.0);
        expect(profile.activityLevel, ActivityLevel.light);
        expect(profile.nutritionGoal, NutritionGoal.maintain);
        expect(profile.onboardingCompleted, isTrue);
      });

      test('fromJson maneja valores faltantes', () {
        final json = {
          'id': 'minimal-id',
          'email': 'minimal@example.com',
        };

        final profile = UserProfile.fromJson(json);

        expect(profile.id, 'minimal-id');
        expect(profile.displayName, 'Usuario');
        expect(profile.gender, isNull);
        expect(profile.onboardingCompleted, isFalse);
      });

      test('toJson y fromJson son inversos', () {
        final original = createTestProfile(
          displayName: 'Round Trip',
          gender: Gender.male,
          country: 'Ecuador',
          weightKg: 75,
          heightCm: 180,
          activityLevel: ActivityLevel.active,
          nutritionGoal: NutritionGoal.gainMuscle,
          dailyCalorieTarget: 2500,
          onboardingCompleted: true,
        );

        final json = original.toJson();
        final restored = UserProfile.fromJson(json);

        expect(restored.id, original.id);
        expect(restored.email, original.email);
        expect(restored.displayName, original.displayName);
        expect(restored.gender, original.gender);
        expect(restored.country, original.country);
        expect(restored.weightKg, original.weightKg);
        expect(restored.activityLevel, original.activityLevel);
        expect(restored.nutritionGoal, original.nutritionGoal);
        expect(restored.dailyCalorieTarget, original.dailyCalorieTarget);
        expect(restored.onboardingCompleted, original.onboardingCompleted);
      });
    });

    group('copyWith', () {
      test('crea copia con valores modificados', () {
        final original = createTestProfile(displayName: 'Original');
        final modified =
            original.copyWith(displayName: 'Modified', weightKg: 80);

        expect(modified.displayName, 'Modified');
        expect(modified.weightKg, 80);
        expect(modified.email, original.email);
      });

      test('clear flags funcionan correctamente', () {
        final original = createTestProfile(
          photoUrl: 'url',
          weightKg: 70,
          gender: Gender.male,
        );

        final cleared = original.copyWith(
          clearPhotoUrl: true,
          clearWeightKg: true,
          clearGender: true,
        );

        expect(cleared.photoUrl, isNull);
        expect(cleared.weightKg, isNull);
        expect(cleared.gender, isNull);
      });
    });

    group('Equality', () {
      test('profiles con mismo id son iguales', () {
        final profile1 =
            createTestProfile(id: 'same-id', displayName: 'User 1');
        final profile2 =
            createTestProfile(id: 'same-id', displayName: 'User 2');

        expect(profile1 == profile2, isTrue);
        expect(profile1.hashCode, equals(profile2.hashCode));
      });

      test('profiles con diferente id son diferentes', () {
        final profile1 = createTestProfile(id: 'id-1');
        final profile2 = createTestProfile(id: 'id-2');

        expect(profile1 == profile2, isFalse);
      });
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // TESTS PARA Gender
  // ═══════════════════════════════════════════════════════════════════════════

  group('Gender', () {
    test('displayName retorna nombres correctos', () {
      expect(Gender.male.displayName, 'Masculino');
      expect(Gender.female.displayName, 'Femenino');
      expect(Gender.other.displayName, 'Otro');
      expect(Gender.preferNotToSay.displayName, 'Prefiero no decir');
    });

    test('fromString parsea valores validos', () {
      expect(Gender.fromString('male'), Gender.male);
      expect(Gender.fromString('female'), Gender.female);
      expect(Gender.fromString('other'), Gender.other);
      expect(Gender.fromString('prefernotosay'), Gender.preferNotToSay);
      expect(Gender.fromString('prefer_not_to_say'), Gender.preferNotToSay);
    });

    test('fromString es case insensitive', () {
      expect(Gender.fromString('MALE'), Gender.male);
      expect(Gender.fromString('Female'), Gender.female);
    });

    test('fromString retorna null para valores invalidos', () {
      expect(Gender.fromString('invalid'), isNull);
      expect(Gender.fromString(''), isNull);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // TESTS PARA ActivityLevel
  // ═══════════════════════════════════════════════════════════════════════════

  group('ActivityLevel', () {
    test('displayName retorna nombres correctos', () {
      expect(ActivityLevel.sedentary.displayName, 'Sedentario');
      expect(ActivityLevel.light.displayName, 'Ligeramente activo');
      expect(ActivityLevel.moderate.displayName, 'Moderadamente activo');
      expect(ActivityLevel.active.displayName, 'Activo');
      expect(ActivityLevel.veryActive.displayName, 'Muy activo');
    });

    test('description retorna descripciones correctas', () {
      expect(ActivityLevel.sedentary.description, contains('ningún ejercicio'));
      expect(ActivityLevel.active.description, contains('6-7 días'));
    });

    test('multiplier retorna valores correctos', () {
      expect(ActivityLevel.sedentary.multiplier, 1.2);
      expect(ActivityLevel.light.multiplier, 1.375);
      expect(ActivityLevel.moderate.multiplier, 1.55);
      expect(ActivityLevel.active.multiplier, 1.725);
      expect(ActivityLevel.veryActive.multiplier, 1.9);
    });

    test('fromString parsea valores validos', () {
      expect(ActivityLevel.fromString('sedentary'), ActivityLevel.sedentary);
      expect(ActivityLevel.fromString('moderate'), ActivityLevel.moderate);
      expect(ActivityLevel.fromString('veryactive'), ActivityLevel.veryActive);
      expect(ActivityLevel.fromString('very_active'), ActivityLevel.veryActive);
    });

    test('fromString retorna null para valores invalidos', () {
      expect(ActivityLevel.fromString('invalid'), isNull);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // TESTS PARA NutritionGoal
  // ═══════════════════════════════════════════════════════════════════════════

  group('NutritionGoal', () {
    test('displayName retorna nombres correctos', () {
      expect(NutritionGoal.loseWeight.displayName, 'Perder peso');
      expect(NutritionGoal.maintain.displayName, 'Mantener peso');
      expect(NutritionGoal.gainMuscle.displayName, 'Ganar músculo');
    });

    test('description retorna descripciones correctas', () {
      expect(NutritionGoal.loseWeight.description, contains('Déficit'));
      expect(NutritionGoal.maintain.description, contains('Balance'));
      expect(NutritionGoal.gainMuscle.description, contains('Superávit'));
    });

    test('fromString parsea valores validos', () {
      expect(NutritionGoal.fromString('loseweight'), NutritionGoal.loseWeight);
      expect(NutritionGoal.fromString('lose_weight'), NutritionGoal.loseWeight);
      expect(NutritionGoal.fromString('maintain'), NutritionGoal.maintain);
      expect(NutritionGoal.fromString('gainmuscle'), NutritionGoal.gainMuscle);
      expect(NutritionGoal.fromString('gain_muscle'), NutritionGoal.gainMuscle);
    });

    test('fromString retorna null para valores invalidos', () {
      expect(NutritionGoal.fromString('invalid'), isNull);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // TESTS PARA BmiCategory
  // ═══════════════════════════════════════════════════════════════════════════

  group('BmiCategory', () {
    test('displayName retorna nombres correctos', () {
      expect(BmiCategory.underweight.displayName, 'Bajo peso');
      expect(BmiCategory.normal.displayName, 'Normal');
      expect(BmiCategory.overweight.displayName, 'Sobrepeso');
      expect(BmiCategory.obese.displayName, 'Obesidad');
    });

    test('range retorna rangos correctos', () {
      expect(BmiCategory.underweight.range, '< 18.5');
      expect(BmiCategory.normal.range, '18.5 - 24.9');
      expect(BmiCategory.overweight.range, '25 - 29.9');
      expect(BmiCategory.obese.range, '>= 30');
    });
  });
}

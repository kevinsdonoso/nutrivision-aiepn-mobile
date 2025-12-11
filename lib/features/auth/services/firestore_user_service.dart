// ╔═══════════════════════════════════════════════════════════════════════════════╗
// ║                       firestore_user_service.dart                             ║
// ║                  Servicio de usuarios en Cloud Firestore                      ║
// ╠═══════════════════════════════════════════════════════════════════════════════╣
// ║  CRUD de perfiles de usuario en Firestore.                                    ║
// ║  Gestiona la persistencia de datos de UserProfile.                            ║
// ╚═══════════════════════════════════════════════════════════════════════════════╝

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/exceptions/app_exceptions.dart';
import '../../../data/models/user_profile.dart';

/// Servicio para operaciones CRUD de usuarios en Firestore.
///
/// Maneja la persistencia de perfiles de usuario en la colección 'users'.
///
/// Estructura en Firestore:
/// ```
/// users/
///   {userId}/
///     - email
///     - displayName
///     - photoUrl
///     - birthDate
///     - gender
///     - ...
/// ```
///
/// Ejemplo de uso:
/// ```dart
/// final userService = FirestoreUserService();
/// final profile = await userService.getUserProfile('user123');
/// ```
class FirestoreUserService {
  /// Instancia de Firestore
  final FirebaseFirestore _firestore;

  /// Nombre de la colección de usuarios
  static const String _usersCollection = 'users';

  /// Constructor con inyección de dependencia opcional.
  FirestoreUserService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Referencia a la colección de usuarios.
  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection(_usersCollection);

  /// Referencia a un documento de usuario específico.
  DocumentReference<Map<String, dynamic>> _userDoc(String userId) =>
      _usersRef.doc(userId);

  // ═══════════════════════════════════════════════════════════════════════════
  // OPERACIONES DE LECTURA
  // ═══════════════════════════════════════════════════════════════════════════

  /// Obtiene el perfil de un usuario por su ID.
  ///
  /// [userId] ID del usuario (Firebase Auth UID)
  ///
  /// Returns: Perfil del usuario o null si no existe
  /// Throws: [ProfileException] si hay error de red/base de datos
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final doc = await _userDoc(userId).get();

      if (!doc.exists || doc.data() == null) {
        return null;
      }

      return UserProfile.fromJson({
        'id': doc.id,
        ...doc.data()!,
      });
    } on FirebaseException catch (e) {
      throw ProfileException(
        message: 'Error al obtener perfil: ${e.message}',
        code: 'FIRESTORE_GET_ERROR',
        originalError: e,
      );
    } catch (e) {
      if (e is ProfileException) rethrow;
      throw ProfileException(
        message: 'Error al obtener perfil: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Verifica si existe un perfil para el usuario.
  ///
  /// [userId] ID del usuario
  ///
  /// Returns: true si el perfil existe
  Future<bool> profileExists(String userId) async {
    try {
      final doc = await _userDoc(userId).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  /// Stream del perfil de usuario (actualizaciones en tiempo real).
  ///
  /// [userId] ID del usuario
  ///
  /// Returns: Stream que emite el perfil actualizado
  Stream<UserProfile?> watchUserProfile(String userId) {
    return _userDoc(userId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      return UserProfile.fromJson({
        'id': doc.id,
        ...doc.data()!,
      });
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // OPERACIONES DE ESCRITURA
  // ═══════════════════════════════════════════════════════════════════════════

  /// Crea un nuevo perfil de usuario.
  ///
  /// [profile] Perfil a crear
  ///
  /// Returns: Perfil creado
  /// Throws: [ProfileException] si el perfil ya existe o hay error
  Future<UserProfile> createUserProfile(UserProfile profile) async {
    try {
      // Verificar si ya existe
      final exists = await profileExists(profile.id);
      if (exists) {
        throw ProfileException(
          message: 'El perfil ya existe',
          code: 'PROFILE_ALREADY_EXISTS',
        );
      }

      final data = profile.toJson();
      data.remove('id'); // No guardar el ID dentro del documento

      await _userDoc(profile.id).set(data);

      return profile;
    } on FirebaseException catch (e) {
      throw ProfileException(
        message: 'Error al crear perfil: ${e.message}',
        code: 'FIRESTORE_CREATE_ERROR',
        originalError: e,
      );
    } catch (e) {
      if (e is ProfileException) rethrow;
      throw ProfileException(
        message: 'Error al crear perfil: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Actualiza un perfil de usuario existente.
  ///
  /// [profile] Perfil con los datos actualizados
  ///
  /// Returns: Perfil actualizado
  /// Throws: [ProfileNotFoundException] si el perfil no existe
  /// Throws: [ProfileUpdateException] si hay error al actualizar
  Future<UserProfile> updateUserProfile(UserProfile profile) async {
    try {
      // Verificar que existe
      final exists = await profileExists(profile.id);
      if (!exists) {
        throw const ProfileNotFoundException();
      }

      final data = profile.toJson();
      data.remove('id');
      data['updatedAt'] = DateTime.now().toIso8601String();

      await _userDoc(profile.id).update(data);

      return profile.copyWith(updatedAt: DateTime.now());
    } on FirebaseException catch (e) {
      throw ProfileUpdateException(
        message: 'Error al actualizar perfil: ${e.message}',
        originalError: e,
      );
    } catch (e) {
      if (e is ProfileException) rethrow;
      throw ProfileUpdateException(
        message: 'Error al actualizar perfil: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Actualiza campos específicos del perfil.
  ///
  /// [userId] ID del usuario
  /// [updates] Map con los campos a actualizar
  ///
  /// Throws: [ProfileUpdateException] si hay error
  Future<void> updateProfileFields(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    try {
      updates['updatedAt'] = DateTime.now().toIso8601String();
      await _userDoc(userId).update(updates);
    } on FirebaseException catch (e) {
      throw ProfileUpdateException(
        message: 'Error al actualizar perfil: ${e.message}',
        originalError: e,
      );
    } catch (e) {
      throw ProfileUpdateException(
        message: 'Error al actualizar perfil: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Marca el onboarding como completado.
  ///
  /// [userId] ID del usuario
  Future<void> completeOnboarding(String userId) async {
    await updateProfileFields(userId, {'onboardingCompleted': true});
  }

  /// Actualiza la URL de la foto de perfil.
  ///
  /// [userId] ID del usuario
  /// [photoUrl] Nueva URL de la foto
  Future<void> updatePhotoUrl(String userId, String photoUrl) async {
    await updateProfileFields(userId, {'photoUrl': photoUrl});
  }

  /// Actualiza los datos nutricionales del perfil.
  ///
  /// [userId] ID del usuario
  /// [weightKg] Peso en kg
  /// [heightCm] Altura en cm
  /// [activityLevel] Nivel de actividad
  /// [nutritionGoal] Meta nutricional
  /// [dailyCalorieTarget] Calorías objetivo
  Future<void> updateNutritionData(
    String userId, {
    double? weightKg,
    double? heightCm,
    ActivityLevel? activityLevel,
    NutritionGoal? nutritionGoal,
    int? dailyCalorieTarget,
  }) async {
    final updates = <String, dynamic>{};

    if (weightKg != null) updates['weightKg'] = weightKg;
    if (heightCm != null) updates['heightCm'] = heightCm;
    if (activityLevel != null) updates['activityLevel'] = activityLevel.name;
    if (nutritionGoal != null) updates['nutritionGoal'] = nutritionGoal.name;
    if (dailyCalorieTarget != null) {
      updates['dailyCalorieTarget'] = dailyCalorieTarget;
    }

    if (updates.isNotEmpty) {
      await updateProfileFields(userId, updates);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // OPERACIONES DE ELIMINACIÓN
  // ═══════════════════════════════════════════════════════════════════════════

  /// Elimina el perfil de un usuario.
  ///
  /// ADVERTENCIA: Esta acción es irreversible.
  ///
  /// [userId] ID del usuario
  ///
  /// Throws: [ProfileException] si hay error
  Future<void> deleteUserProfile(String userId) async {
    try {
      await _userDoc(userId).delete();
    } on FirebaseException catch (e) {
      throw ProfileException(
        message: 'Error al eliminar perfil: ${e.message}',
        code: 'FIRESTORE_DELETE_ERROR',
        originalError: e,
      );
    } catch (e) {
      throw ProfileException(
        message: 'Error al eliminar perfil: ${e.toString()}',
        originalError: e,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UTILIDADES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Crea o actualiza un perfil (upsert).
  ///
  /// Si el perfil existe, lo actualiza.
  /// Si no existe, lo crea.
  ///
  /// [profile] Perfil a guardar
  Future<UserProfile> saveUserProfile(UserProfile profile) async {
    final exists = await profileExists(profile.id);
    if (exists) {
      return updateUserProfile(profile);
    } else {
      return createUserProfile(profile);
    }
  }
}

import 'dart:convert';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../models/location_model.dart';
import '../models/class_model.dart';
import '../models/academic_models.dart';
import '../core/utils/app_utils.dart';
import 'session_controller.dart';
import 'attendance_controller.dart';

class AuthController extends GetxController {
  final AuthService _authService = AuthService();

  var isLoading = false.obs;
  var user = Rxn<UserModel>();
  var locations = <LocationModel>[].obs;
  var classes = <ClassModel>[].obs;
  
  // Academic Data
  var academicYears = <AcademicYearModel>[].obs;
  var filieres = <FiliereModel>[].obs;
  var levels = <LevelModel>[].obs;
  var parcours = <ParcoursModel>[].obs;
  var matters = <MatterModel>[].obs;

  Future<void> fetchAcademicData() async {
    academicYears.assignAll(await _authService.getAcademicYears());
    filieres.assignAll(await _authService.getFilieres());
    levels.assignAll(await _authService.getLevels());
    matters.assignAll(await _authService.getMatters());
  }

  Future<void> fetchParcours(String filiereId) async {
    parcours.assignAll(await _authService.getParcours(filiereId));
  }

  // --- CRUD ACADEMIC ---

  Future<bool> addAcademicYear(String nom) async {
    final success = await _authService.addAcademicYear(nom);
    if (success) await fetchAcademicData();
    return success;
  }

  Future<bool> updateAcademicYear(String id, String nom) async {
    final success = await _authService.updateAcademicYear(id, nom);
    if (success) await fetchAcademicData();
    return success;
  }

  Future<bool> deleteAcademicYear(String id) async {
    final success = await _authService.deleteAcademicYear(id);
    if (success) await fetchAcademicData();
    return success;
  }

  Future<bool> addFiliere(String nom) async {
    final success = await _authService.addFiliere(nom);
    if (success) await fetchAcademicData();
    return success;
  }

  Future<bool> updateFiliere(String id, String nom) async {
    final success = await _authService.updateFiliere(id, nom);
    if (success) await fetchAcademicData();
    return success;
  }

  Future<bool> deleteFiliere(String id) async {
    final success = await _authService.deleteFiliere(id);
    if (success) await fetchAcademicData();
    return success;
  }

  Future<bool> addLevel(String nom) async {
    final success = await _authService.addLevel(nom);
    if (success) await fetchAcademicData();
    return success;
  }

  Future<bool> updateLevel(String id, String nom) async {
    final success = await _authService.updateLevel(id, nom);
    if (success) await fetchAcademicData();
    return success;
  }

  Future<bool> deleteLevel(String id) async {
    final success = await _authService.deleteLevel(id);
    if (success) await fetchAcademicData();
    return success;
  }

  Future<bool> addParcours(String nom, String filiereId) async {
    final success = await _authService.addParcours(nom, filiereId);
    if (success) await fetchAcademicData();
    return success;
  }

  Future<bool> updateParcours(String id, String nom, String filiereId) async {
    final success = await _authService.updateParcours(id, nom, filiereId);
    if (success) await fetchAcademicData();
    return success;
  }

  Future<bool> deleteParcours(String id) async {
    final success = await _authService.deleteParcours(id);
    if (success) await fetchAcademicData();
    return success;
  }

  Future<bool> addMatter(String nom, String code) async {
    final success = await _authService.addMatter(nom, code);
    if (success) await fetchAcademicData();
    return success;
  }

  Future<bool> updateMatter(String id, String nom, String code) async {
    final success = await _authService.updateMatter(id, nom, code);
    if (success) await fetchAcademicData();
    return success;
  }

  Future<bool> deleteMatter(String id) async {
    final success = await _authService.deleteMatter(id);
    if (success) await fetchAcademicData();
    return success;
  }

  @override
  void onInit() {
    super.onInit();
    checkAuth();
    loadCachedClasses();
    fetchLocations();
    fetchAcademicData(); // Nouveau
  }

  Future<void> checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token != null) {
      final loadedUser = await _authService.getProfile(token);
      if (loadedUser != null) {
        user.value = loadedUser;
        _triggerDataFetch();
      } else {
        // Token expiré ou invalide
        await prefs.remove('auth_token');
      }
    }
  }

  void _triggerDataFetch() {
    if (user.value == null) return;

    // Charger les sessions
    Get.find<SessionController>().fetchSessions();

    // Charger l'historique si c'est un étudiant
    if (user.value!.role == UserRole.ETUDIANT) {
      Get.find<AttendanceController>().fetchAttendanceForStudent(
        user.value!.id,
      );
    }
    // Charger les lieux/salles
    fetchLocations();
  }

  /// Méthode publique pour déclencher le chargement des données après connexion
  void triggerDataFetch() {
    _triggerDataFetch();
  }

  Future<bool> login(String email, String password) async {
    isLoading.value = true;
    try {
      final loggedUser = await _authService.login(email, password);
      if (loggedUser != null) {
        // Enregistrer le token
        if (loggedUser.token != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', loggedUser.token!);

          // Récupérer le profil complet via /auth/me
          final fullProfile = await _authService.getProfile(loggedUser.token!);
          if (fullProfile != null) {
            user.value = fullProfile;
          } else {
            user.value = loggedUser;
          }
        } else {
          user.value = loggedUser;
        }

        _triggerDataFetch();
        // Charger les classes après connexion réussie
        await fetchClasses();
        return true;
      }
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> registerStudent({
    required String nom,
    required String prenom,
    required String email,
    required String password,
    required String matricule,
    required String classeId,
    required String niveau,
    required String parcours,
  }) async {
    isLoading.value = true;
    try {
      final registeredUser = await _authService.registerStudent(
        nom: nom,
        prenom: prenom,
        email: email,
        password: password,
        matricule: matricule,
        classeId: classeId,
        niveau: niveau,
        parcours: parcours,
      );
      if (registeredUser != null) {
        // Enregistrer le token si présent
        if (registeredUser.token != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', registeredUser.token!);

          // Récupérer le profil complet via /auth/me
          final fullProfile = await _authService.getProfile(
            registeredUser.token!,
          );
          if (fullProfile != null) {
            user.value = fullProfile;
          } else {
            user.value = registeredUser;
          }
        } else {
          user.value = registeredUser;
        }

        _triggerDataFetch();
        return true;
      }
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  void logout() async {
    user.value = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    Get.offAllNamed('/login');
  }

  Future<void> fetchLocations() async {
    final list = await _authService.getLocations();
    locations.assignAll(list);
  }

  Future<void> fetchClasses() async {
    try {
      print('🔄 Début de la récupération des classes...');
      final list = await _authService.getClasses();
      print('📋 Classes récupérées depuis l\'API: ${list.length}');

      if (list.isNotEmpty) {
        classes.assignAll(list);
        print('✅ ${list.length} classes assignées au controller');
        // Sauvegarder les classes dans le stockage local
        await _saveClassesToCache(list);
        print('💾 Classes sauvegardées dans le cache');
      } else {
        print('⚠️ Liste vide depuis l\'API, chargement depuis le cache...');
        // Si la liste est vide, charger depuis le cache
        await loadCachedClasses();
        print('📦 Classes chargées depuis le cache: ${classes.length}');
      }
    } catch (e) {
      print('❌ Erreur lors de fetchClasses: $e');
      AppUtils.handleError(e);
      // En cas d'erreur, charger depuis le cache
      print('📦 Tentative de chargement depuis le cache après erreur...');
      await loadCachedClasses();
      print('📦 Classes disponibles après chargement cache: ${classes.length}');
    }
  }

  /// Charge les classes depuis le cache local
  Future<void> loadCachedClasses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final classesJson = prefs.getString('cached_classes');
      if (classesJson != null) {
        print('📦 Cache trouvé, parsing...');
        final List<dynamic> decoded = jsonDecode(classesJson);
        final cachedClasses =
            decoded
                .map(
                  (item) => ClassModel.fromJson(item as Map<String, dynamic>),
                )
                .toList();
        if (cachedClasses.isNotEmpty) {
          print('✅ ${cachedClasses.length} classes chargées depuis le cache');
          classes.assignAll(cachedClasses);
        } else {
          print('⚠️ Cache vide après parsing');
        }
      } else {
        print('⚠️ Aucun cache trouvé');
      }
    } catch (e) {
      print('❌ Erreur lors du chargement du cache: $e');
    }
  }

  /// Sauvegarde les classes dans le cache local
  Future<void> _saveClassesToCache(List<ClassModel> classesList) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final classesJson = jsonEncode(
        classesList.map((cls) => cls.toJson()).toList(),
      );
      await prefs.setString('cached_classes', classesJson);
    } catch (e) {
      print('Error saving classes to cache: $e');
    }
  }
}

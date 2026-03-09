import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'auth_controller.dart';

class StartupController extends GetxController {
  final AuthService _authService = AuthService();
  final AuthController _authController = Get.find<AuthController>();

  var loadingStatus = "Initialisation...".obs;
  var progress = 0.0.obs;
  var hasError = false.obs;
  var errorMessage = "".obs;

  @override
  void onInit() {
    super.onInit();
    startInitialization();
  }

  Future<void> startInitialization() async {
    try {
      hasError.value = false;
      progress.value = 0.1;

      // 1. Préférence Onboarding
      loadingStatus.value = "Chargement des préférences...";
      final prefs = await SharedPreferences.getInstance();
      final bool onboardingDone = prefs.getBool('onboarding_done') ?? false;
      progress.value = 0.3;
      await Future.delayed(const Duration(milliseconds: 500));

      // 2. Charger les données globales (Classes/Locations)
      loadingStatus.value = "Récupération des salles et classes...";
      await _authController.fetchLocations();
      await _authController.fetchClasses();
      progress.value = 0.6;
      await Future.delayed(const Duration(milliseconds: 500));

      // 3. Vérifier la session (Token)
      loadingStatus.value = "Vérification de la session...";
      final String? token = prefs.getString('auth_token');

      if (token != null && token.isNotEmpty) {
        try {
          final profile = await _authService.getProfile(token);
          if (profile != null) {
            _authController.user.value = profile;
            // Déclencher le chargement des données
            _authController.triggerDataFetch();
            loadingStatus.value = "Session restaurée !";
            progress.value = 0.9;
            await Future.delayed(const Duration(milliseconds: 500));
          } else {
            // Token invalide ou expiré
            await prefs.remove('auth_token');
            _authController.user.value = null;
          }
        } catch (e) {
          // Erreur lors de la vérification du token
          print('Erreur lors de la vérification du token: $e');
          await prefs.remove('auth_token');
          _authController.user.value = null;
        }
      }
      progress.value = 1.0;
      loadingStatus.value = "Démarrage...";
      await Future.delayed(const Duration(milliseconds: 500));

      // Navigation finale
      if (!onboardingDone) {
        Get.offAllNamed('/onboarding');
      } else if (_authController.user.value != null) {
        // Rediriger vers le dashboard approprié selon le rôle
        final role = _authController.user.value!.role;
        if (role == UserRole.ETUDIANT) {
          Get.offAllNamed('/student/dashboard');
        } else if (role == UserRole.ENSEIGNANT) {
          Get.offAllNamed('/teacher/dashboard');
        } else if (role == UserRole.ADMIN) {
          Get.offAllNamed('/admin/dashboard');
        } else {
          Get.offAllNamed('/login');
        }
      } else {
        Get.offAllNamed('/login');
      }
    } catch (e) {
      hasError.value = true;
      errorMessage.value =
          "Erreur de connexion : Impossible de joindre le serveur.";
      loadingStatus.value = "Échec du chargement";
    }
  }

  void retry() {
    startInitialization();
  }
}

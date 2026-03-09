import 'package:get/get.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AdminStatsController extends GetxController {
  final AuthService _authService = AuthService();

  var isLoading = false.obs;
  var studentsCount = 0.obs;
  var teachersCount = 0.obs;
  var locationsCount = 0.obs;
  var classesCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    fetchStats();
  }

  Future<void> fetchStats() async {
    isLoading.value = true;
    try {
      // Récupérer les utilisateurs
      final users = await _authService.getUsers();
      studentsCount.value = users.where((u) => u.role == UserRole.ETUDIANT).length;
      teachersCount.value = users.where((u) => u.role == UserRole.ENSEIGNANT).length;

      // Récupérer les locations
      final locations = await _authService.getLocations();
      locationsCount.value = locations.length;

      // Récupérer les classes
      final classes = await _authService.getClasses();
      classesCount.value = classes.length;
    } catch (e) {
      print('Error fetching admin stats: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void refreshStats() {
    fetchStats();
  }
}

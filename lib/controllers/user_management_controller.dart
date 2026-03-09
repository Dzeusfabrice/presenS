import 'package:get/get.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class UserManagementController extends GetxController {
  final AuthService _authService = AuthService();

  var isLoading = false.obs;
  var usersList = <UserModel>[].obs;
  var locations = <dynamic>[].obs;
  var classes = <dynamic>[].obs;
  var selectedClassFilter = Rxn<String>(
    null,
  ); // Filtre par classe pour les étudiants
  var searchQuery = ''.obs; // Texte de recherche

  @override
  void onInit() {
    super.onInit();
    fetchUsers();
    fetchLocations();
    fetchClasses();
  }

  Future<void> fetchClasses() async {
    final list = await _authService.getClasses();
    classes.assignAll(list);
  }

  Future<void> fetchLocations() async {
    final list = await _authService.getLocations();
    locations.assignAll(list);
  }

  Future<void> fetchUsers() async {
    isLoading.value = true;
    try {
      final list = await _authService.getUsers();
      usersList.assignAll(list);
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> addUser(UserModel user) async {
    isLoading.value = true;
    try {
      final success = await _authService.addUser(user);
      if (success) {
        await fetchUsers();
      }
      return success;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateUser(UserModel user) async {
    isLoading.value = true;
    try {
      final success = await _authService.updateUser(user);
      if (success) {
        await fetchUsers();
      }
      return success;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> deleteUser(String id) async {
    isLoading.value = true;
    try {
      final success = await _authService.deleteUser(id);
      if (success) {
        await fetchUsers();
      }
      return success;
    } finally {
      isLoading.value = false;
    }
  }
}

import 'package:get/get.dart';
import '../models/location_model.dart';
import '../services/auth_service.dart';

class LocationController extends GetxController {
  final AuthService _authService = AuthService();

  var isLoading = false.obs;
  var locations = <LocationModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchLocations();
  }

  Future<void> fetchLocations() async {
    isLoading.value = true;
    try {
      final list = await _authService.getLocations();
      locations.assignAll(list);
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> addLocation(LocationModel location) async {
    isLoading.value = true;
    try {
      final success = await _authService.addLocation(location);
      if (success) {
        await fetchLocations();
      }
      return success;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateLocation(LocationModel location) async {
    isLoading.value = true;
    try {
      final success = await _authService.updateLocation(location);
      if (success) {
        await fetchLocations();
      }
      return success;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> deleteLocation(String id) async {
    isLoading.value = true;
    try {
      final success = await _authService.deleteLocation(id);
      if (success) {
        await fetchLocations();
      }
      return success;
    } finally {
      isLoading.value = false;
    }
  }
}

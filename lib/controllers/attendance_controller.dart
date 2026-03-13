import 'package:get/get.dart';
import '../models/attendance_model.dart';
import '../services/auth_service.dart';

class AttendanceController extends GetxController {
  final AuthService _authService = AuthService();

  var isLoading = false.obs;
  var attendances = <AttendanceModel>[].obs;

  Future<void> fetchAttendanceForSession(String sessionId) async {
    isLoading.value = true;
    try {
      final list = await _authService.getAttendanceForSession(sessionId);
      attendances.assignAll(list);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchAttendanceForStudent(String etudiantId) async {
    isLoading.value = true;
    try {
      final list = await _authService.getAttendanceForStudent(etudiantId);
      attendances.assignAll(list);
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> markPresence({
    required String sessionId,
    required String etudiantId,
    double? lat,
    double? lon,
    bool isMocked = false,
  }) async {
    isLoading.value = true;
    try {
      final attendance = AttendanceModel(
        id: "att-${DateTime.now().millisecondsSinceEpoch}",
        sessionId: sessionId,
        etudiantId: etudiantId,
        timestamp: DateTime.now(),
        latClient: lat,
        longClient: lon,
        statut: AttendanceStatus.PRESENT,
        isMocked: isMocked,
      );

      final success = await _authService.markAttendance(attendance);
      if (success) {
        await fetchAttendanceForSession(sessionId);
        return true;
      }
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateManualStatus({
    required String sessionId,
    required String etudiantId,
    required AttendanceStatus status,
    bool fetchAfter = true,
  }) async {
    if (fetchAfter) isLoading.value = true;
    try {
      final attendance = AttendanceModel(
        id: "att-${DateTime.now().millisecondsSinceEpoch}",
        sessionId: sessionId,
        etudiantId: etudiantId,
        timestamp: DateTime.now(),
        statut: status,
      );

      final success = await _authService.markAttendance(attendance, showToast: fetchAfter);
      if (success && fetchAfter) {
        await fetchAttendanceForSession(sessionId);
      }
      return success;
    } finally {
      if (fetchAfter) isLoading.value = false;
    }
  }

  Future<bool> updateBulkManualStatus({
    required String sessionId,
    required Map<String, AttendanceStatus> changes,
  }) async {
    isLoading.value = true;
    try {
      bool allSuccess = true;
      // On boucle sur les changements mais sans fetcher entre chaque
      for (var entry in changes.entries) {
        final success = await updateManualStatus(
          sessionId: sessionId,
          etudiantId: entry.key,
          status: entry.value,
          fetchAfter: false,
        );
        if (!success) allSuccess = false;
      }
      
      // On fetch une seule fois à la fin
      await fetchAttendanceForSession(sessionId);
      return allSuccess;
    } finally {
      isLoading.value = false;
    }
  }
}

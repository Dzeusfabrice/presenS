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
    double? lat,
    double? lon,
  }) async {
    isLoading.value = true;
    try {
      // Regrouper les étudiants par statut pour limiter le nombre d'appels API
      final Map<AttendanceStatus, List<String>> groups = {};
      for (var entry in changes.entries) {
        groups.putIfAbsent(entry.value, () => []).add(entry.key);
      }

      bool allSuccess = true;
      for (var entry in groups.entries) {
        final success = await _authService.markAttendanceBulk(
          sessionId,
          entry.value,
          entry.key,
          lat: lat,
          long: lon,
        );
        if (!success) allSuccess = false;
      }

      // On fetch une seule fois à la fin pour mettre à jour l'interface
      await fetchAttendanceForSession(sessionId);
      return allSuccess;
    } finally {
      isLoading.value = false;
    }
  }
}

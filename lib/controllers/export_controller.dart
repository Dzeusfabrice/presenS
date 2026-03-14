import 'package:get/get.dart';
import '../models/class_model.dart';
import '../models/session_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/export_service.dart';
import '../core/utils/app_utils.dart';

class ExportController extends GetxController {
  final AuthService _authService = AuthService();
  final ExportService _exportService = ExportService();

  var isLoadingList = false.obs;
  var classes = <ClassModel>[].obs;
  var sessions = <SessionModel>[].obs;
  var students = <UserModel>[].obs;

  // Sélections
  var selectedClassId = Rxn<String>();
  var selectedSessionId = Rxn<String>();
  var selectedStudentId = Rxn<String>();

  @override
  void onInit() {
    super.onInit();
    fetchData();
  }

  Future<void> fetchData() async {
    isLoadingList.value = true;
    try {
      final fetchedClasses = await _authService.getClasses();
      classes.assignAll(fetchedClasses);

      final fetchedSessions = await _authService.getSessions();
      sessions.assignAll(fetchedSessions);

      final fetchedUsers = await _authService.getUsers();
      students.assignAll(fetchedUsers.where((u) => u.role == UserRole.ETUDIANT));
    } catch (e) {
      print("Erreur lors de la récupération des données d'export: $e");
    } finally {
      isLoadingList.value = false;
    }
  }

  Future<void> exportStudents(String format) async {
    await _exportService.exportStudents(format, classId: selectedClassId.value);
  }

  Future<void> exportTeachers(String format) async {
    await _exportService.exportTeachers(format);
  }

  Future<void> exportLocations(String format) async {
    await _exportService.exportLocations(format);
  }

  Future<void> exportAttendance(String format) async {
    await _exportService.exportAttendance(format, classId: selectedClassId.value);
  }

  Future<void> exportSessionReport(String format) async {
    if (selectedSessionId.value == null) {
      AppUtils.showErrorToast("Veuillez sélectionner une séance");
      return;
    }
    await _exportService.downloadReport(selectedSessionId.value!, format);
  }

  Future<void> exportClassReport(String format) async {
    if (selectedClassId.value == null) {
      AppUtils.showErrorToast("Veuillez sélectionner une classe");
      return;
    }
    await _exportService.exportClassReport(format, selectedClassId.value!);
  }

  Future<void> exportStudentReport(String format) async {
    if (selectedStudentId.value == null) {
      AppUtils.showErrorToast("Veuillez sélectionner un étudiant");
      return;
    }
    await _exportService.exportStudentReport(format, selectedStudentId.value!);
  }
}

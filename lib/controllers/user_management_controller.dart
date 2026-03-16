import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart' as excel_lib;
import 'package:get/get.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../core/utils/app_utils.dart';

class UserManagementController extends GetxController {
  final AuthService _authService = AuthService();

  var isLoading = false.obs;
  var usersList = <UserModel>[].obs;
  var locations = <dynamic>[].obs;
  var classes = <dynamic>[].obs;
  var selectedClassFilter = Rxn<String>(null);
  var selectedFiliereFilter = Rxn<String>(null);
  var selectedLevelFilter = Rxn<String>(null);
  var searchQuery = ''.obs;

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

  Future<bool> addUsersBulk(List<UserModel> users) async {
    isLoading.value = true;
    try {
      final success = await _authService.addUsersBulk(users);
      if (success) {
        await fetchUsers();
      }
      return success;
    } finally {
      isLoading.value = false;
    }
  }

  // --- NOUVEAU : SYSTÈME D'IMPORTATION ROBUSTE ---

  Future<List<UserModel>?> processImportFile(PlatformFile file) async {
    if (file.bytes == null) return null;

    final extension = file.extension?.toLowerCase();
    List<List<dynamic>> rows = [];

    try {
      if (extension == 'csv') {
        // Décodage UTF-8 sécurisé
        String content = utf8.decode(file.bytes!, allowMalformed: true);
        
        // Détection automatique du séparateur
        String separator = content.contains(";") ? ";" : ",";
        rows = CsvToListConverter(fieldDelimiter: separator).convert(content);
      } else if (extension == 'xlsx' || extension == 'xls') {
        var excel = excel_lib.Excel.decodeBytes(file.bytes!);
        String sheetName = excel.tables.keys.first;
        var table = excel.tables[sheetName];
        if (table != null) {
          for (var row in table.rows) {
            rows.add(row.map((cell) => cell?.value?.toString() ?? "").toList());
          }
        }
      }
    } catch (e) {
      AppUtils.showErrorToast("Erreur de lecture du fichier : $e");
      return null;
    }

    if (rows.length < 2) {
      AppUtils.showErrorToast("Le fichier ne contient pas assez de données");
      return null;
    }

    // 1. Détection des en-têtes (Mapping intelligent)
    final headerRow = rows.first.map((e) => e.toString().toLowerCase().trim()).toList();
    
    int idxNom = _findHeaderIndex(headerRow, ['nom', 'last name', 'lastname', 'name', 'family name']);
    int idxPrenom = _findHeaderIndex(headerRow, ['prenom', 'first name', 'firstname', 'given name']);
    int idxEmail = _findHeaderIndex(headerRow, ['email', 'mail', 'e-mail', 'courriel']);
    int idxMatricule = _findHeaderIndex(headerRow, ['matricule', 'id', 'id_number', 'student_id', 'code']);
    int idxClasse = _findHeaderIndex(headerRow, ['classe', 'class', 'group', 'groupe', 'classe_id']);

    if (idxNom == -1 || idxPrenom == -1 || idxEmail == -1) {
      AppUtils.showErrorToast("Colonnes obligatoires manquantes : Nom, Prénom ou Email");
      return null;
    }

    List<UserModel> students = [];
    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty) continue;
      
      final email = _getRowValue(row, idxEmail);
      if (email.isEmpty || !GetUtils.isEmail(email)) continue;

      students.add(UserModel(
        id: "imp-${DateTime.now().millisecondsSinceEpoch}-$i",
        nom: _getRowValue(row, idxNom),
        prenom: _getRowValue(row, idxPrenom),
        email: email,
        role: UserRole.ETUDIANT,
        matricule: idxMatricule != -1 ? _getRowValue(row, idxMatricule) : "",
        classeId: idxClasse != -1 ? _getRowValue(row, idxClasse) : "",
        isActive: true,
      ));
    }

    return students;
  }

  int _findHeaderIndex(List<String> headers, List<String> keywords) {
    for (int i = 0; i < headers.length; i++) {
      final h = headers[i];
      if (keywords.any((k) => h.contains(k))) return i;
    }
    return -1;
  }

  String _getRowValue(List<dynamic> row, int index) {
    if (index >= 0 && index < row.length) {
      return row[index]?.toString().trim() ?? "";
    }
    return "";
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

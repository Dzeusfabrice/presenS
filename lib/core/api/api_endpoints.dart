class ApiEndpoints {
  static const String baseUrl =
      "https://attendance-backend.presens-app-backend.workers.dev";
  //   "https://attendance-backend.basilo-store-api.workers.dev";

  // --- AUTH ---
  static const String register = "$baseUrl/auth/register";
  static const String login = "$baseUrl/auth/login";
  static const String me = "$baseUrl/auth/me";
  static const String forgotPassword = "$baseUrl/auth/forgot-password";
  static const String resetPassword = "$baseUrl/auth/reset-password";

  // --- USERS ---
  static const String users = "$baseUrl/users";
  static const String usersBulk = "$baseUrl/users/bulk";
  static String userById(String id) => "$baseUrl/users/$id";
  static String userStatus(String id) => "$baseUrl/users/$id/status";

  // --- LOCATIONS ---
  static const String locations = "$baseUrl/locations";
  static String locationById(String id) => "$baseUrl/locations/$id";
  static String locationQRCode(String id) => "$baseUrl/locations/$id/qrcode";

  static const String classes = "$baseUrl/classes";
  static String classById(String id) => "$baseUrl/classes/$id";

  // --- SESSIONS ---
  static const String sessions = "$baseUrl/sessions";
  static String sessionById(String id) => "$baseUrl/sessions/$id";
  static String sessionStatus(String id) => "$baseUrl/sessions/$id/status";

  // --- ACADEMIC DATA ---
  static const String academicYears = "$baseUrl/annees";
  static String academicYearById(String id) => "$baseUrl/annees/$id";

  static const String filieres = "$baseUrl/filieres";
  static String filiereById(String id) => "$baseUrl/filieres/$id";

  static const String levels = "$baseUrl/niveaux";
  static String levelById(String id) => "$baseUrl/niveaux/$id";

  static const String matters = "$baseUrl/matieres";
  static String matterById(String id) => "$baseUrl/matieres/$id";

  static const String parcours = "$baseUrl/parcours";
  static String parcoursById(String id) => "$baseUrl/parcours/$id";
  static String parcoursByFiliere(String filiereId) =>
      "$parcours?filiere_id=$filiereId";

  // --- ATTENDANCE ---
  static const String attendanceMark = "$baseUrl/attendance/mark";
  static const String attendanceBulk = "$baseUrl/attendance/bulk";
  static String attendanceBySession(String sessionId) =>
      "$baseUrl/attendance/session/$sessionId";
  static String attendanceByStudent(String studentId) =>
      "$baseUrl/attendance/student/$studentId";
  static String attendanceById(String id) => "$baseUrl/attendance/$id";

  // --- REPORTS ---
  static String exportReport(String sessionId, String format) =>
      "$baseUrl/reports/export/$sessionId?format=$format";
      
  static String classReport(String classId, String format) =>
      "$baseUrl/reports/class/$classId?format=$format";
      
  static String studentReport(String studentId, String format) =>
      "$baseUrl/reports/student/$studentId?format=$format";

  // --- EXPORTS ---
  static String exportStudents(String format, {String? classId}) =>
      "$baseUrl/users/export?format=$format&role=ETUDIANT${classId != null ? '&classe_id=$classId' : ''}";
      
  static String exportTeachers(String format) =>
      "$baseUrl/users/export?format=$format&role=ENSEIGNANT";
      
  static String exportLocations(String format) =>
      "$baseUrl/users/export?format=$format&role=LOCATIONS"; // Souvent centralisé dans users/export ou une route spécifique

  // Route pour les présences globales (si différente de l'export par classe)
  static String exportAttendance(String format, {String? classId}) {
    if (classId != null) {
      return classReport(classId, format);
    }
    return "$baseUrl/users/export?format=$format&type=attendance"; // Ajusté pour éviter le 404 /exports/
  }

  // --- NOTIFICATIONS ---
  static const String sendNotification = "$baseUrl/notifications/send";

  // Headers Helper
  static Map<String, String> getHeaders([String? token]) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
}

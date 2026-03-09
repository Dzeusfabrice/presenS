class ApiEndpoints {
  static const String baseUrl =
      "https://attendance-backend.basilo-store-api.workers.dev";

  // --- AUTH ---
  static const String register = "$baseUrl/auth/register";
  static const String login = "$baseUrl/auth/login";
  static const String me = "$baseUrl/auth/me";
  static const String forgotPassword = "$baseUrl/auth/forgot-password";
  static const String resetPassword = "$baseUrl/auth/reset-password";

  // --- USERS ---
  static const String users = "$baseUrl/users";
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

  // --- ATTENDANCE ---
  static const String attendanceMark = "$baseUrl/attendance/mark";
  static String attendanceBySession(String sessionId) =>
      "$baseUrl/attendance/session/$sessionId";
  static String attendanceByStudent(String studentId) =>
      "$baseUrl/attendance/student/$studentId";
  static String attendanceById(String id) => "$baseUrl/attendance/$id";

  // --- REPORTS ---
  static String exportReport(String sessionId) =>
      "$baseUrl/reports/export/$sessionId";
  static String classReport(String classId) =>
      "$baseUrl/reports/class/$classId";
  static String studentReport(String studentId) =>
      "$baseUrl/reports/student/$studentId";
  
  // --- EXPORTS ---
  static String exportStudents(String format) =>
      "$baseUrl/exports/students?format=$format";
  static String exportTeachers(String format) =>
      "$baseUrl/exports/teachers?format=$format";
  static String exportLocations(String format) =>
      "$baseUrl/exports/locations?format=$format";
  static String exportAttendance(String format) =>
      "$baseUrl/exports/attendance?format=$format";

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

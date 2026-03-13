import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/attendance_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/session_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_modal.dart';
import '../../models/attendance_model.dart';
import '../../models/session_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';

class SessionRecapView extends StatefulWidget {
  final String sessionId;

  const SessionRecapView({Key? key, required this.sessionId}) : super(key: key);

  @override
  State<SessionRecapView> createState() => _SessionRecapViewState();
}

class _SessionRecapViewState extends State<SessionRecapView> {
  final SessionController _sessionController = Get.find<SessionController>();
  final AuthController _authController = Get.find<AuthController>();
  final AttendanceController _attendanceController = Get.put(
    AttendanceController(),
  );
  final AuthService _authService = AuthService();

  SessionModel? _session;
  List<UserModel> _students = [];
  List<AttendanceModel> _attendances = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _session = _sessionController.sessions.firstWhereOrNull(
      (s) => s.id == widget.sessionId,
    );

    if (_session == null) {
      setState(() => _isLoading = false);
      return;
    }

    // Charger les étudiants
    final List<UserModel> allStudents = [];
    for (final classId in _session!.classeIds) {
      final students = await _authService.getStudentsByClass(classId);
      allStudents.addAll(students);
    }

    // Charger les présences
    await _attendanceController.fetchAttendanceForSession(widget.sessionId);
    _attendances = _attendanceController.attendances.toList();

    setState(() {
      _students = allStudents;
      _isLoading = false;
    });
  }

  AttendanceStatus _getStudentStatus(String studentId) {
    final attendance = _attendances.firstWhereOrNull(
      (a) => a.etudiantId == studentId,
    );
    return attendance?.statut ?? AttendanceStatus.ABSENT;
  }

  int _getCountByStatus(AttendanceStatus status) {
    return _students.where((s) => _getStudentStatus(s.id) == status).length;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_session == null) {
      return const Scaffold(body: Center(child: Text("Séance introuvable")));
    }

    final location = _authController.locations.firstWhereOrNull(
      (loc) => loc.id == _session!.lieuId,
    );
    final locationName = location?.name ?? "Salle inconnue";

    final presentCount = _getCountByStatus(AttendanceStatus.PRESENT);
    final absentCount = _getCountByStatus(AttendanceStatus.ABSENT);
    final retardCount = _getCountByStatus(AttendanceStatus.RETARD);
    final totalCount = _students.length;

    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      appBar: AppBar(
        title: const Text(
          "Récapitulatif de Séance",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded, color: AppColors.primary),
            onPressed: _showExportOptions,
          ),
        ],
      ),
      body: Column(
        children: [
          // Header avec statistiques
          _buildHeader(
            locationName,
            presentCount,
            absentCount,
            retardCount,
            totalCount,
          ),

          // Liste des étudiants
          Expanded(child: _buildStudentsList()),
        ],
      ),
    );
  }

  Widget _buildHeader(
    String locationName,
    int presentCount,
    int absentCount,
    int retardCount,
    int totalCount,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryLight],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Informations de la séance
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _session!.matiere,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _session!.classeIds.map((id) {
                        final cls = (_session!.classes ?? []).firstWhereOrNull((c) => c.id == id) ??
                                   _authController.classes.firstWhereOrNull((c) => c.id == id);
                        if (cls == null) return id;
                        return "${cls.nom}${cls.niveau.isNotEmpty ? ' (${cls.niveau})' : ''}${cls.parcours.isNotEmpty ? ' - ${cls.parcours}' : ''}";
                      }).join(", "),
                      style: const TextStyle(color: Colors.white70, fontSize: 13, fontStyle: FontStyle.italic),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Colors.white70,
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          locationName,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 16),
                        if (_session!.heureDebut != null) ...[
                          const Icon(
                            Icons.access_time,
                            color: Colors.white70,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('HH:mm').format(_session!.heureDebut!),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Statistiques
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  "Total",
                  "$totalCount",
                  Colors.white70,
                  Icons.people_outline,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  "Présents",
                  "$presentCount",
                  Colors.greenAccent,
                  Icons.check_circle_outline,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  "Absents",
                  "$absentCount",
                  Colors.redAccent,
                  Icons.cancel_outlined,
                ),
              ),
              if (retardCount > 0) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    "Retards",
                    "$retardCount",
                    Colors.orangeAccent,
                    Icons.watch_later_outlined,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentsList() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // En-tête
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.backgroundGrey,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "LISTE DES ÉTUDIANTS",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "${_students.length} étudiants",
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Liste
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _students.length,
              itemBuilder: (context, index) {
                final student = _students[index];
                final status = _getStudentStatus(student.id);

                return _buildStudentRecapRow(student, status, index + 1);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentRecapRow(
    UserModel student,
    AttendanceStatus status,
    int number,
  ) {
    Color statusColor;
    String statusChar;

    switch (status) {
      case AttendanceStatus.PRESENT:
        statusColor = Colors.green;
        statusChar = "P";
        break;
      case AttendanceStatus.RETARD:
        statusColor = Colors.orange;
        statusChar = "R";
        break;
      case AttendanceStatus.ABSENT:
        statusColor = Colors.red;
        statusChar = "A";
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.withOpacity(0.1), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 25,
            child: Text(
              "$number.",
              style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
            ),
          ),
          Expanded(
            child: Text(
              "${student.nom.toUpperCase()} ${student.prenom}",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: statusColor.withOpacity(0.3)),
            ),
            child: Text(
              statusChar,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showExportOptions() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Exporter le rapport",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Téléchargez le récapitulatif de la séance",
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(
                Icons.table_chart_rounded,
                color: Colors.green,
                size: 32,
              ),
              title: const Text("Exportation Excel"),
              onTap: () {
                Get.back();
                AppModal.showInfo(
                  context: context,
                  title: "Export en cours",
                  message:
                      "Le téléchargement du fichier Excel a commencé. Vous serez notifié une fois le téléchargement terminé.",
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(
                Icons.picture_as_pdf_rounded,
                color: Colors.red,
                size: 32,
              ),
              title: const Text("Exportation PDF"),
              onTap: () {
                Get.back();
                AppModal.showInfo(
                  context: context,
                  title: "Export en cours",
                  message:
                      "Le téléchargement du fichier PDF a commencé. Vous serez notifié une fois le téléchargement terminé.",
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

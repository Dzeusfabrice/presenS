import 'dart:async';
import 'package:chrono/core/utils/app_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/session_controller.dart';
import '../../controllers/attendance_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_modal.dart';
import '../../models/session_model.dart';
import '../../models/attendance_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import 'session_recap_view.dart';
import 'class_attendance_monitor_view.dart';
import '../../models/class_model.dart';

class LiveMonitorView extends StatefulWidget {
  final String sessionId;

  const LiveMonitorView({Key? key, required this.sessionId}) : super(key: key);

  @override
  State<LiveMonitorView> createState() => _LiveMonitorViewState();
}

class _LiveMonitorViewState extends State<LiveMonitorView>
    with TickerProviderStateMixin {
  final SessionController _sessionController = Get.find<SessionController>();
  final AuthController _authController = Get.find<AuthController>();
  final AttendanceController _attendanceController = Get.put(
    AttendanceController(),
  );

  final AuthService _authService = AuthService();

  SessionModel? _session;
  Timer? _timer;
  final RxMap<String, List<UserModel>> _studentsByClass = <String, List<UserModel>>{}.obs;
  bool _isLoadingQR = false;

  late AnimationController _pulseController;
  late AnimationController _glowController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _loadData();
    _timer = Timer.periodic(
      const Duration(seconds: 15),
      (Timer t) => _refreshData(),
    );

    // Initialisation des animations pour l'appel GPS
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    _session = _sessionController.sessions.firstWhereOrNull(
      (s) => s.id == widget.sessionId,
    );
    _attendanceController.fetchAttendanceForSession(widget.sessionId);

    // Charger les étudiants des classes de la séance
    if (_session != null) {
      final Map<String, List<UserModel>> groupedStudents = {};
      for (final classId in _session!.classeIds) {
        final students = await _authService.getStudentsByClass(classId);
        groupedStudents[classId] = students;
      }
      _studentsByClass.assignAll(groupedStudents);

      // Charger le QR Code du lieu si mode SCAN_QR
      if (_session!.mode == SessionMode.SCAN_QR) {}
    }
  }

  void _refreshData() {
    if (_session?.statut == SessionStatus.EN_COURS) {
      _attendanceController.fetchAttendanceForSession(widget.sessionId);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_session == null) {
      return const Scaffold(body: Center(child: Text("Séance introuvable")));
    }

    final isClosed = _session!.statut == SessionStatus.CLOS;

    if (isClosed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.off(() => SessionRecapView(sessionId: widget.sessionId));
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      appBar: AppBar(
        title: const Text(
          "Suivi de Séance",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildModernSessionHeader(),
            // if (_session!.mode == SessionMode.SCAN_QR) _buildQrSection(),
            if (_session!.mode == SessionMode.GPS) _buildGPSCallIndicator(),
            const SizedBox(height: 20),
            _buildStatsRow(),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildClassesGrid(),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildGPSCallIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32.0),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return AnimatedBuilder(
                animation: _glowAnimation,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      for (int i = 0; i < 3; i++)
                        Transform.scale(
                          scale: _pulseAnimation.value + (i * 0.2),
                          child: Container(
                            width: 120 - (i * 20),
                            height: 120 - (i * 20),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.primary.withOpacity(
                                  _glowAnimation.value * (0.4 - i * 0.1),
                                ),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      GestureDetector(
                        onTap: _launchGPSCall,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                AppColors.primary,
                                AppColors.primaryLight,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(
                                  _glowAnimation.value * 0.6,
                                ),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.location_on_rounded,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
          const SizedBox(height: 20),
          const Text(
            "LANCER L'APPEL GPS",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Cliquez sur le cercle pour notifier les étudiants",
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Obx(() {
      final attendances = _attendanceController.attendances;
      final presentCount =
          attendances.where((a) => a.statut == AttendanceStatus.PRESENT).length;
      
      int total = 0;
      _studentsByClass.values.forEach((list) => total += list.length);

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Row(
          children: [
            _buildSmallStat("Global Inscrits", "$total", Colors.blueGrey),
            const SizedBox(width: 12),
            _buildSmallStat("Global Présents", "$presentCount", Colors.green),
            const SizedBox(width: 12),
            _buildSmallStat("Global Absents", "${total - presentCount}", Colors.red),
          ],
        ),
      );
    });
  }

  Widget _buildSmallStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassesGrid() {
    return Obx(() {
      if (_studentsByClass.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      final classes = _session!.classes ?? [];
      final attendances = _attendanceController.attendances;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8.0, bottom: 12.0),
            child: Text(
              "SÉLECTIONNER UNE CLASSE POUR L'APPEL",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 11,
                letterSpacing: 1.2,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
            ),
            itemCount: _session!.classeIds.length,
            itemBuilder: (context, index) {
              final classId = _session!.classeIds[index];
              final classObj = classes.firstWhereOrNull((c) => c.id == classId) ?? 
                              _authController.classes.firstWhereOrNull((c) => c.id == classId) ??
                              ClassModel(id: classId, nom: "Classe $classId", niveau: "", parcours: "");
              
              final classStudents = _studentsByClass[classId] ?? [];
              final studentIds = classStudents.map((s) => s.id).toSet();
              final presentCount = attendances.where((a) => studentIds.contains(a.etudiantId) && a.statut == AttendanceStatus.PRESENT).length;
              
              return _buildClassCard(classObj, classStudents, presentCount);
            },
          ),
        ],
      );
    });
  }

  Widget _buildClassCard(ClassModel classObj, List<UserModel> students, int presentCount) {
    final total = students.length;
    final percent = total > 0 ? (presentCount / total) * 100 : 0.0;

    return InkWell(
      onTap: () {
        Get.to(() => ClassAttendanceMonitorView(
          sessionId: widget.sessionId,
          classModel: classObj,
          students: students,
        ));
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  classObj.nom,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  "${classObj.niveau} ${classObj.parcours}",
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "$presentCount/$total",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: percent > 50 ? Colors.green : AppColors.primary,
                      ),
                    ),
                    Text(
                      "${percent.toInt()}%",
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: total > 0 ? presentCount / total : 0,
                    backgroundColor: Colors.grey.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      percent > 50 ? Colors.green : AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernSessionHeader() {
    final location = _authController.locations.firstWhereOrNull(
      (loc) => loc.id == _session!.lieuId,
    );
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryLight],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _session!.matiere,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  location?.name ?? "Salle ${_session!.lieuId}",
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              "EN COURS",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          const Text(
            "SCANEZ POUR LA PRÉSENCE",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 16),
          if (_isLoadingQR)
            const CircularProgressIndicator()
          else
            const Icon(Icons.qr_code_2_rounded, size: 120, color: Colors.black),
          const SizedBox(height: 12),
          Text(
            "Affichez ce code aux étudiants",
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _endSession,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          "CLÔTURER LA SÉANCE",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _launchGPSCall() {
    AppModal.showConfirmation(
      context: context,
      title: "Lancer l'appel GPS",
      message:
          "Une notification sera envoyée à tous les étudiants de la classe.",
      confirmText: "Lancer",
      onConfirm: () async {
        AppUtils.showSuccessToast("Appel lancé !");
      },
    );
  }

  void _endSession() {
    AppModal.showConfirmation(
      context: context,
      title: "Clôturer la séance",
      message: "Voulez-vous vraiment terminer cette séance ?\nLes statistiques finales seront générées.",
      confirmText: "Confirmer",
      onConfirm: () async {
        final success = await _sessionController.endSession(widget.sessionId);
        if (success) {
          Get.off(() => SessionRecapView(sessionId: widget.sessionId));
          AppUtils.showSuccessToast("Séance clôturée");
        }
      },
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/attendance_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/session_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_modal.dart';
import '../../models/session_model.dart';
import '../../models/attendance_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import 'session_recap_view.dart';

class ManualAttendanceView extends StatefulWidget {
  final String sessionId;
  final List<String>? additionalLocationIds; // Pour les séances multi-salles

  const ManualAttendanceView({
    Key? key,
    required this.sessionId,
    this.additionalLocationIds,
  }) : super(key: key);

  @override
  State<ManualAttendanceView> createState() => _ManualAttendanceViewState();
}

class _ManualAttendanceViewState extends State<ManualAttendanceView>
    with TickerProviderStateMixin {
  final SessionController _sessionController = Get.find<SessionController>();
  final AuthController _authController = Get.find<AuthController>();
  final AttendanceController _attendanceController = Get.put(
    AttendanceController(),
  );
  final AuthService _authService = AuthService();

  SessionModel? _session;
  List<UserModel> _students = [];
  Map<String, AttendanceStatus> _attendanceMap = {}; // etudiantId -> status
  bool _isCallStarted = false;
  bool _isSaving = false;
  int _currentLocationIndex = 0;
  List<String> _allLocationIds = [];

  late AnimationController _pulseController;
  late AnimationController _glowController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _loadData();

    // Animation pour le cercle clignotant
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
    _pulseController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    _session = _sessionController.sessions.firstWhereOrNull(
      (s) => s.id == widget.sessionId,
    );

    if (_session == null) return;

    // Construire la liste des lieux (premier lieu + lieux additionnels)
    _allLocationIds = [_session!.lieuId];
    if (widget.additionalLocationIds != null) {
      _allLocationIds.addAll(widget.additionalLocationIds!);
    }

    // Charger les étudiants
    final List<UserModel> allStudents = [];
    for (final classId in _session!.classeIds) {
      final students = await _authService.getStudentsByClass(classId);
      allStudents.addAll(students);
    }
    setState(() {
      _students = allStudents;
      // Initialiser tous les étudiants comme absents par défaut
      for (final student in _students) {
        _attendanceMap[student.id] = AttendanceStatus.ABSENT;
      }
    });
  }

  void _startCall() {
    setState(() {
      _isCallStarted = true;
    });
  }

  void _toggleAttendance(String studentId) {
    setState(() {
      final currentStatus =
          _attendanceMap[studentId] ?? AttendanceStatus.ABSENT;
      _attendanceMap[studentId] =
          currentStatus == AttendanceStatus.PRESENT
              ? AttendanceStatus.ABSENT
              : AttendanceStatus.PRESENT;
    });
  }

  Future<void> _saveAttendance() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // Enregistrer les présences pour la salle actuelle
      final sessionIdForLocation =
          _currentLocationIndex == 0
              ? widget.sessionId
              : '${widget.sessionId}_loc_${_currentLocationIndex}';

      bool allSuccess = true;
      for (final entry in _attendanceMap.entries) {
        final attendance = await _attendanceController.updateManualStatus(
          sessionId: sessionIdForLocation,
          etudiantId: entry.key,
          status: entry.value,
        );
        if (!attendance) allSuccess = false;
      }

      if (!allSuccess) {
        await AppModal.showWarning(
          context: context,
          title: "Attention",
          message:
              "Certaines présences n'ont pas pu être enregistrées. Veuillez réessayer.",
          confirmText: "OK",
        );
        setState(() => _isSaving = false);
        return;
      }

      // Si on a plusieurs salles et qu'on n'est pas à la dernière
      if (_allLocationIds.length > 1 &&
          _currentLocationIndex < _allLocationIds.length - 1) {
        // Passer à la salle suivante
        setState(() {
          _currentLocationIndex++;
          _isCallStarted = false;
          // Réinitialiser les présences pour la nouvelle salle
          for (final student in _students) {
            _attendanceMap[student.id] = AttendanceStatus.ABSENT;
          }
        });

        AppModal.showSuccess(
          context: context,
          title: "Appel enregistré",
          message:
              "L'appel de la salle ${_currentLocationIndex} a été enregistré avec succès. Vous pouvez maintenant passer à la salle suivante.",
        );
      } else {
        // Tous les appels sont terminés, rediriger vers le récap
        Get.off(() => SessionRecapView(sessionId: widget.sessionId));
      }
    } catch (e) {
      AppModal.showError(
        context: context,
        title: "Erreur",
        message:
            "Une erreur est survenue lors de l'enregistrement. Veuillez réessayer.",
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_session == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final currentLocation = _authController.locations.firstWhereOrNull(
      (loc) => loc.id == _allLocationIds[_currentLocationIndex],
    );
    final locationName = currentLocation?.name ?? "Salle inconnue";

    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      appBar: AppBar(
        title: const Text(
          "Appel Manuel",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Header moderne
          _buildModernHeader(locationName),

          // Cercle animé (si appel pas encore commencé)
          if (!_isCallStarted) _buildAnimatedCallIndicator(),

          // Fiche de présence
          Expanded(child: _buildAttendanceSheet()),

          // Bouton d'action
          _buildActionButton(),
        ],
      ),
    );
  }

  Widget _buildModernHeader(String locationName) {
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
                        if (_allLocationIds.length > 1) ...[
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "Salle ${_currentLocationIndex + 1}/${_allLocationIds.length}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
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
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatCard("Total", "${_students.length}", Colors.white70),
              const SizedBox(width: 12),
              _buildStatCard(
                "Présents",
                "${_attendanceMap.values.where((s) => s == AttendanceStatus.PRESENT).length}",
                Colors.greenAccent,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                "Absents",
                "${_attendanceMap.values.where((s) => s == AttendanceStatus.ABSENT).length}",
                Colors.redAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedCallIndicator() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
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
                      // Cercles concentriques avec glow
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
                      // Cercle principal
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [AppColors.primary, AppColors.primaryLight],
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
                          Icons.mic,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            "Appuyez pour commencer l'appel",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _startCall,
            icon: const Icon(Icons.play_arrow),
            label: const Text("Commencer l'appel"),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceSheet() {
    if (!_isCallStarted) {
      return const SizedBox.shrink();
    }

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
          // En-tête de la fiche
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
                  "FICHE DE PRÉSENCE",
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

          // Liste des étudiants
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _students.length,
              itemBuilder: (context, index) {
                final student = _students[index];
                final status =
                    _attendanceMap[student.id] ?? AttendanceStatus.ABSENT;
                final isPresent = status == AttendanceStatus.PRESENT;

                return _buildStudentRow(student, isPresent, index + 1);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentRow(UserModel student, bool isPresent, int number) {
    return InkWell(
      onTap: () => _toggleAttendance(student.id),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey.withOpacity(0.1), width: 0.5),
          ),
          color:
              isPresent ? Colors.green.withOpacity(0.03) : Colors.transparent,
        ),
        child: Row(
          children: [
            // Index discret
            SizedBox(
              width: 25,
              child: Text(
                "$number.",
                style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
              ),
            ),
            const SizedBox(width: 8),

            // NOM Prénom (Style administratif)
            Expanded(
              child: Text(
                "${student.nom.toUpperCase()} ${student.prenom}",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isPresent ? FontWeight.bold : FontWeight.w500,
                  color: isPresent ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ),

            // Indicateur P/A compact
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isPresent ? Colors.green : Colors.red.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                isPresent ? "P" : "A",
                style: TextStyle(
                  color: isPresent ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    if (!_isCallStarted) return const SizedBox.shrink();

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
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _isSaving ? null : _saveAttendance,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child:
              _isSaving
                  ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                  : Text(
                    _allLocationIds.length > 1 &&
                            _currentLocationIndex < _allLocationIds.length - 1
                        ? "Terminer cette salle et passer à la suivante"
                        : "Enregistrer l'appel",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
        ),
      ),
    );
  }
}

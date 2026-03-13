import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/attendance_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/session_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../models/session_model.dart';
import '../../models/attendance_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../core/utils/app_utils.dart';
import '../../models/class_model.dart';
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
  Map<String, List<UserModel>> _studentsByClass = {};
  Map<String, Map<String, AttendanceStatus>> _attendanceMap = {}; // classId -> (etudiantId -> status)
  bool _isCallStarted = false;
  String? _selectedClassId;
  bool _isSaving = false;
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

    // Charger les étudiants et les grouper par classe
    final Map<String, List<UserModel>> grouped = {};
    for (final classId in _session!.classeIds) {
      final students = await _authService.getStudentsByClass(classId);
      grouped[classId] = students;
      
      // Initialiser la map de présence pour cette classe
      _attendanceMap[classId] = {
        for (var s in students) s.id: AttendanceStatus.ABSENT
      };
    }

    setState(() {
      _studentsByClass = grouped;
    });
  }

  void _startCall(String classId) {
    setState(() {
      _selectedClassId = classId;
      _isCallStarted = true;
    });
  }

  void _toggleAttendance(String studentId) {
    if (_selectedClassId == null) return;
    setState(() {
      final classMap = _attendanceMap[_selectedClassId!]!;
      final currentStatus = classMap[studentId] ?? AttendanceStatus.ABSENT;
      classMap[studentId] =
          currentStatus == AttendanceStatus.PRESENT
              ? AttendanceStatus.ABSENT
              : AttendanceStatus.PRESENT;
    });
  }

  Future<void> _saveAttendance() async {
    if (_isSaving || _selectedClassId == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final currentClassAttendance = _attendanceMap[_selectedClassId!]!;
      
      bool allSuccess = true;
      for (final entry in currentClassAttendance.entries) {
        final success = await _attendanceController.updateManualStatus(
          sessionId: widget.sessionId,
          etudiantId: entry.key,
          status: entry.value,
        );
        if (!success) allSuccess = false;
      }

      if (!allSuccess) {
        AppUtils.showErrorToast("Certaines présences n'ont pas pu être enregistrées.");
      } else {
        AppUtils.showSuccessToast("Appel enregistré pour cette classe");
        setState(() {
           _isCallStarted = false;
           _selectedClassId = null;
        });
      }
    } catch (e) {
      AppUtils.showErrorToast("Une erreur est survenue");
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_session == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      appBar: AppBar(
        title: Text(
          _isCallStarted ? "Appel : ${_session!.matiere}" : "Choisir une classe",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_isCallStarted) {
              setState(() {
                _isCallStarted = false;
                _selectedClassId = null;
              });
            } else {
              Get.back();
            }
          },
        ),
        actions: [
          if (!_isCallStarted)
            TextButton(
              onPressed: () => Get.off(() => SessionRecapView(sessionId: widget.sessionId)),
              child: const Text("Terminer", style: TextStyle(color: Colors.white)),
            )
        ],
      ),
      body: Column(
        children: [
          _buildModernHeader(),
          if (!_isCallStarted) Expanded(child: _buildClassSelectionList()),
          if (_isCallStarted) ...[
             _buildAnimatedCallIndicator(),
             Expanded(child: _buildAttendanceSheet()),
             _buildActionButton(),
          ]
        ],
      ),
    );
  }

  Widget _buildModernHeader() {
    final location = _authController.locations.firstWhereOrNull((l) => l.id == _session!.lieuId);
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
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  location?.name ?? "Salle ${_session!.lieuId}",
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          if (_isCallStarted && _selectedClassId != null)
             _buildHeaderStatusBadge(),
        ],
      ),
    );
  }

  Widget _buildHeaderStatusBadge() {
    final students = _studentsByClass[_selectedClassId!] ?? [];
    final classAttendance = _attendanceMap[_selectedClassId!] ?? {};
    final presents = classAttendance.values.where((v) => v == AttendanceStatus.PRESENT).length;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        "$presents / ${students.length} Présents",
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _buildClassSelectionList() {
    if (_studentsByClass.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final classes = _session!.classes ?? [];
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _session!.classeIds.length,
      itemBuilder: (context, index) {
        final classId = _session!.classeIds[index];
        final classObj = classes.firstWhereOrNull((c) => c.id == classId) ?? 
                        _authController.classes.firstWhereOrNull((c) => c.id == classId) ??
                        ClassModel(id: classId, nom: "Classe $classId", niveau: "", parcours: "");
        
        final students = _studentsByClass[classId] ?? [];
        return _buildClassSelectionCard(classObj, students);
      },
    );
  }

  Widget _buildClassSelectionCard(ClassModel classObj, List<UserModel> students) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        title: Text(classObj.nom, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("${classObj.niveau} ${classObj.parcours} • ${students.length} étudiants"),
        trailing: const Icon(Icons.chevron_right, color: AppColors.primary),
        onTap: () => _startCall(classObj.id),
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
            "Faites l'appel pour la classe sélectionnée",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
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
                    "${_studentsByClass[_selectedClassId!]?.length ?? 0} étudiants",
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
              itemCount: _studentsByClass[_selectedClassId!]?.length ?? 0,
              itemBuilder: (context, index) {
                final student = _studentsByClass[_selectedClassId!]![index];
                final status =
                    _attendanceMap[_selectedClassId!]![student.id] ?? AttendanceStatus.ABSENT;
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
                  ? const Center(
                    child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                  )
                  : const Text(
                    "Enregistrer l'appel",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
        ),
      ),
    );
  }
}

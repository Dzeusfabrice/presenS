import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/attendance_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/session_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../models/attendance_model.dart';
import 'session_details_view.dart';
import 'package:intl/intl.dart';

class AttendanceHistoryView extends StatefulWidget {
  const AttendanceHistoryView({Key? key}) : super(key: key);

  @override
  State<AttendanceHistoryView> createState() => _AttendanceHistoryViewState();
}

class _AttendanceHistoryViewState extends State<AttendanceHistoryView> {
  final AttendanceController _attendanceController =
      Get.find<AttendanceController>();
  final AuthController _authController = Get.find<AuthController>();
  final SessionController _sessionController = Get.find<SessionController>();

  String _selectedPeriod = "Ce mois";
  String _selectedSubject = "Toutes";

  final List<String> _periods = [
    "Cette semaine",
    "Ce mois",
    "Ce semestre",
    "Cette année",
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchHistory();
      _sessionController.fetchSessions();
    });
  }

  void _fetchHistory() {
    final userId = _authController.user.value?.id;
    if (userId != null) {
      _attendanceController.fetchAttendanceForStudent(userId);
    }
  }

  // Récupérer les matières uniques depuis les sessions
  List<String> _getSubjects() {
    final attendances = _attendanceController.attendances;
    final sessions = _sessionController.sessions;

    final subjects = <String>{};
    for (final attendance in attendances) {
      final session = sessions.firstWhereOrNull(
        (s) => s.id == attendance.sessionId,
      );
      if (session != null && session.matiere.isNotEmpty) {
        subjects.add(session.matiere);
      }
    }

    final subjectList = ["Toutes", ...subjects.toList()..sort()];
    return subjectList;
  }

  // Filtrer par période
  bool _isInPeriod(DateTime date, String period) {
    final now = DateTime.now();
    switch (period) {
      case "Cette semaine":
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        return date.isAfter(weekStart.subtract(const Duration(days: 1)));
      case "Ce mois":
        return date.year == now.year && date.month == now.month;
      case "Ce semestre":
        final semesterStart = DateTime(now.year, now.month <= 6 ? 1 : 7, 1);
        return date.isAfter(semesterStart.subtract(const Duration(days: 1)));
      case "Cette année":
        return date.year == now.year;
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      appBar: AppBar(
        title: const Text(
          "Historique des présences",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.cardBackground,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: Column(
        children: [
          _buildFiltersSection(),
          Expanded(child: _buildHistoryList()),
        ],
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Obx(() {
      final subjects = _getSubjects();
      // Réinitialiser le filtre si la matière sélectionnée n'existe plus
      if (!subjects.contains(_selectedSubject)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() => _selectedSubject = "Toutes");
          }
        });
      }

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.backgroundGrey,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedPeriod,
                    isExpanded: true,
                    icon: const Icon(Icons.calendar_today_rounded, size: 16),
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    items:
                        _periods
                            .map(
                              (p) => DropdownMenuItem(value: p, child: Text(p)),
                            )
                            .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedPeriod = val);
                      }
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.backgroundGrey,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value:
                        subjects.contains(_selectedSubject)
                            ? _selectedSubject
                            : "Toutes",
                    isExpanded: true,
                    icon: const Icon(Icons.menu_book_rounded, size: 16),
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    items:
                        subjects
                            .map(
                              (s) => DropdownMenuItem(
                                value: s,
                                child: Text(s, overflow: TextOverflow.ellipsis),
                              ),
                            )
                            .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedSubject = val);
                      }
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildHistoryList() {
    return Obx(() {
      if (_attendanceController.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final allAttendances = _attendanceController.attendances.toList();
      final sessions = _sessionController.sessions;

      // Appliquer les filtres
      var filtered =
          allAttendances.where((attendance) {
            // Filtre par période
            if (!_isInPeriod(attendance.timestamp, _selectedPeriod)) {
              return false;
            }

            // Filtre par matière
            if (_selectedSubject != "Toutes") {
              final session = sessions.firstWhereOrNull(
                (s) => s.id == attendance.sessionId,
              );
              if (session == null || session.matiere != _selectedSubject) {
                return false;
              }
            }

            return true;
          }).toList();

      // Trier par date (plus récent en premier)
      filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      if (filtered.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history_rounded, size: 80, color: AppColors.grey300),
              const SizedBox(height: 16),
              Text(
                "Aucune présence trouvée.",
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _fetchHistory,
                child: const Text("Actualiser"),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final item = filtered[index];
          return _buildHistoryCard(item);
        },
      );
    });
  }

  Widget _buildHistoryCard(AttendanceModel item) {
    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    switch (item.statut) {
      case AttendanceStatus.PRESENT:
        statusColor = Colors.green;
        statusLabel = "PRÉSENT";
        statusIcon = Icons.check_circle_rounded;
        break;
      case AttendanceStatus.RETARD:
        statusColor = Colors.orange;
        statusLabel = "RETARD";
        statusIcon = Icons.watch_later_rounded;
        break;
      case AttendanceStatus.ABSENT:
        statusColor = Colors.red;
        statusLabel = "ABSENT";
        statusIcon = Icons.cancel_rounded;
        break;
    }

    final dateStr = DateFormat('dd MMM yyyy').format(item.timestamp);
    final timeStr = DateFormat('HH:mm').format(item.timestamp);

    return GestureDetector(
      onTap: () {
        Get.to(() => SessionDetailsView(attendance: item));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(statusIcon, color: statusColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _sessionController.sessions
                            .firstWhereOrNull((s) => s.id == item.sessionId)
                            ?.matiere ??
                        "Séance de cours",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 12,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "$dateStr à $timeStr",
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              statusLabel,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

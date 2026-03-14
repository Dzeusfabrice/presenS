import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/session_controller.dart';
import '../../core/theme/app_colors.dart';
import 'attendance_history_view.dart';
import 'mark_attendance_view.dart';
import '../../controllers/attendance_controller.dart';
import '../../models/attendance_model.dart';
import '../../core/widgets/watermark_background.dart';
import '../../models/session_model.dart';
import '../../core/widgets/timeline_session_card.dart';

import '../../core/widgets/app_modal.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({Key? key}) : super(key: key);

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final Set<String> _notifiedSessionIds = {};

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final sessionController = Get.find<SessionController>();
    Get.find<AttendanceController>(); // Just ensure it's loaded

    return Scaffold(
      body: WatermarkBackground(
        child: Stack(
          children: [
            // Background Gradient
            RefreshIndicator(
              onRefresh: () => sessionController.fetchSessions(),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // AppBar Premium with Background Image
                  SliverToBoxAdapter(
                    child: Stack(
                      children: [
                        // Header Background Image
                        Container(
                          height: 240,
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage('assets/images/Students.jpg'),
                              fit: BoxFit.cover,
                              alignment: Alignment.topCenter,
                            ),
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(40),
                              bottomRight: Radius.circular(40),
                            ),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  AppColors.primary.withValues(alpha: 0.2),
                                  AppColors.primary.withValues(alpha: 0.95),
                                ],
                              ),
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(40),
                                bottomRight: Radius.circular(40),
                              ),
                            ),
                          ),
                        ),

                        Column(
                          children: [
                            Obx(() {
                              final u = authController.user.value;
                              final displayName =
                                  (u?.prenom == null ||
                                          u!.prenom.trim().isEmpty)
                                      ? "Étudiant"
                                      : u.prenom;
                              return _buildCustomAppBar(
                                displayName,
                                authController,
                              );
                            }),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(24, 1, 24, 10),
                              child: _buildStatsSection(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Dashboard Content
                  SliverToBoxAdapter(
                    child: Obx(() {
                      final u = authController.user.value;
                      final studentClasseId = u?.classeId;
                      final activeGPS = sessionController.activeSessions
                          .firstWhereOrNull(
                            (s) =>
                                s.mode == SessionMode.GPS &&
                                (studentClasseId != null &&
                                    s.classeIds.contains(studentClasseId)),
                          );

                      // Afficher le modal si nouveau cours GPS détecté
                      if (activeGPS != null && !_notifiedSessionIds.contains(activeGPS.id)) {
                        _notifiedSessionIds.add(activeGPS.id);
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          AppModal.showInfo(
                            context: context,
                            title: "🚨 Appel Lancé !",
                            message: "Votre enseignant vient de lancer l'appel pour le cours de ${activeGPS.matiere}. Vous pouvez cliquer sur la carte qui vient d'apparaître pour marquer votre présence par GPS.",
                          );
                        });
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (activeGPS != null)
                            _buildQuickGPSCard(context, activeGPS),
                          Padding(
                            padding: EdgeInsets.fromLTRB(24, 20, 24, 10),
                            child: Text(
                              "Séances en cours",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),

                  // Active Sessions List
                  Obx(() {
                    if (sessionController.isLoading.value) {
                      return const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.only(top: 50),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      );
                    }

                    final studentClasseId = authController.user.value?.classeId;
                    final filteredSessions =
                        sessionController.activeSessions.where((s) {
                          // Si l'étudiant a une classe, on filtre strictement.
                          // Sinon (admin/debug), on montre tout.
                          if (studentClasseId != null &&
                              studentClasseId.isNotEmpty) {
                            return s.classeIds.contains(studentClasseId);
                          }
                          return true;
                        }).toList();

                    if (filteredSessions.isEmpty) {
                      return SliverToBoxAdapter(child: _buildEmptyState());
                    }

                    return SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final session = filteredSessions[index];
                        final isLast = index == filteredSessions.length - 1;
                        return TimelineSessionCard(
                          session: session,
                          isLast: isLast,
                          onTap: () {
                            Get.to(
                              () => MarkAttendanceView(
                                preSelectedSessionId: session.id,
                              ),
                            );
                          },
                        );
                      }, childCount: filteredSessions.length),
                    );
                  }),

                  // Spacing at bottom
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildCustomAppBar(String name, AuthController auth) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 30),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Get.toNamed('/profile'),
            child: CircleAvatar(
              backgroundColor: Colors.white.withOpacity(0.2),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () => Get.toNamed('/profile'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Bonjour,",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  Text(
                    "$name 👋",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: () => Get.to(() => const AttendanceHistoryView()),
            icon: const Icon(Icons.history_rounded, color: Colors.white),
          ),
          IconButton(
            onPressed: () => Get.toNamed('/profile'),
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    final attendanceController = Get.find<AttendanceController>();
    return Obx(() {
      final list = attendanceController.attendances;
      final presentCount =
          list.where((a) => a.statut == AttendanceStatus.PRESENT).length;
      final retardCount =
          list.where((a) => a.statut == AttendanceStatus.RETARD).length;
      final totalPresent = presentCount + retardCount;

      final rate = totalPresent > 0 ? "100%" : "0%";

      return Row(
        children: [
          Expanded(
            child: _buildStudentStat(
              "Taux",
              rate,
              Icons.auto_graph_rounded,
              Colors.blueAccent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStudentStat(
              "Présences",
              totalPresent.toString(),
              Icons.check_circle_outline,
              Colors.greenAccent,
            ),
          ),
        ],
      );
    });
  }

  Widget _buildStudentStat(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBackground.withOpacity(0.12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.cardBackground.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.cardBackground, size: 16),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 10,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
} // Fin de la classe

Widget _buildQuickGPSCard(BuildContext context, SessionModel session) {
  return Container(
    margin: const EdgeInsets.fromLTRB(24, 20, 24, 0),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.primary, AppColors.primaryLight],
      ),
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withOpacity(0.3),
          blurRadius: 15,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showGPSPrompt(context, session),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.location_on_rounded,
                  color: AppColors.cardBackground,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Appel en cours !",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Validez votre présence pour ${session.matiere}",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

void _showGPSPrompt(BuildContext context, SessionModel session) {
  // On peut directement rediriger vers la vue de marquage
  // qui contient déjà toute la logique GPS et Premium
  Get.to(
    () => MarkAttendanceView(preSelectedSessionId: session.id),
    transition: Transition.cupertino,
    fullscreenDialog: true,
  );
}

Widget _buildEmptyState() {
  return Container(
    padding: const EdgeInsets.all(40),
    child: Column(
      children: [
        Icon(
          Icons.event_busy_rounded,
          size: 60,
          color: AppColors.grey500.withOpacity(0.5),
        ),
        const SizedBox(height: 16),
        Text(
          "Aucune séance active pour le moment",
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ],
    ),
  );
}

Widget _buildFloatingActionButton() {
  return FloatingActionButton.extended(
    onPressed: () {
      Get.to(() => const MarkAttendanceView());
    },
    backgroundColor: AppColors.primary,
    icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white),
    label: const Text(
      "Marquer présence",
      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    ),
  );
}

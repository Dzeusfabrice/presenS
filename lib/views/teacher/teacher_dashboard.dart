import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/session_controller.dart';
import '../../controllers/user_management_controller.dart';
import '../../models/user_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/watermark_background.dart';
import '../../core/widgets/timeline_session_card.dart';
import '../../models/session_model.dart';
import 'live_monitor_view.dart';
import 'session_recap_view.dart';

class TeacherDashboard extends StatelessWidget {
  const TeacherDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final sessionController = Get.find<SessionController>();
    Get.put(UserManagementController()); // Ensure students list is available
    final user = authController.user.value;

    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      body: WatermarkBackground(
        child: RefreshIndicator(
          onRefresh: () => sessionController.fetchSessions(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Stack(
                  children: [
                    // Header Background Image
                    Container(
                      height: 250,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/images/teacher.jpg'),
                          fit: BoxFit.cover,
                          alignment: Alignment.center,
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
                        // const SizedBox(width: 48),
                        _buildCustomAppBar(
                          user?.prenom ?? "Enseignant",
                          authController,
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                          child: _buildHeader(sessionController),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Vos séances",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Obx(() {
                          final filters = [
                            "Tous",
                            "En cours",
                            "Terminés",
                            "Récents",
                            "Anciens",
                          ];
                          return Row(
                            children:
                                filters.map((f) {
                                  final isSelected =
                                      sessionController.selectedFilter.value ==
                                      f;
                                  final count = sessionController
                                      .getFilterCount(f);

                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: ChoiceChip(
                                      label: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(f),
                                          if (count > 0) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color:
                                                    isSelected
                                                        ? Colors.white
                                                        : AppColors.primary
                                                            .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: Text(
                                                "$count",
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      isSelected
                                                          ? AppColors.primary
                                                          : AppColors
                                                              .textSecondary,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      selected: isSelected,
                                      onSelected: (val) {
                                        if (val) sessionController.setFilter(f);
                                      },
                                      selectedColor: AppColors.primary,
                                      backgroundColor: AppColors.cardBackground,
                                      labelStyle: TextStyle(
                                        color:
                                            isSelected
                                                ? Colors.white
                                                : AppColors.textSecondary,
                                        fontWeight:
                                            isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                        fontSize: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        side: BorderSide(
                                          color:
                                              isSelected
                                                  ? AppColors.primary
                                                  : Colors.grey.withOpacity(
                                                    0.2,
                                                  ),
                                        ),
                                      ),
                                      elevation: 0,
                                      pressElevation: 0,
                                    ),
                                  );
                                }).toList(),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),

              Obx(() {
                final sessions = sessionController.filteredSessions;
                if (sessions.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.event_busy_rounded,
                              size: 60,
                              color: AppColors.grey500.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "Aucune séance ne correspond au filtre",
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final session = sessions[index];
                    final isLast = index == sessions.length - 1;
                    return TimelineSessionCard(
                      session: session,
                      isLast: isLast,
                      onTap: () {
                        if (session.statut == SessionStatus.CLOS) {
                          Get.to(() => SessionRecapView(sessionId: session.id));
                        } else {
                          Get.to(() => LiveMonitorView(sessionId: session.id));
                        }
                      },
                    );
                  }, childCount: sessions.length),
                );
              }),

              SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed('/teacher/create-session'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          "Nouvelle séance",
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildCustomAppBar(String name, AuthController auth) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Row(
        children: [
          const SizedBox(width: 8),
          const Text(
            "Espace Enseignant",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Get.toNamed('/profile'),
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(SessionController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Obx(() {
        final userManagementController = Get.find<UserManagementController>();
        final sessions = controller.sessions;

        // Real data calculations
        final sessionsCount = sessions.length;

        // Students count - safe expansion in case classeIds is empty
        final teacherClassIds =
            sessions.expand((s) {
              try {
                return s.classeIds;
              } catch (_) {
                return <String>[];
              }
            }).toSet();
        final studentsCount =
            userManagementController.usersList.where((u) {
              return u.role == UserRole.ETUDIANT &&
                  teacherClassIds.contains(u.classeId);
            }).length;

        return Row(
          children: [
            Expanded(
              child: _buildSimpleStat(
                "Séances",
                sessionsCount.toString(),
                Icons.book_rounded,
                Colors.blueAccent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSimpleStat(
                "Étudiants",
                studentsCount.toString(),
                Icons.people_rounded,
                Colors.orangeAccent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSimpleStat(
                "Taux",
                "${controller.avgAttendanceRate.value.toInt()}%",
                Icons.analytics_rounded,
                Colors.greenAccent,
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildSimpleStat(
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
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
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
}

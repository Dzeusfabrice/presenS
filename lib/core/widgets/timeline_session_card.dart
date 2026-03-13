import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../../models/session_model.dart';
import '../../controllers/auth_controller.dart';

class TimelineSessionCard extends StatelessWidget {
  final SessionModel session;
  final bool isLast;
  final VoidCallback? onTap;

  const TimelineSessionCard({
    Key? key,
    required this.session,
    this.isLast = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final statusInfo = _getStatusInfo(session.statut);
    final day = DateFormat('d', 'fr').format(session.createdAt);
    final month = DateFormat('MMM', 'fr').format(session.createdAt);

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. DATE SECTION
              SizedBox(
                width: 45,
                child: Column(
                  children: [
                    Text(
                      day,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                        height: 1,
                      ),
                    ),
                    Text(
                      month,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // 2. TIMELINE SECTION
              const SizedBox(width: 8),
              Column(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(
                        color: statusInfo['indicatorColor'] as Color,
                        width: 2.5,
                      ),
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(width: 1, color: AppColors.grey300),
                    ),
                ],
              ),
              const SizedBox(width: 12),

              // 3. CARD SECTION
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.15),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // TAG / STATUS
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: (statusInfo['indicatorColor'] as Color)
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            statusInfo['statusText'] as String,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: statusInfo['indicatorColor'] as Color,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // TITLE
                        Text(
                          session.matiere,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 6),
                        
                        // CLASSES INFO
                        Obx(() {
                          final authController = Get.find<AuthController>();
                          final classes = session.classes ?? [];
                          final classNames = session.classeIds.map((id) {
                            final cls = classes.firstWhereOrNull((c) => c.id == id) ??
                                       authController.classes.firstWhereOrNull((c) => c.id == id);
                            return cls != null ? "${cls.nom} ${cls.niveau}" : id;
                          }).join(", ");
                          
                          return Row(
                            children: [
                              Icon(
                                Icons.school_rounded,
                                size: 14,
                                color: AppColors.textSecondary.withOpacity(0.5),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  classNames,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary.withOpacity(0.8),
                                    fontStyle: FontStyle.italic,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          );
                        }),
                        const SizedBox(height: 12),

                        // INFO LINE (User & Room)
                        Row(
                          children: [
                            Icon(
                              Icons.person_rounded,
                              size: 16,
                              color: AppColors.textSecondary.withOpacity(0.6),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _getTimeInfo(),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.grey300,
                                  width: 1,
                                ),
                              ),
                              child: Obx(() {
                                final authController =
                                    Get.find<AuthController>();
                                final location = authController.locations
                                    .firstWhereOrNull(
                                      (loc) => loc.id == session.lieuId,
                                    );
                                final locationName =
                                    location?.name ?? "Salle ${session.lieuId}";

                                return Text(
                                  locationName,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textSecondary,
                                  ),
                                );
                              }),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _getStatusInfo(SessionStatus status) {
    switch (status) {
      case SessionStatus.CLOS:
        return {
          'indicatorColor': const Color(0xFF0D9488), // Teal for Positive
          'statusText': 'Terminé',
        };
      case SessionStatus.EN_COURS:
        return {
          'indicatorColor': const Color(0xFF2563EB), // Blue for Active
          'statusText': 'En cours',
        };
      case SessionStatus.ATTENTE:
        return {
          'indicatorColor': const Color(0xFFF59E0B), // Amber for Neutral
          'statusText': 'À venir',
        };
    }
  }

  String _getTimeInfo() {
    if (session.heureDebut != null && session.heureFin != null) {
      final start = DateFormat('HH:mm').format(session.heureDebut!);
      final end = DateFormat('HH:mm').format(session.heureFin!);
      return '$start - $end';
    }
    return '--:--';
  }
}

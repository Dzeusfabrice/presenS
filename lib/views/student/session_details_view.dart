import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/attendance_model.dart';

import 'package:intl/intl.dart';

class SessionDetailsView extends StatelessWidget {
  final AttendanceModel attendance;

  const SessionDetailsView({Key? key, required this.attendance})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      appBar: AppBar(
        title: const Text(
          "Détails de la séance",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildStatusHeader(),
            const SizedBox(height: 24),
            _buildInfoCard(),
            const SizedBox(height: 24),
            _buildStatusHeader(),
            const SizedBox(height: 24),
            _buildInfoCard(),
            const SizedBox(height: 24),
            if (attendance.statut == AttendanceStatus.PRESENT)
              _buildProofCard()
            else if (attendance.statut == AttendanceStatus.RETARD)
              _buildDelayCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader() {
    Color statusColor;
    String statusLabel;
    IconData statusIcon;
    String statusMessage;

    switch (attendance.statut) {
      case AttendanceStatus.PRESENT:
        statusColor = Colors.green;
        statusLabel = "PRÉSENT";
        statusIcon = Icons.check_circle_rounded;
        statusMessage = "Votre présence a été validée avec succès.";
        break;
      case AttendanceStatus.RETARD:
        statusColor = Colors.orange;
        statusLabel = "RETARD";
        statusIcon = Icons.watch_later_rounded;
        statusMessage = "Vous avez été marqué en retard.";
        break;
      case AttendanceStatus.ABSENT:
      default:
        statusColor = Colors.red;
        statusLabel = "ABSENT";
        statusIcon = Icons.cancel_rounded;
        statusMessage = "Vous étiez absent à cette séance.";
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(statusIcon, color: statusColor, size: 48),
          ),
          const SizedBox(height: 16),
          Text(
            statusLabel,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: statusColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            statusMessage,
            textAlign: TextAlign.center,
            style:  TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
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
           Text(
            "Informations Générales",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          _buildInfoRow(
            Icons.book_rounded,
            "Matière",
            "Information indisponible",
          ),
          const Divider(height: 32),
          _buildInfoRow(
            Icons.person_rounded,
            "Enseignant",
            "Information indisponible",
          ),
          const Divider(height: 32),
          _buildInfoRow(
            Icons.room_rounded,
            "Salle",
            "Information indisponible",
          ),
          const Divider(height: 32),
          _buildInfoRow(
            Icons.access_time_rounded,
            "Heure",
            DateFormat('dd MMM yyyy | HH:mm').format(attendance.timestamp),
          ),
          const Divider(height: 32),
          _buildInfoRow(
            Icons.rule_rounded,
            "Validation",
            attendance.isMocked ? "MANUEL" : "AUTO",
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style:  TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style:  TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProofCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_user_rounded, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                "Preuve de validation",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            "Preuve de validation enregistrée",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          if (attendance.latClient != null) ...[
            const SizedBox(height: 4),
            Text(
              "Coordonnées GPS: ${attendance.latClient}, ${attendance.longClient}",
              style:  TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDelayCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.orange.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              const SizedBox(width: 8),
              Text(
                "Retard Enregistré",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            "Heure de marquage: 08:30",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
           Text(
            "Marge tolérée: Jusqu'à 08:15",
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

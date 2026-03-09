import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_utils.dart';
import '../../services/export_service.dart';

class ExportManagementView extends StatelessWidget {
  ExportManagementView({Key? key}) : super(key: key);
  
  final ExportService _exportService = ExportService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      appBar: AppBar(
        title: const Text(
          "Exportation des données",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        foregroundColor: AppColors.cardBackground,
      ),
      body: Column(
        children: [
          // En-tête avec description
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildExportCard(
                  icon: Icons.people_alt_rounded,
                  title: "Liste des Étudiants",
                  description:
                      "Exportez la liste complète des étudiants avec leurs informations",
                  formats: ["CSV", "Excel"],
                  color: const Color(0xFF3B82F6),
                  gradientColors: [
                    const Color(0xFF3B82F6).withOpacity(0.7),
                    const Color(0xFF2563EB).withOpacity(0.7),
                  ],
                  onTap:
                      () => _handleExport(context, "Liste des Étudiants", [
                        "CSV",
                        "Excel",
                      ]),
                ),
                const SizedBox(height: 16),
                _buildExportCard(
                  icon: Icons.school_rounded,
                  title: "Liste des Enseignants",
                  description:
                      "Exportez la liste complète des enseignants avec leurs départements",
                  formats: ["CSV", "Excel"],
                  color: const Color(0xFFF97316),
                  gradientColors: [
                    const Color(0xFFF97316).withOpacity(0.7),
                    const Color(0xFFEA580C).withOpacity(0.7),
                  ],
                  onTap:
                      () => _handleExport(context, "Liste des Enseignants", [
                        "CSV",
                        "Excel",
                      ]),
                ),
                const SizedBox(height: 16),
                _buildExportCard(
                  icon: Icons.meeting_room_rounded,
                  title: "Rapport des Salles/Lieux",
                  description:
                      "Générez un rapport détaillé de tous les lieux de cours",
                  formats: ["PDF"],
                  color: const Color(0xFF10B981),
                  gradientColors: [
                    const Color(0xFF10B981).withOpacity(0.7),
                    const Color(0xFF059669).withOpacity(0.7),
                  ],
                  onTap:
                      () => _handleExport(context, "Rapport des Salles/Lieux", [
                        "PDF",
                      ]),
                ),
                const SizedBox(height: 16),
                _buildExportCard(
                  icon: Icons.fact_check_rounded,
                  title: "Rapports de Présence (Global)",
                  description:
                      "Exportez tous les rapports de présence avec statistiques",
                  formats: ["Excel", "PDF"],
                  color: const Color(0xFF8B5CF6),
                  gradientColors: [
                    const Color(0xFF8B5CF6).withOpacity(0.7),
                    const Color(0xFF7C3AED).withOpacity(0.7),
                  ],
                  onTap:
                      () => _handleExport(
                        context,
                        "Rapports de Présence (Global)",
                        ["Excel", "PDF"],
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportCard({
    required IconData icon,
    required String title,
    required String description,
    required List<String> formats,
    required Color color,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.15),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Pattern de fond subtil
              Positioned.fill(
                child: Opacity(
                  opacity: 0.1,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: CustomPaint(painter: _ExportPatternPainter()),
                  ),
                ),
              ),
              // Contenu
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    // Icône principale
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Icon(icon, color: Colors.white, size: 32),
                    ),
                    const SizedBox(width: 16),
                    // Informations
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            description,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 10),
                          // Badges de formats
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children:
                                formats.map((format) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.25),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.5),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          format == "PDF"
                                              ? Icons.picture_as_pdf_rounded
                                              : Icons.table_chart_rounded,
                                          color: Colors.white,
                                          size: 12,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          format,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                          ),
                        ],
                      ),
                    ),
                    // Bouton d'export
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.download_rounded,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleExport(
    BuildContext context,
    String exportType,
    List<String> formats,
  ) {
    if (formats.length == 1) {
      // Un seul format, exporter directement
      _performExport(exportType, formats[0]);
    } else {
      // Plusieurs formats, demander à l'utilisateur
      _showFormatSelector(context, exportType, formats);
    }
  }

  Future<void> _performExport(String exportType, String format) async {
    bool success = false;
    
    switch (exportType) {
      case "Liste des Étudiants":
        success = await _exportService.exportStudents(format);
        break;
      case "Liste des Enseignants":
        success = await _exportService.exportTeachers(format);
        break;
      case "Rapport des Salles/Lieux":
        success = await _exportService.exportLocations(format);
        break;
      case "Rapports de Présence (Global)":
        success = await _exportService.exportAttendance(format);
        break;
      default:
        AppUtils.showErrorToast("Type d'export non reconnu");
        return;
    }
    
    if (success) {
      AppUtils.showSuccessToast("Exportation réussie !");
    }
  }

  void _showFormatSelector(
    BuildContext context,
    String exportType,
    List<String> formats,
  ) {
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
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.grey300,
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Choisir le format",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Sélectionnez le format pour $exportType",
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ...formats.map((format) {
              final isExcel = format == "Excel" || format == "CSV";
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Get.back();
                      _performExport(exportType, format);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundGrey,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border, width: 1),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color:
                                  isExcel
                                      ? AppColors.primary.withOpacity(0.1)
                                      : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              isExcel
                                  ? Icons.table_chart_rounded
                                  : Icons.picture_as_pdf_rounded,
                              color: isExcel ? AppColors.primary : Colors.red,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  format,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isExcel
                                      ? "Fichier tableur compatible Excel"
                                      : "Document PDF formaté",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: AppColors.textSecondary,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// Peintre pour créer un pattern original sur les cartes d'export
class _ExportPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white
          ..strokeWidth = 1.0
          ..style = PaintingStyle.stroke;

    // Lignes diagonales
    for (double i = 0; i < size.width + size.height; i += 25) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i - size.height, size.height),
        paint,
      );
    }

    // Cercles décoratifs
    final circlePaint =
        Paint()
          ..color = Colors.white.withOpacity(0.15)
          ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * 0.15),
      35,
      circlePaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.15, size.height * 0.85),
      30,
      circlePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

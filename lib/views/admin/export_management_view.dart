import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../controllers/export_controller.dart';

class ExportManagementView extends StatelessWidget {
  ExportManagementView({Key? key}) : super(key: key);

  final ExportController controller = Get.put(ExportController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      appBar: AppBar(
        title: Text(
          "Exportation des données",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        foregroundColor: AppColors.cardBackground,
      ),
      body: Obx(() {
        if (controller.isLoadingList.value && controller.classes.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            // Filtres rapides
            _buildFiltersSection(),

            // Liste des options d'export
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                children: [
                  _buildSectionTitle("Utilisateurs & Salles"),
                  _buildExportCard(
                    icon: Icons.people_alt_rounded,
                    title: "Liste des Étudiants",
                    description:
                        controller.selectedClassId.value == null
                            ? "Liste complète de tous les étudiants"
                            : "Liste des étudiants de la classe sélectionnée",
                    formats: ["CSV", "Excel"],
                    color: const Color(0xFF3B82F6),
                    gradientColors: [
                      const Color(0xFF3B82F6).withOpacity(0.8),
                      const Color(0xFF2563EB).withOpacity(0.8),
                    ],
                    onTap:
                        () => _handleExport(context, "Étudiants", [
                          "CSV",
                          "Excel",
                        ]),
                  ),
                  const SizedBox(height: 12),
                  _buildExportCard(
                    icon: Icons.school_rounded,
                    title: "Liste des Enseignants",
                    description: "Liste complète de tous les enseignants",
                    formats: ["CSV", "Excel"],
                    color: const Color(0xFFF97316),
                    gradientColors: [
                      const Color(0xFFF97316).withOpacity(0.8),
                      const Color(0xFFEA580C).withOpacity(0.8),
                    ],
                    onTap:
                        () => _handleExport(context, "Enseignants", [
                          "CSV",
                          "Excel",
                        ]),
                  ),
                  const SizedBox(height: 12),
                  _buildExportCard(
                    icon: Icons.meeting_room_rounded,
                    title: "Rapport des Salles",
                    description: "Toutes les salles et lieux enregistrés",
                    formats: ["PDF"],
                    color: const Color(0xFF10B981),
                    gradientColors: [
                      const Color(0xFF10B981).withOpacity(0.8),
                      const Color(0xFF059669).withOpacity(0.8),
                    ],
                    onTap: () => _handleExport(context, "Salles", ["PDF"]),
                  ),

                  const SizedBox(height: 24),
                  _buildSectionTitle("Rapports d'Assiduité"),
                  _buildExportCard(
                    icon: Icons.event_note_rounded,
                    title: "Rapport par Séance",
                    description:
                        controller.selectedSessionId.value == null
                            ? "Sélectionnez une séance ci-dessus"
                            : "Rapport de présence pour la séance sélectionnée",
                    formats: ["Excel", "PDF"],
                    disabled: controller.selectedSessionId.value == null,
                    color: const Color(0xFFF43F5E),
                    gradientColors: [
                      const Color(0xFFF43F5E).withOpacity(0.8),
                      const Color(0xFFE11D48).withOpacity(0.8),
                    ],
                    onTap:
                        () =>
                            _handleExport(context, "Séance", ["Excel", "PDF"]),
                  ),
                  const SizedBox(height: 12),
                  _buildExportCard(
                    icon: Icons.fact_check_rounded,
                    title: "Rapport de Présence",
                    description:
                        controller.selectedClassId.value == null
                            ? "Statistiques globales de présence"
                            : "Statistiques de présence pour la classe sélectionnée",
                    formats: ["Excel", "PDF"],
                    color: const Color(0xFF8B5CF6),
                    gradientColors: [
                      const Color(0xFF8B5CF6).withOpacity(0.8),
                      const Color(0xFF7C3AED).withOpacity(0.8),
                    ],
                    onTap:
                        () =>
                            _handleExport(context, "Global", ["Excel", "PDF"]),
                  ),
                  const SizedBox(height: 12),
                  _buildExportCard(
                    icon: Icons.assessment_rounded,
                    title: "Bilan Global Classe",
                    description:
                        controller.selectedClassId.value == null
                            ? "Sélectionnez une classe ci-dessus"
                            : "Bilan complet de toutes les séances de la classe",
                    formats: ["Excel", "PDF"],
                    disabled: controller.selectedClassId.value == null,
                    color: const Color(0xFF0EA5E9),
                    gradientColors: [
                      const Color(0xFF0EA5E9).withOpacity(0.8),
                      const Color(0xFF0284C7).withOpacity(0.8),
                    ],
                    onTap:
                        () => _handleExport(context, "BilanClasse", [
                          "Excel",
                          "PDF",
                        ]),
                  ),
                  const SizedBox(height: 12),
                  _buildExportCard(
                    icon: Icons.history_edu_rounded,
                    title: "Historique Étudiant",
                    description:
                        controller.selectedStudentId.value == null
                            ? "Sélectionnez un étudiant ci-dessus"
                            : "Relevé de présence complet de l'étudiant",
                    formats: ["Excel", "PDF"],
                    disabled: controller.selectedStudentId.value == null,
                    color: const Color(0xFF64748B),
                    gradientColors: [
                      const Color(0xFF64748B).withOpacity(0.8),
                      const Color(0xFF475569).withOpacity(0.8),
                    ],
                    onTap:
                        () => _handleExport(context, "HistoriqueEtudiant", [
                          "Excel",
                          "PDF",
                        ]),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.textSecondary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.tune_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                "Filtres d'exportation",
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildFilterDropdown(
                  label: "Classe",
                  value: controller.selectedClassId.value,
                  items:
                      controller.classes
                          .map(
                            (c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(
                                c.nom,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          )
                          .toList(),
                  onChanged: (val) {
                    controller.selectedClassId.value = val;
                    // Optionnel: filtrer les étudiants par classe si sélectionnée ?
                  },
                  hint: "Toutes les classes",
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFilterDropdown(
                  label: "Séance",
                  value: controller.selectedSessionId.value,
                  items:
                      controller.sessions.map((s) {
                        final displayDate = s.heureDebut ?? s.createdAt;
                        return DropdownMenuItem(
                          value: s.id,
                          child: Text(
                            "${s.matiere} (${displayDate.day}/${displayDate.month})",
                            style: const TextStyle(fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                  onChanged: (val) => controller.selectedSessionId.value = val,
                  hint: "Choisir séance",
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildFilterDropdown(
            label: "Étudiant",
            value: controller.selectedStudentId.value,
            items:
                controller.students
                    .map(
                      (s) => DropdownMenuItem(
                        value: s.id,
                        child: Text(
                          "${s.nom} ${s.prenom}",
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    )
                    .toList(),
            onChanged: (val) => controller.selectedStudentId.value = val,
            hint: "Choisir un étudiant",
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required Function(String?) onChanged,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.backgroundGrey,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              hint: Text(hint, style: const TextStyle(fontSize: 12)),
              items: [
                DropdownMenuItem<String>(
                  value: null,
                  child: Text(hint, style: const TextStyle(fontSize: 12)),
                ),
                ...items,
              ],
              onChanged: onChanged,
            ),
          ),
        ),
      ],
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
    bool disabled = false,
  }) {
    return Opacity(
      opacity: disabled ? 0.5 : 1.0,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: disabled ? null : onTap,
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
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: GoogleFonts.outfit(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
      ),
    );
  }

  void _handleExport(BuildContext context, String type, List<String> formats) {
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
            Text(
              "Format d'exportation",
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Comment souhaitez-vous recevoir ce fichier ?",
              style: GoogleFonts.outfit(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            ...formats.map((f) => _buildFormatOption(type, f)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatOption(String type, String format) {
    bool isExcel = format == "Excel" || format == "CSV";
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () {
          Get.back();
          _executeExport(type, format);
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.backgroundGrey,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Icon(
                isExcel
                    ? Icons.table_view_rounded
                    : Icons.picture_as_pdf_rounded,
                color: isExcel ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 12),
              Text(
                format,
                style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Icon(
                Icons.download_rounded,
                size: 20,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _executeExport(String type, String format) async {
    switch (type) {
      case "Étudiants":
        await controller.exportStudents(format);
        break;
      case "Enseignants":
        await controller.exportTeachers(format);
        break;
      case "Salles":
        await controller.exportLocations(format);
        break;
      case "Séance":
        await controller.exportSessionReport(format);
        break;
      case "Global":
        await controller.exportAttendance(format);
        break;
      case "BilanClasse":
        await controller.exportClassReport(format);
        break;
      case "HistoriqueEtudiant":
        await controller.exportStudentReport(format);
        break;
    }
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_utils.dart';
import '../../controllers/auth_controller.dart';
import '../../services/auth_service.dart';

class AcademicReferenceView extends StatefulWidget {
  const AcademicReferenceView({Key? key}) : super(key: key);

  @override
  State<AcademicReferenceView> createState() => _AcademicReferenceViewState();
}

class _AcademicReferenceViewState extends State<AcademicReferenceView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AuthController _authController = Get.find<AuthController>();
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      appBar: AppBar(
        title: Text(
          "Configuration Académique",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.cardBackground,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: "Années"),
            Tab(text: "Filières"),
            Tab(text: "Niveaux"),
            Tab(text: "Parcours"),
            Tab(text: "Matières"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAcademicYearList(),
          _buildFiliereList(),
          _buildLevelList(),
          _buildParcoursList(),
          _buildMatterList(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddForm,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  void _showAddForm() {
    switch (_tabController.index) {
      case 0:
        _showSimpleForm("Ajouter une Année", (name) => _authService.addAcademicYear(name));
        break;
      case 1:
        _showSimpleForm("Ajouter une Filière", (name) => _authService.addFiliere(name));
        break;
      case 2:
        _showSimpleForm("Ajouter un Niveau", (name) => _authService.addLevel(name));
        break;
      case 3:
        _showParcoursForm();
        break;
      case 4:
        _showMatterForm();
        break;
    }
  }

  void _showSimpleForm(String title, Future<bool> Function(String) onSave) {
    final controller = TextEditingController();
    Get.dialog(
      AlertDialog(
        title: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: "Nom",
            filled: true,
            fillColor: AppColors.backgroundGrey,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isEmpty) return;
              final success = await onSave(controller.text);
              if (success) {
                Get.back();
                _authController.fetchAcademicData();
                AppUtils.showSuccessToast("Enregistré avec succès");
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text("Enregistrer", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showParcoursForm() {
    final controller = TextEditingController();
    String? selectedFiliereId;
    
    Get.dialog(
      StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: Text("Ajouter un Parcours", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedFiliereId,
                  hint: const Text("Sélectionner la filière"),
                  items: _authController.filieres.map((f) => DropdownMenuItem(value: f.id, child: Text(f.nom))).toList(),
                  onChanged: (val) => setModalState(() => selectedFiliereId = val),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.backgroundGrey,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: "Nom du parcours",
                    filled: true,
                    fillColor: AppColors.backgroundGrey,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Get.back(), child: const Text("Annuler")),
              ElevatedButton(
                onPressed: () async {
                  if (controller.text.isEmpty || selectedFiliereId == null) return;
                  final success = await _authService.addParcours(controller.text, selectedFiliereId!);
                  if (success) {
                    Get.back();
                    _authController.fetchAcademicData(); // Note: might need to re-fetch parcours specifically if filtered
                    AppUtils.showSuccessToast("Enregistré avec succès");
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Text("Enregistrer", style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        }
      ),
    );
  }

  void _showMatterForm() {
    final nameController = TextEditingController();
    final codeController = TextEditingController();
    
    Get.dialog(
      AlertDialog(
        title: Text("Ajouter une Matière", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                hintText: "Nom de la matière",
                filled: true,
                fillColor: AppColors.backgroundGrey,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              decoration: InputDecoration(
                hintText: "Code (ex: INF101)",
                filled: true,
                fillColor: AppColors.backgroundGrey,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) return;
              final success = await _authService.addMatter(nameController.text, codeController.text);
              if (success) {
                Get.back();
                _authController.fetchAcademicData();
                AppUtils.showSuccessToast("Enregistré avec succès");
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text("Enregistrer", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildAcademicYearList() {
    return Obx(() => ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _authController.academicYears.length,
      itemBuilder: (context, index) {
        final a = _authController.academicYears[index];
        return _buildItemCard(a.nom, "ID: ${a.id}");
      },
    ));
  }

  Widget _buildFiliereList() {
    return Obx(() => ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _authController.filieres.length,
      itemBuilder: (context, index) {
        final f = _authController.filieres[index];
        return _buildItemCard(f.nom, "ID: ${f.id}");
      },
    ));
  }

  Widget _buildLevelList() {
    return Obx(() => ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _authController.levels.length,
      itemBuilder: (context, index) {
        final l = _authController.levels[index];
        return _buildItemCard(l.nom, "ID: ${l.id}");
      },
    ));
  }

  Widget _buildParcoursList() {
    return Obx(() => ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _authController.parcours.length,
      itemBuilder: (context, index) {
        final p = _authController.parcours[index];
        final filiere = _authController.filieres.firstWhereOrNull((f) => f.id == p.filiereId);
        return _buildItemCard(p.nom, "Filière: ${filiere?.nom ?? p.filiereId}");
      },
    ));
  }

  Widget _buildMatterList() {
    return Obx(() => ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _authController.matters.length,
      itemBuilder: (context, index) {
        final m = _authController.matters[index];
        return _buildItemCard(m.nom, "Code: ${m.code}");
      },
    ));
  }

  Widget _buildItemCard(String title, String subtitle) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        title: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 13)),
        trailing: Icon(Icons.chevron_right_rounded, color: AppColors.primary.withOpacity(0.5)),
      ),
    );
  }
}

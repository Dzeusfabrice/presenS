import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_modal.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/user_management_controller.dart';
import '../../models/class_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';

class ClassManagementView extends StatefulWidget {
  const ClassManagementView({Key? key}) : super(key: key);

  @override
  State<ClassManagementView> createState() => _ClassManagementViewState();
}

class _ClassManagementViewState extends State<ClassManagementView> {
  final AuthController _authController = Get.find<AuthController>();
  final UserManagementController _userController = Get.put(
    UserManagementController(),
  );
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _authController.fetchClasses();
  }

  int _getStudentCountForClass(String classId) {
    return _userController.usersList
        .where((u) => u.role == UserRole.ETUDIANT && u.classeId == classId)
        .length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      appBar: AppBar(
        title: const Text(
          "Gestion des Classes",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        foregroundColor: AppColors.cardBackground,
      ),
      body: Obx(() {
        final classes = _authController.classes;
        if (classes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.class_outlined, size: 80, color: AppColors.grey300),
                const SizedBox(height: 16),
                Text(
                  "Aucune classe trouvée",
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }
        return Column(
          children: [
            // En-tête avec statistiques
            _buildHeader(classes.length),

            // Liste des classes en grille
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.68,
                ),
                itemCount: classes.length,
                itemBuilder: (context, index) {
                  final classModel = classes[index];
                  return _buildClassCard(classModel, index);
                },
              ),
            ),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showClassForm(),
        backgroundColor: AppColors.primary,
        child: Icon(Icons.add, color: AppColors.cardBackground),
      ),
    );
  }

  // En-tête avec statistiques
  Widget _buildHeader(int totalClasses) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.school_rounded,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$totalClasses Classe${totalClasses > 1 ? 's' : ''}",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  "Groupes d'étudiants",
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Carte de classe moderne et originale
  Widget _buildClassCard(ClassModel classModel, int index) {
    final studentCount = _getStudentCountForClass(classModel.id);
    final bool isActive = classModel.nom.isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // Afficher les détails de la classe
          _showClassDetails(classModel, studentCount);
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primaryLight],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
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
                    child: CustomPaint(painter: _ClassPatternPainter()),
                  ),
                ),
              ),
              // Contenu
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // En-tête avec numéro et badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "#${index + 1}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isActive
                                    ? Colors.green.withOpacity(0.3)
                                    : Colors.red.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            isActive ? "ACTIVE" : "INACTIVE",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Nom de la classe - Flexible pour éviter le débordement
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 5),
                          Text(
                            classModel.nom,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (classModel.niveau.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(
                                  Icons.leaderboard_rounded,
                                  color: Colors.white70,
                                  size: 11,
                                ),
                                const SizedBox(width: 3),
                                Flexible(
                                  child: Text(
                                    classModel.niveau,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (classModel.parcours.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(
                                  Icons.book_rounded,
                                  color: Colors.white70,
                                  size: 11,
                                ),
                                const SizedBox(width: 3),
                                Flexible(
                                  child: Text(
                                    classModel.parcours,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 9,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Statistiques en bas
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.people_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "$studentCount",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(
                              Icons.more_vert_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                            color: Colors.white,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onSelected: (value) {
                              if (value == 'edit') {
                                _showClassForm(classModel: classModel);
                              } else if (value == 'delete') {
                                _confirmDelete(classModel);
                              } else if (value == 'details') {
                                _showClassDetails(classModel, studentCount);
                              }
                            },
                            itemBuilder:
                                (context) => [
                                  const PopupMenuItem(
                                    value: 'details',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.info_outline_rounded,
                                          color: AppColors.primary,
                                          size: 18,
                                        ),
                                        SizedBox(width: 8),
                                        Text("Détails"),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.edit_rounded,
                                          color: AppColors.primary,
                                          size: 18,
                                        ),
                                        SizedBox(width: 8),
                                        Text("Modifier"),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.delete_outline_rounded,
                                          color: Colors.red,
                                          size: 18,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          "Supprimer",
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                          ),
                        ],
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

  // Afficher les détails d'une classe
  void _showClassDetails(ClassModel classModel, int studentCount) {
    AppModal.showInfo(
      context: context,
      title: classModel.nom,
      message:
          "Niveau: ${classModel.niveau.isNotEmpty ? classModel.niveau : 'Non spécifié'}\n"
          "Parcours: ${classModel.parcours.isNotEmpty ? classModel.parcours : 'Non spécifié'}\n"
          "Nombre d'étudiants: $studentCount",
    );
  }

  void _showClassForm({ClassModel? classModel}) {
    final nameController = TextEditingController(text: classModel?.nom ?? '');
    final levelController = TextEditingController(
      text: classModel?.niveau ?? '',
    );
    final parcoursController = TextEditingController(
      text: classModel?.parcours ?? '',
    );
    String status = classModel != null ? "Active" : "Active";

    Get.bottomSheet(
      isScrollControlled: true,
      StatefulBuilder(
        builder: (BuildContext modalContext, setModalState) {
          return Container(
            height: MediaQuery.of(modalContext).size.height * 0.7,
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(30),
              ),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
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
                  classModel == null ? "Nouvelle Classe" : "Modifier la Classe",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildField(
                          nameController,
                          "Nom de la classe (ex: Licence 1)",
                          Icons.text_fields,
                        ),
                        const SizedBox(height: 16),
                        _buildField(
                          levelController,
                          "Niveau (L1, M2, etc.)",
                          Icons.leaderboard_outlined,
                        ),
                        const SizedBox(height: 16),
                        _buildField(
                          parcoursController,
                          "Parcours",
                          Icons.school_outlined,
                        ),
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.backgroundGrey,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.grey300,
                              width: 1,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: status,
                              isExpanded: true,
                              items: const [
                                DropdownMenuItem(
                                  value: "Active",
                                  child: Text("Active"),
                                ),
                                DropdownMenuItem(
                                  value: "Inactive",
                                  child: Text("Inactive"),
                                ),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setModalState(() => status = val);
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: () async {
                              print("🔵 Bouton Enregistrer cliqué - Début");

                              if (nameController.text.trim().isEmpty) {
                                print("❌ Nom vide");
                                AppModal.showError(
                                  context: modalContext,
                                  title: "Erreur",
                                  message: "Le nom de la classe est requis.",
                                );
                                return;
                              }

                              print("✅ Validation OK, traitement en cours...");

                              // Créer ou mettre à jour la classe
                              final newClass = ClassModel(
                                id:
                                    classModel?.id ??
                                    "c-${DateTime.now().millisecondsSinceEpoch}",
                                nom: nameController.text.trim(),
                                niveau: levelController.text.trim(),
                                parcours: parcoursController.text.trim(),
                              );

                              try {
                                bool success;
                                if (classModel == null) {
                                  // Créer une nouvelle classe
                                  print("📝 Création d'une nouvelle classe...");
                                  success = await _authService.addClass(
                                    newClass,
                                  );
                                  print("📝 Résultat création: $success");
                                  if (success) {
                                    print("✅ Classe créée avec succès");
                                    Get.back();
                                    _authController.fetchClasses();
                                    // Attendre un peu pour que le modal se ferme
                                    await Future.delayed(
                                      const Duration(milliseconds: 300),
                                    );
                                    AppModal.showSuccess(
                                      context: Get.context!,
                                      title: "Succès",
                                      message:
                                          "La classe a été créée avec succès.",
                                    );
                                  } else {
                                    print("❌ Échec de la création");
                                    AppModal.showError(
                                      context: modalContext,
                                      title: "Erreur",
                                      message:
                                          "Impossible de créer la classe. Veuillez réessayer.",
                                    );
                                  }
                                } else {
                                  // Mettre à jour la classe existante
                                  print("✏️ Mise à jour de la classe...");
                                  success = await _authService.updateClass(
                                    newClass,
                                  );
                                  print("✏️ Résultat mise à jour: $success");
                                  if (success) {
                                    print("✅ Classe modifiée avec succès");
                                    Get.back();
                                    _authController.fetchClasses();
                                    // Attendre un peu pour que le modal se ferme
                                    await Future.delayed(
                                      const Duration(milliseconds: 300),
                                    );
                                    AppModal.showSuccess(
                                      context: Get.context!,
                                      title: "Succès",
                                      message:
                                          "La classe a été modifiée avec succès.",
                                    );
                                  } else {
                                    print("❌ Échec de la modification");
                                    AppModal.showError(
                                      context: modalContext,
                                      title: "Erreur",
                                      message:
                                          "Impossible de modifier la classe. Veuillez réessayer.",
                                    );
                                  }
                                }
                              } catch (e) {
                                print("❌ Erreur exception: $e");
                                AppModal.showError(
                                  context: modalContext,
                                  title: "Erreur",
                                  message:
                                      "Une erreur est survenue: ${e.toString()}",
                                );
                              }
                            },
                            child: const Text(
                              "Enregistrer",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _confirmDelete(ClassModel classModel) {
    AppModal.showConfirmation(
      context: context,
      title: "Supprimer la classe",
      message:
          "Voulez-vous vraiment supprimer la classe ${classModel.nom} ? Cette action est irréversible.",
      confirmText: "Supprimer",
      cancelText: "Annuler",
      onConfirm: () {
        // Note: L'implémentation de la suppression de classe
        // devrait être ajoutée dans AuthService si l'API le supporte
        AppModal.showInfo(
          context: context,
          title: "Information",
          message:
              "La fonctionnalité de suppression de classe nécessite une implémentation API.",
        );
      },
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String label,
    IconData icon,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundGrey,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: AppColors.textSecondary.withOpacity(0.7),
            fontSize: 14,
          ),
          prefixIcon: Icon(
            icon,
            color: Colors.green.withOpacity(0.7),
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 16,
          ),
        ),
      ),
    );
  }
}

// Peintre pour créer un pattern original sur les cartes de classe
class _ClassPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white
          ..strokeWidth = 1.0
          ..style = PaintingStyle.stroke;

    // Lignes diagonales
    for (double i = 0; i < size.width + size.height; i += 20) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i - size.height, size.height),
        paint,
      );
    }

    // Cercles décoratifs
    final circlePaint =
        Paint()
          ..color = Colors.white.withOpacity(0.1)
          ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.2),
      30,
      circlePaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.8),
      25,
      circlePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

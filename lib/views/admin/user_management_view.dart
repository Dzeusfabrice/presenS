import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import '../../controllers/user_management_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_utils.dart';
import '../../core/widgets/app_modal.dart';
import '../../models/user_model.dart';
import '../../models/class_model.dart';
import 'package:google_fonts/google_fonts.dart';

class UserManagementView extends StatefulWidget {
  const UserManagementView({Key? key}) : super(key: key);

  @override
  State<UserManagementView> createState() => _UserManagementViewState();
}

class _UserManagementViewState extends State<UserManagementView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final UserManagementController controller = Get.put(
    UserManagementController(),
  );
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      appBar: AppBar(
        title: const Text(
          "Gestion Utilisateurs",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.cardBackground,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        actions: [
          Obx(
            () =>
                _tabController.index == 1
                    ? PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'import_csv') {
                          _importStudentsFromCSV(context);
                        }
                      },
                      itemBuilder:
                          (BuildContext context) => [
                            const PopupMenuItem<String>(
                              value: 'import_csv',
                              child: Text('Importer CSV Étudiants'),
                            ),
                          ],
                    )
                    : const SizedBox.shrink(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [Tab(text: "Enseignants"), Tab(text: "Étudiants")],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUserList(UserRole.ENSEIGNANT),
          _buildUserList(UserRole.ETUDIANT),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tabController.index == 0) {
            _showTeacherForm(context);
          } else {
            _showStudentForm(context);
          }
        },
        backgroundColor: AppColors.primary,
        child: Icon(
          Icons.person_add_alt_1_rounded,
          color: AppColors.cardBackground,
        ),
      ),
    );
  }

  Widget _buildUserList(UserRole role) {
    return Obx(() {
      // Filtrer par rôle d'abord
      var filteredUsers =
          controller.usersList.where((u) => u.role == role).toList();

      // Si c'est un étudiant et qu'un filtre de classe est sélectionné, filtrer par classe
      if (role == UserRole.ETUDIANT &&
          controller.selectedClassFilter.value != null) {
        filteredUsers =
            filteredUsers
                .where(
                  (u) => u.classeId == controller.selectedClassFilter.value,
                )
                .toList();
      }

      // Appliquer la recherche si un texte est saisi
      if (controller.searchQuery.value.isNotEmpty) {
        final query = controller.searchQuery.value.toLowerCase().trim();
        filteredUsers =
            filteredUsers.where((u) {
              final nom = u.nom.toLowerCase();
              final prenom = u.prenom.toLowerCase();
              final email = u.email.toLowerCase();
              final matricule = (u.matricule ?? '').toLowerCase();
              final matriculeEnseignant =
                  (u.matriculeEnseignant ?? '').toLowerCase();

              return nom.contains(query) ||
                  prenom.contains(query) ||
                  email.contains(query) ||
                  matricule.contains(query) ||
                  matriculeEnseignant.contains(query) ||
                  "$nom $prenom".contains(query);
            }).toList();
      }

      return Column(
        children: [
          // Unified Search and Filter Section
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              border: Border(
                bottom: BorderSide(color: AppColors.border.withOpacity(0.5)),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundGrey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => controller.searchQuery.value = value,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText:
                          role == UserRole.ETUDIANT
                              ? "Rechercher un étudiant..."
                              : "Rechercher un enseignant...",
                      hintStyle: GoogleFonts.outfit(
                        fontSize: 13,
                        color: AppColors.textSecondary.withOpacity(0.5),
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                      suffixIcon: Obx(
                        () =>
                            controller.searchQuery.value.isNotEmpty
                                ? IconButton(
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    size: 16,
                                  ),
                                  onPressed: () {
                                    controller.searchQuery.value = '';
                                    _searchController.clear();
                                  },
                                )
                                : const SizedBox.shrink(),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),

                // Class Filters for Students
                if (role == UserRole.ETUDIANT) ...[
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        // "All" Chip
                        _buildFilterChip(
                          label: "Toutes les classes",
                          isSelected:
                              controller.selectedClassFilter.value == null,
                          onSelected:
                              (val) =>
                                  controller.selectedClassFilter.value = null,
                        ),
                        const SizedBox(width: 8),
                        // Class list from controller
                        ...controller.classes.map((dynamic item) {
                          final cls = item as ClassModel;
                          final isSelected =
                              controller.selectedClassFilter.value == cls.id;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _buildFilterChip(
                              label: cls.nom,
                              isSelected: isSelected,
                              onSelected:
                                  (val) =>
                                      controller.selectedClassFilter.value =
                                          val ? cls.id : null,
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Liste des utilisateurs
          if (filteredUsers.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_off_rounded,
                      size: 64,
                      color: AppColors.grey300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      controller.searchQuery.value.isNotEmpty
                          ? "Aucun résultat trouvé pour \"${controller.searchQuery.value}\""
                          : role == UserRole.ETUDIANT &&
                              controller.selectedClassFilter.value != null
                          ? "Aucun étudiant trouvé pour cette classe"
                          : "Aucun utilisateur trouvé",
                      style: TextStyle(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredUsers.length,
                itemBuilder: (context, index) {
                  final user = filteredUsers[index];
                  return _buildUserCard(context, user);
                },
              ),
            ),
        ],
      );
    });
  }

  Widget _buildUserCard(BuildContext context, UserModel user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Optionnel: action au clic sur la carte
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // Avatar avec initiale
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      user.nom.isNotEmpty ? user.nom[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Nom de l'utilisateur
                Expanded(
                  child: Text(
                    "${user.nom} ${user.prenom}",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Menu more_vert
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert_rounded,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  color: Colors.white,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onSelected: (value) {
                    if (value == 'edit') {
                      if (user.role == UserRole.ENSEIGNANT) {
                        _showTeacherForm(context, user: user);
                      } else {
                        _showStudentForm(context, user: user);
                      }
                    } else if (value == 'delete') {
                      _confirmDelete(context, user);
                    }
                  },
                  itemBuilder:
                      (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(
                                Icons.edit_rounded,
                                color: AppColors.primary,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text("Modifier"),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.red,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
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
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, UserModel user) {
    AppModal.showConfirmation(
      context: context,
      title: "Supprimer l'utilisateur",
      message:
          "Voulez-vous vraiment supprimer ${user.nom} ${user.prenom} ? Cette action est irréversible.",
      confirmText: "Supprimer",
      cancelText: "Annuler",
      onConfirm: () {
        controller.deleteUser(user.id);
      },
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required Function(bool) onSelected,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.backgroundGrey,
      labelStyle: GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        color: isSelected ? AppColors.cardBackground : AppColors.textSecondary,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 0,
      pressElevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  // ── FORMULAIRE ENSEIGNANT ──────────────────────────────────────────────
  void _showTeacherForm(BuildContext context, {UserModel? user}) {
    final nomController = TextEditingController(text: user?.nom);
    final prenomController = TextEditingController(text: user?.prenom);
    final emailController = TextEditingController(text: user?.email);
    final matriculeController = TextEditingController(
      text: user?.matriculeEnseignant,
    );
    final deptController = TextEditingController(text: user?.departement);

    Get.bottomSheet(
      isScrollControlled: true,
      Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
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
              user == null ? "Nouvel Enseignant" : "Modifier Enseignant",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildField(nomController, "Nom", Icons.person_outline),
                    const SizedBox(height: 16),
                    _buildField(
                      prenomController,
                      "Prénom",
                      Icons.person_outline,
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      emailController,
                      "Email",
                      Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      matriculeController,
                      "Matricule Enseignant",
                      Icons.badge_outlined,
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      deptController,
                      "Département",
                      Icons.account_balance_outlined,
                    ),
                    const SizedBox(height: 32),
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
                          if (controller.isLoading.value) return;
                          if (nomController.text.isEmpty ||
                              prenomController.text.isEmpty ||
                              emailController.text.isEmpty) {
                            AppUtils.showWarningToast(
                              "Veuillez remplir au moins le nom, le prénom et l'email.",
                            );
                            return;
                          }
                          if (!GetUtils.isEmail(emailController.text)) {
                            AppUtils.showWarningToast(
                              "L'adresse email est invalide.",
                            );
                            return;
                          }

                          final newUser = UserModel(
                            id:
                                user?.id ??
                                "t-${DateTime.now().millisecondsSinceEpoch}",
                            nom: nomController.text,
                            prenom: prenomController.text,
                            email: emailController.text,
                            role: UserRole.ENSEIGNANT,
                            matriculeEnseignant: matriculeController.text,
                            departement: deptController.text,
                          );

                          bool success;
                          if (user == null)
                            success = await controller.addUser(newUser);
                          else
                            success = await controller.updateUser(newUser);

                          if (success) {
                            Get.back();
                          }
                        },
                        child: Obx(
                          () =>
                              controller.isLoading.value
                                  ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Text(
                                    "Enregistrer",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
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
      ),
    );
  }

  // ── FORMULAIRE ÉTUDIANT (Multi-étapes) ───────────────────────────────────
  void _showStudentForm(BuildContext context, {UserModel? user}) {
    final nomController = TextEditingController(text: user?.nom);
    final prenomController = TextEditingController(text: user?.prenom);
    final emailController = TextEditingController(text: user?.email);
    final matriculeController = TextEditingController(text: user?.matricule);
    final passwordController = TextEditingController();
    int currentStep = 0;
    final int totalSteps = 2;
    final PageController pageController = PageController();
    final selectedClasseId = Rxn<String>(user?.classeId);

    Get.bottomSheet(
      isScrollControlled: true,
      StatefulBuilder(
        builder: (context, setLocalState) {
          final isMobile = MediaQuery.of(context).size.width < 600;

          return Container(
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.grey500,
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  user == null ? "Nouvel Étudiant" : "Modifier Étudiant",
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 24),

                // Barre de progression style Register
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Étape ${currentStep + 1} / $totalSteps",
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            "${((currentStep + 1) / totalSteps * 100).toInt()}%",
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Stack(
                        children: [
                          Container(
                            height: 6,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: AppColors.grey100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOutCubic,
                            height: 6,
                            width:
                                (MediaQuery.of(context).size.width - 48) *
                                ((currentStep + 1) / totalSteps),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: AppColors.mainGradient,
                              ),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.25),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                Expanded(
                  child: PageView(
                    controller: pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      // Étape 1 : Identité
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              _buildModernField(
                                nomController,
                                "Nom",
                                "Nom de famille",
                                Icons.person_outline_rounded,
                                isMobile: isMobile,
                              ),
                              const SizedBox(height: 20),
                              _buildModernField(
                                prenomController,
                                "Prénom",
                                "Prénom de l'étudiant",
                                Icons.person_outline_rounded,
                                isMobile: isMobile,
                              ),
                              const SizedBox(height: 20),
                              _buildModernField(
                                emailController,
                                "Email",
                                "votre@email.com",
                                Icons.alternate_email_rounded,
                                keyboardType: TextInputType.emailAddress,
                                isMobile: isMobile,
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Étape 2 : Cursus & Sécurité
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildModernField(
                                matriculeController,
                                "Matricule",
                                "Numéro matricule",
                                Icons.badge_outlined,
                                isMobile: isMobile,
                              ),
                              const SizedBox(height: 20),
                              _buildModernDropdown(
                                setLocalState,
                                selectedClasseId,
                                isMobile,
                              ),
                              const SizedBox(height: 24),
                              if (user == null) ...[
                                Text(
                                  "Sécurité",
                                  style: GoogleFonts.outfit(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildModernField(
                                  passwordController,
                                  "Mot de passe",
                                  "••••••••",
                                  Icons.lock_outline_rounded,
                                  isMobile: isMobile,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Boutons Navigation Style Register
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      if (currentStep > 0) ...[
                        GestureDetector(
                          onTap: () {
                            setLocalState(() => currentStep--);
                            pageController.previousPage(
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.fastOutSlowIn,
                            );
                          },
                          child: Container(
                            height: 56,
                            width: 56,
                            decoration: BoxDecoration(
                              color: AppColors.backgroundGrey,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: AppColors.textPrimary,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            if (controller.isLoading.value) return;
                            if (currentStep == 0) {
                              if (nomController.text.trim().isEmpty ||
                                  prenomController.text.trim().isEmpty ||
                                  !GetUtils.isEmail(
                                    emailController.text.trim(),
                                  )) {
                                AppUtils.showWarningToast(
                                  "Veuillez remplir les informations d'identité.",
                                );
                                return;
                              }
                              setLocalState(() => currentStep++);
                              pageController.nextPage(
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.fastOutSlowIn,
                              );
                            } else {
                              if (matriculeController.text.trim().isEmpty ||
                                  selectedClasseId.value == null) {
                                AppUtils.showWarningToast(
                                  "Veuillez remplir le matricule et la classe.",
                                );
                                return;
                              }
                              if (user == null &&
                                  passwordController.text.length < 6) {
                                AppUtils.showWarningToast(
                                  "Le mot de passe doit faire au moins 6 caractères.",
                                );
                                return;
                              }

                              final currentId = selectedClasseId.value;
                              final selectedClass = controller.classes
                                  .firstWhere(
                                    (c) => c.id == currentId,
                                    orElse: () => null,
                                  );

                              final newUser = UserModel(
                                id:
                                    user?.id ??
                                    "s-${DateTime.now().millisecondsSinceEpoch}",
                                nom: nomController.text.trim(),
                                prenom: prenomController.text.trim(),
                                email: emailController.text.trim(),
                                role: UserRole.ETUDIANT,
                                matricule: matriculeController.text.trim(),
                                classeId: currentId,
                                niveau: selectedClass?.niveau ?? "",
                                parcours: selectedClass?.parcours ?? "",
                                password:
                                    user == null
                                        ? passwordController.text
                                        : null,
                                isActive: user?.isActive ?? true,
                              );

                              bool success;
                              if (user == null)
                                success = await controller.addUser(newUser);
                              else
                                success = await controller.updateUser(newUser);

                              if (success) {
                                Get.back();
                              }
                            }
                          },
                          child: Container(
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: AppColors.mainGradient,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Obx(
                                () =>
                                    controller.isLoading.value
                                        ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                        : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              currentStep == 0
                                                  ? "Suivant"
                                                  : "Enregistrer",
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Icon(
                                              currentStep == 0
                                                  ? Icons.arrow_forward_rounded
                                                  : Icons.check_circle_rounded,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                          ],
                                        ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildModernField(
    TextEditingController controller,
    String label,
    String hint,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    bool isMobile = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary.withOpacity(0.85),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.backgroundGrey.withOpacity(0.6),
            borderRadius: BorderRadius.circular(18),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.outfit(
                color: AppColors.textSecondary.withOpacity(0.5),
                fontSize: 15,
              ),
              prefixIcon: Icon(
                icon,
                color: AppColors.primary.withOpacity(0.7),
                size: 20,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 18,
                horizontal: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernDropdown(
    Function setLocalState,
    Rxn<String> selectedClasseId,
    bool isMobile,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            "Classe",
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary.withOpacity(0.85),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.backgroundGrey.withOpacity(0.6),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.grey500, width: 1.2),
          ),
          child: Obx(
            () => DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedClasseId.value,
                isExpanded: true,
                hint: Text(
                  "Sélectionner la classe",
                  style: GoogleFonts.outfit(
                    color: AppColors.textSecondary.withOpacity(0.5),
                    fontSize: 15,
                  ),
                ),
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.primary,
                ),
                items:
                    controller.classes.map((dynamic item) {
                      final cls = item as ClassModel;
                      // Concaténer le nom et le niveau pour plus de précision
                      final String labelDisplay =
                          cls.niveau.isNotEmpty
                              ? "${cls.nom} (${cls.niveau})"
                              : cls.nom;

                      return DropdownMenuItem<String>(
                        value: cls.id,
                        child: Text(
                          labelDisplay,
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                onChanged: (val) {
                  selectedClasseId.value = val;
                  // On force un rebuild local si nécessaire, bien que Obx s'en occupe
                  setLocalState(() {});
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary.withOpacity(0.85),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.backgroundGrey.withOpacity(0.6),
            borderRadius: BorderRadius.circular(16),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: GoogleFonts.outfit(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(
                icon,
                color: AppColors.primary.withOpacity(0.7),
                size: 20,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 16,
                horizontal: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _importStudentsFromCSV(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null) {
        final file = result.files.first;
        final input = String.fromCharCodes(file.bytes!);
        final fields = CsvToListConverter().convert(input);

        if (fields.isEmpty) {
          AppUtils.showErrorToast("Le fichier CSV est vide");
          return;
        }

        // Assuming CSV format: nom,prenom,email,matricule,classeId,niveau,parcours
        final headers =
            fields[0].map((e) => e.toString().toLowerCase()).toList();
        final dataRows = fields.sublist(1);

        List<UserModel> students = [];
        for (var row in dataRows) {
          if (row.length < 7) continue; // Skip invalid rows

          final student = UserModel(
            id: '', // Will be set by backend
            nom: row[0].toString(),
            prenom: row[1].toString(),
            email: row[2].toString(),
            role: UserRole.ETUDIANT,
            matricule: row[3].toString(),
            classeId: row[4].toString(),
            niveau: row[5].toString(),
            parcours: row[6].toString(),
          );
          students.add(student);
        }

        if (students.isEmpty) {
          AppUtils.showErrorToast("Aucun étudiant valide trouvé dans le CSV");
          return;
        }

        // Show confirmation dialog
        final confirmed = await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text("Confirmer l'import"),
                content: Text(
                  "Voulez-vous importer ${students.length} étudiant(s) ?",
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text("Annuler"),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text("Importer"),
                  ),
                ],
              ),
        );

        if (confirmed == true) {
          final success = await controller.addUsersBulk(students);
          if (success) {
            AppUtils.showSuccessToast(
              "${students.length} étudiant(s) importé(s) avec succès",
            );
          }
        }
      }
    } catch (e) {
      AppUtils.showErrorToast("Erreur lors de l'import: $e");
    }
  }
}

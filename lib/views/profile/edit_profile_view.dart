import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/auth_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_utils.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';

class EditProfileView extends StatefulWidget {
  const EditProfileView({Key? key}) : super(key: key);

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  final AuthController _authController = Get.find<AuthController>();
  final AuthService _authService = AuthService();

  late TextEditingController _nameController;
  late TextEditingController _prenomController;
  late TextEditingController _emailController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;

  // Role specific controllers
  late TextEditingController _deptController;
  late TextEditingController _gradeController;
  late TextEditingController _niveauController;
  late TextEditingController _parcoursController;

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = _authController.user.value;
    _nameController = TextEditingController(text: user?.nom ?? "");
    _prenomController = TextEditingController(text: user?.prenom ?? "");
    _emailController = TextEditingController(text: user?.email ?? "");
    _usernameController = TextEditingController(
      text: user?.matricule ?? user?.matriculeEnseignant ?? "",
    );
    _passwordController = TextEditingController();

    _deptController = TextEditingController(text: user?.departement ?? "");
    _gradeController = TextEditingController(text: user?.grade ?? "");
    _niveauController = TextEditingController(text: user?.niveau ?? "");
    _parcoursController = TextEditingController(text: user?.parcours ?? "");
  }

  @override
  void dispose() {
    _nameController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _deptController.dispose();
    _gradeController.dispose();
    _niveauController.dispose();
    _parcoursController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    // Validation des champs obligatoires
    if (_nameController.text.trim().isEmpty) {
      AppUtils.showWarningToast("Le nom est obligatoire");
      return;
    }

    if (_prenomController.text.trim().isEmpty) {
      AppUtils.showWarningToast("Le prénom est obligatoire");
      return;
    }

    if (_emailController.text.trim().isEmpty) {
      AppUtils.showWarningToast("L'adresse email est obligatoire");
      return;
    }

    if (!GetUtils.isEmail(_emailController.text.trim())) {
      AppUtils.showWarningToast("L'adresse email est invalide");
      return;
    }

    // Validation du mot de passe si fourni
    if (_passwordController.text.isNotEmpty &&
        _passwordController.text.length < 6) {
      AppUtils.showWarningToast(
        "Le mot de passe doit contenir au moins 6 caractères",
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = _authController.user.value;
      if (user == null) {
        AppUtils.showErrorToast("Utilisateur non trouvé");
        setState(() => _isLoading = false);
        return;
      }

      // Construire l'objet utilisateur mis à jour
      final updatedUser = user.copyWith(
        nom: _nameController.text.trim(),
        prenom: _prenomController.text.trim(),
        email: _emailController.text.trim(),
        departement: _deptController.text.trim().isEmpty
            ? null
            : _deptController.text.trim(),
        grade: _gradeController.text.trim().isEmpty
            ? null
            : _gradeController.text.trim(),
        niveau: _niveauController.text.trim().isEmpty
            ? null
            : _niveauController.text.trim(),
        parcours: _parcoursController.text.trim().isEmpty
            ? null
            : _parcoursController.text.trim(),
        password: _passwordController.text.isNotEmpty
            ? _passwordController.text
            : null,
      );

      // Appeler l'API pour mettre à jour
      final success = await _authService.updateUser(updatedUser);

      if (success) {
        // Mettre à jour le contrôleur avec les nouvelles données
        _authController.user.value = updatedUser;
        AppUtils.showSuccessToast("Profil mis à jour avec succès");
        Get.back();
      } else {
        AppUtils.showErrorToast("Erreur lors de la mise à jour du profil");
      }
    } catch (e) {
      AppUtils.handleError(e);
      AppUtils.showErrorToast(
        "Une erreur est survenue. Veuillez réessayer.",
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final user = _authController.user.value;
      if (user == null) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }

      return Scaffold(
        backgroundColor: AppColors.backgroundGrey,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Get.back(),
            color: AppColors.textPrimary,
          ),
          title: Text(
            "Modifier Profil",
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          centerTitle: true,
          backgroundColor: AppColors.cardBackground,
          elevation: 0,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _saveProfile,
              child: Text(
                "Sauver",
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildProfileImageEdit(user),
          const SizedBox(height: 40),
          _buildEditForm(user),
          const SizedBox(height: 24),
        ],
      ),
      ),
    );
    });
  }

  Widget _buildProfileImageEdit(UserModel user) {
    final initial = user.prenom.isNotEmpty ? user.prenom[0].toUpperCase() : "U";
    return Center(
      child: Stack(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(0.1),
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: GoogleFonts.outfit(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditForm(UserModel user) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField(
            controller: _prenomController,
            label: "Prénom",
            icon: Icons.person_outline_rounded,
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _nameController,
            label: "Nom",
            icon: Icons.person_outline_rounded,
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _emailController,
            label: "Adresse E-mail",
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),

          if (user.role == UserRole.ENSEIGNANT) ...[
            const SizedBox(height: 32),
            _buildFieldLabel("Informations Professionnelles"),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _deptController,
              label: "Département",
              icon: Icons.apartment_rounded,
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _gradeController,
              label: "Grade",
              icon: Icons.business_center_outlined,
            ),
          ],

          if (user.role == UserRole.ETUDIANT) ...[
            const SizedBox(height: 32),
            _buildFieldLabel("Informations Académiques"),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _niveauController,
              label: "Niveau",
              icon: Icons.school_outlined,
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _parcoursController,
              label: "Parcours",
              icon: Icons.auto_awesome_mosaic_outlined,
            ),
          ],

          const SizedBox(height: 32),
          _buildFieldLabel("Sécurité"),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _usernameController,
            label: "Matricule",
            icon: Icons.badge_outlined,
            enabled: false,
          ),
          const SizedBox(height: 20),
          _buildPasswordField(),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color:
                enabled
                    ? AppColors.backgroundGrey
                    : AppColors.backgroundGrey.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: TextField(
            controller: controller,
            enabled: enabled,
            keyboardType: keyboardType,
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: enabled ? AppColors.textPrimary : AppColors.textSecondary,
            ),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: GoogleFonts.outfit(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
              prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundGrey,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        style: GoogleFonts.outfit(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          labelText: "Nouveau mot de passe",
          labelStyle: GoogleFonts.outfit(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
          prefixIcon: Icon(
            Icons.lock_outline_rounded,
            color: AppColors.textSecondary,
            size: 20,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: AppColors.textSecondary,
              size: 20,
            ),
            onPressed:
                () => setState(() => _obscurePassword = !_obscurePassword),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }
}

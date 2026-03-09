import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../models/user_model.dart';
import '../admin/settings_management_view.dart';
import 'edit_profile_view.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({Key? key}) : super(key: key);

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final AuthController authController = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      body: Obx(() {
        final user = authController.user.value;
        if (user == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildAppBar(user),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildSectionHeader("INFORMATIONS PERSONNELLES"),
                    _buildUserInfoList(user),

                    const SizedBox(height: 24),
                    _buildSectionHeader(
                      user.role == UserRole.ETUDIANT
                          ? "ACADÉMIQUE"
                          : "PROFESSIONNEL",
                    ),
                    _buildRoleSpecificList(user),

                    const SizedBox(height: 24),
                    _buildSectionHeader("PARAMÈTRES ET SÉCURITÉ"),
                    _buildSettingsList(authController),

                    const SizedBox(height: 48),
                    _buildLogoutButton(authController),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildAppBar(UserModel user) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: AppColors.primary,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: Colors.white,
          ),
        ),
        onPressed: () => Get.back(),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.edit_note_rounded, color: Colors.white),
          ),
          onPressed: () => Get.to(() => const EditProfileView()),
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image
            Image.asset(
              'assets/images/etudiantglasmorph.jpg',
              fit: BoxFit.cover,
            ),
            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    AppColors.primary.withOpacity(0.8),
                  ],
                ),
              ),
            ),
            // User Profile Info
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildAvatar(user),
                const SizedBox(height: 12),
                Text(
                  "${user.prenom} ${user.nom}",
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  user.email,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(UserModel user) {
    final initial = user.prenom.isNotEmpty ? user.prenom[0].toUpperCase() : "U";
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            color: Colors.white.withOpacity(0.2),
            child: Center(
              child: Text(
                initial,
                style: GoogleFonts.outfit(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary.withOpacity(0.7),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildUserInfoList(UserModel user) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          _buildModernRow(
            icon: Icons.badge_outlined,
            label: "Rôle",
            value: user.role.name.toUpperCase(),
            color: AppColors.primary,
          ),
          _buildModernRow(
            icon: Icons.numbers_rounded,
            label: "Matricule",
            value:
                (user.role == UserRole.ETUDIANT
                    ? user.matricule
                    : user.matriculeEnseignant) ??
                "N/A",
            color: Colors.orange,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildRoleSpecificList(UserModel user) {
    if (user.role == UserRole.ETUDIANT) {
      return Container(
        color: Colors.white,
        child: Column(
          children: [
            _buildModernRow(
              icon: Icons.school_outlined,
              label: "Niveau",
              value: user.niveau ?? "N/A",
              color: AppColors.success,
            ),
            _buildModernRow(
              icon: Icons.class_outlined,
              label: "Classe",
              value: user.classeId ?? "N/A",
              color: Colors.purple,
            ),
            _buildModernRow(
              icon: Icons.auto_awesome_mosaic_outlined,
              label: "Parcours",
              value: user.parcours ?? "Général",
              color: Colors.indigo,
              isLast: true,
            ),
          ],
        ),
      );
    } else if (user.role == UserRole.ENSEIGNANT) {
      return Container(
        color: Colors.white,
        child: Column(
          children: [
            _buildModernRow(
              icon: Icons.business_center_outlined,
              label: "Grade",
              value: user.grade ?? "Enseignant",
              color: AppColors.success,
            ),
            _buildModernRow(
              icon: Icons.apartment_rounded,
              label: "Département",
              value: user.departement ?? "Non spécifié",
              color: Colors.purple,
              isLast: true,
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildSettingsList(AuthController auth) {
    final themeController = Get.find<ThemeController>();
    return Container(
      color: AppColors.cardBackground,
      child: Column(
        children: [
          _buildMenuTile(
            icon: Icons.manage_accounts_rounded,
            title: "Modifier le profil",
            subtitle: "Nom, email, informations",
            onTap: () => Get.to(() => const EditProfileView()),
          ),
          _buildMenuTile(
            icon: Icons.security_rounded,
            title: "Sécurité",
            subtitle: "Changer le mot de passe",
            onTap: () => Get.to(() => const EditProfileView()),
          ),
          Obx(
            () => _buildMenuTile(
              icon:
                  themeController.isDarkMode
                      ? Icons.dark_mode_rounded
                      : Icons.light_mode_rounded,
              title: "Mode Sombre",
              subtitle: themeController.isDarkMode ? "Activé" : "Désactivé",
              trailing: Switch.adaptive(
                value: themeController.isDarkMode,
                onChanged: (val) => themeController.toggleTheme(),
                activeColor: AppColors.primary,
              ),
              onTap: () => themeController.toggleTheme(),
            ),
          ),
          _buildMenuTile(
            icon: Icons.settings_rounded,
            title: "Paramètres",
            subtitle: "Paramètres de l'application",
            onTap: () {
              // Rediriger vers la page des paramètres complets si admin
              // Sinon, on peut créer une vue simplifiée pour les autres rôles
              final user = auth.user.value;
              if (user?.role == UserRole.ADMIN) {
                Get.to(() => const SettingsManagementView());
              } else {
                // Pour les autres rôles, on peut aussi accéder aux paramètres
                Get.to(() => const SettingsManagementView());
              }
            },
          ),
          _buildMenuTile(
            icon: Icons.language_rounded,
            title: "Langue",
            subtitle: "Français (FR)",
            onTap: () {},
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(AuthController auth) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: InkWell(
        onTap: () => _showLogoutDialog(auth),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: AppColors.error.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.error.withOpacity(0.1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.logout_rounded,
                color: AppColors.error,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                "Déconnexion",
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool isLast = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 24),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border:
              isLast
                  ? null
                  : Border(
                    bottom: BorderSide(color: Colors.grey.withOpacity(0.1)),
                  ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    value,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.grey300,
              size: 20,
            ),
            const SizedBox(width: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? color,
    Widget? trailing,
    bool isLast = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 24),
      child: Container(
        decoration: BoxDecoration(
          border:
              isLast
                  ? null
                  : Border(
                    bottom: BorderSide(color: Colors.grey.withOpacity(0.1)),
                  ),
        ),
        child: ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.only(right: 24, top: 4, bottom: 4),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (color ?? AppColors.primary).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color ?? AppColors.primary, size: 18),
          ),
          title: Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: color ?? AppColors.textPrimary,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          trailing:
              trailing ??
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.grey300,
                size: 20,
              ),
        ),
      ),
    );
  }

  void _showLogoutDialog(AuthController auth) {
    Get.dialog(
      BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            "Déconnexion",
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
          content: Text(
            "Êtes-vous sûr de vouloir vous déconnecter ?",
            style: GoogleFonts.outfit(),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text(
                "Annuler",
                style: GoogleFonts.outfit(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Get.back();
                auth.logout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                "Déconnexion",
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

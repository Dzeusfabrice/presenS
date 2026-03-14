import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/admin_stats_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/watermark_background.dart';
import 'user_management_view.dart';
import 'location_management_view.dart';
import 'class_management_view.dart';
import 'export_management_view.dart';
import 'settings_management_view.dart';
import 'academic_reference_view.dart';
import 'location_qr_view.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final statsController = Get.put(AdminStatsController());

    return Obx(() {
      // Observer le thème pour forcer la reconstruction
      Get.find<ThemeController>().isDarkMode;
      return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      body: WatermarkBackground(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  // Header Background Image
                  Container(
                    height: 280,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/images/admin1.jpg'),
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

                  SafeArea(
                    child: Column(
                      children: [
                        _buildCustomAppBar(authController),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 20,
                          ),
                          child: _buildGlobalStats(statsController),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 4),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 24,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: AppColors.mainGradient,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "Gestion du système",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                child: _buildAdminMenu(),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
    });
  }

  Widget _buildCustomAppBar(AuthController auth) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          // Section gauche : Logo et informations
          Expanded(
            child: Row(
              children: [
                // Icône d'administration
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.cardBackground.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.admin_panel_settings_rounded,
                    color: AppColors.cardBackground,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                // Titre et nom d'utilisateur
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Administration",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          letterSpacing: -0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Obx(() {
                        final user = auth.user.value;
                        if (user != null) {
                          return Text(
                            "${user.prenom} ${user.nom}",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          );
                        }
                        return const SizedBox.shrink();
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Section droite : Actions
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Bouton Paramètres
              _buildActionButton(
                icon: Icons.settings_rounded,
                tooltip: "Paramètres",
                onPressed: () => Get.to(() => const SettingsManagementView()),
              ),
              const SizedBox(width: 8),
              // Bouton Déconnexion
              _buildActionButton(
                icon: Icons.logout_rounded,
                tooltip: "Déconnexion",
                onPressed: () => auth.logout(),
                isDestructive: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Widget réutilisable pour les boutons d'action dans l'AppBar
  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    bool isDestructive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Tooltip(
          message: tooltip,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color:
                  isDestructive
                      ? Colors.red.withOpacity(0.2)
                      : AppColors.cardBackground.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    isDestructive
                        ? Colors.red.withOpacity(0.4)
                        : AppColors.cardBackground.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(icon, color: AppColors.cardBackground, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildGlobalStats(AdminStatsController statsController) {
    return Obx(() {
      if (statsController.isLoading.value) {
        return Container(
          height: 100,
          alignment: Alignment.center,
          child: CircularProgressIndicator(color: AppColors.cardBackground),
        );
      }
      return Row(
        children: [
          Expanded(
            child: _buildAdminStat(
              "Étudiants",
              _formatNumber(statsController.studentsCount.value),
              Icons.people_rounded,
              Colors.blueAccent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildAdminStat(
              "Enseignants",
              _formatNumber(statsController.teachersCount.value),
              Icons.school_rounded,
              Colors.orangeAccent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildAdminStat(
              "Salles",
              _formatNumber(statsController.locationsCount.value),
              Icons.room_rounded,
              Colors.greenAccent,
            ),
          ),
        ],
      );
    });
  }

  Widget _buildAdminStat(
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
            child: Icon(icon, color: AppColors.cardBackground, size: 16),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: AppColors.cardBackground,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.cardBackground.withOpacity(0.6),
              fontSize: 10,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return "${(number / 1000).toStringAsFixed(1)}k";
    }
    return number.toString();
  }

  Widget _buildAdminMenu() {
    final menuItems = [
      _MenuItemData(
        icon: Icons.people_alt_rounded,
        title: "Utilisateurs",
        subtitle: "Gérer les comptes",
        color: Colors.blue,
        onTap: () => Get.to(() => const UserManagementView()),
      ),
      _MenuItemData(
        icon: Icons.room_preferences_rounded,
        title: "Salles / Lieux",
        subtitle: "Espaces de cours",
        color: Colors.orange,
        onTap: () => Get.to(() => const LocationManagementView()),
      ),
      _MenuItemData(
        icon: Icons.class_rounded,
        title: "Classes",
        subtitle: "Groupes d'élèves",
        color: Colors.green,
        onTap: () => Get.to(() => const ClassManagementView()),
      ),
      _MenuItemData(
        icon: Icons.history_edu_rounded,
        title: "Configuration",
        subtitle: "Données académiques",
        color: Colors.indigo,
        onTap: () => Get.to(() => const AcademicReferenceView()),
      ),
      _MenuItemData(
        icon: Icons.file_download_rounded,
        title: "Exports des Données",
        subtitle: "Rapports & Data",
        color: Colors.purple,
        onTap: () => Get.to(() => ExportManagementView()),
      ),
      _MenuItemData(
        icon: Icons.qr_code_2_rounded,
        title: "Générateur QR",
        subtitle: "Salles & Lieux",
        color: Colors.teal,
        onTap: () => Get.to(() => const LocationQrView()),
      ),
    // _MenuItemData(
    //   icon: Icons.settings_rounded,
    //   title: "Paramètres",
    //   subtitle: "Config. système",
    //   color: Colors.blueGrey,
    //   onTap: () => Get.to(() => const SettingsManagementView()),
    // ),
    // _MenuItemData(
    //   icon: Icons.shield_rounded,
    //   title: "Sécurité",
    //   subtitle: "Logs & Accès",
    //   color: Colors.redAccent,
    //   onTap: () => Get.to(() => const SecurityManagementView()),
    // ),
  ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: menuItems.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.95,
      ),
      itemBuilder: (context, index) {
        return _buildAdminMenuItem(menuItems[index], index: index);
      },
    );
  }

  Widget _buildAdminMenuItem(_MenuItemData item, {required int index}) {
    return TweenAnimationBuilder<double>(
    duration: Duration(milliseconds: 300 + (index * 100)),
    tween: Tween(begin: 0.0, end: 1.0),
    curve: Curves.easeOutCubic,
    builder: (context, value, child) {
      return Transform.translate(
        offset: Offset(0, 20 * (1 - value)),
        child: Opacity(opacity: value, child: child),
      );
    },
    child: GestureDetector(
      onTap: item.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: item.color.withOpacity(0.2), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: item.color.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: AppColors.textPrimary.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Fond dégradé subtil
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [item.color.withOpacity(0.03), Colors.transparent],
                  ),
                ),
              ),
            ),
            // Icône de fond
            Positioned(
              right: -15,
              top: -15,
              child: Icon(
                item.icon,
                size: 100,
                color: item.color.withOpacity(0.05),
              ),
            ),
            // Contenu
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Icône principale
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: item.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: item.color.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(item.icon, color: item.color, size: 26),
                  ),
                  const Spacer(flex: 1),
                  // Titre et sous-titre
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.title,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          letterSpacing: -0.5,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.subtitle,
                        style: TextStyle(
                          color: AppColors.textSecondary.withOpacity(0.8),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Flèche d'action
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: item.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          color: item.color,
                          size: 14,
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
    ),
    );
  }
}

class _MenuItemData {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;  _MenuItemData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
}

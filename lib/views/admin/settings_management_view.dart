import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_utils.dart';
import '../../controllers/theme_controller.dart';

class SettingsManagementView extends StatefulWidget {
  const SettingsManagementView({Key? key}) : super(key: key);

  @override
  State<SettingsManagementView> createState() => _SettingsManagementViewState();
}

class _SettingsManagementViewState extends State<SettingsManagementView> {
  final ThemeController _themeController = Get.find<ThemeController>();
  bool _notificationsEnabled = true;
  bool _autoSync = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
      _autoSync = prefs.getBool('autoSync') ?? true;
    });
  }

  Future<void> _toggleDarkMode(bool val) async {
    await _themeController.setTheme(val);
    setState(() {});
  }

  Future<void> _saveNotificationSetting(bool value) async {
    setState(() => _notificationsEnabled = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', value);
    AppUtils.showSuccessToast(
      value ? "Notifications activées" : "Notifications désactivées",
    );
  }

  Future<void> _saveAutoSyncSetting(bool value) async {
    setState(() => _autoSync = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('autoSync', value);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      appBar: AppBar(
        title: Text(
          "Paramètres",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.cardBackground,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionLabel("Apparence"),
            const SizedBox(height: 12),
            _buildSettingCard(
              children: [
                Obx(() {
                  final isDark = _themeController.isDarkMode;
                  return _buildSwitchSetting(
                    icon: isDark
                        ? Icons.dark_mode_rounded
                        : Icons.light_mode_rounded,
                    iconColor: isDark ? Colors.indigo : Colors.amber,
                    title: "Mode Sombre",
                    subtitle:
                        isDark ? "Thème sombre activé" : "Thème clair activé",
                    value: isDark,
                    onChanged: _toggleDarkMode,
                  );
                }),
              ],
            ),

            const SizedBox(height: 24),
            _buildSectionLabel("Notifications"),
            const SizedBox(height: 12),
            _buildSettingCard(
              children: [
                _buildSwitchSetting(
                  icon: Icons.notifications_active_rounded,
                  iconColor: Colors.orange,
                  title: "Notifications Push",
                  subtitle: "Activer les notifications système",
                  value: _notificationsEnabled,
                  onChanged: _saveNotificationSetting,
                ),
              ],
            ),

            const SizedBox(height: 24),
            _buildSectionLabel("Système"),
            const SizedBox(height: 12),
            _buildSettingCard(
              children: [
                _buildSwitchSetting(
                  icon: Icons.sync_rounded,
                  iconColor: Colors.teal,
                  title: "Synchronisation auto",
                  subtitle: "Mise à jour automatique des données",
                  value: _autoSync,
                  onChanged: _saveAutoSyncSetting,
                ),
                _buildDivider(),
               
              ],
            ),

            const SizedBox(height: 24),
            _buildSectionLabel("À propos"),
            const SizedBox(height: 12),
            _buildSettingCard(
              children: [
                _buildInfoTile(
                  icon: Icons.info_outline_rounded,
                  title: "Version",
                  value: "1.0.0",
                ),
                _buildDivider(),
                _buildInfoTile(
                  icon: Icons.shield_outlined,
                  title: "Politique de confidentialité",
                  value: "Voir",
                ),
                _buildDivider(),
                _buildInfoTile(
                  icon: Icons.description_outlined,
                  title: "Conditions d'utilisation",
                  value: "Voir",
                ),
              ],
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String title) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.outfit(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildSettingCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchSetting({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    Future<void> Function(bool)? onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 12),
      ),
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged != null ? (v) => onChanged(v) : null,
        activeColor: AppColors.primary,
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.backgroundGrey,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15),
      ),
      trailing: Text(
        value,
        style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 13),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      indent: 64,
      color: AppColors.border.withOpacity(0.5),
    );
  }
}

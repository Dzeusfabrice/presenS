import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_utils.dart';

class SecurityManagementView extends StatelessWidget {
  const SecurityManagementView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      appBar: AppBar(
        title: const Text(
          "Sécurité et Accès",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Confidentialité et Authentification",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            _buildActionCard(
              icon: Icons.password_rounded,
              title: "Politique de mot de passe",
              subtitle: "Forcer la complexité des mots de passe",
              onTap: () {
                AppUtils.showSuccessToast("Paramètres de sécurité mis à jour.");
              },
            ),
            const SizedBox(height: 12),
            _buildActionCard(
              icon: Icons.history_rounded,
              title: "Historique des connexions",
              subtitle: "Voir les dernières tentatives d'accès",
              onTap: () {
                // Future view implementation
              },
            ),
            const SizedBox(height: 32),
            const Text(
              "Sessions Actives",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.redAccent,
              ),
            ),
            const SizedBox(height: 16),
            _buildSessionCard(
              device: "Windows 10 - Chrome",
              ip: "192.168.1.15",
              time: "Actuel",
              isCurrent: true,
            ),
            _buildSessionCard(
              device: "iPhone 13 - Safari",
              ip: "41.202.10.150",
              time: "Il y a 2 heures",
            ),
            _buildSessionCard(
              device: "Android - Application Locale",
              ip: "10.0.2.16",
              time: "Hier",
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: BorderSide(color: Colors.red.withOpacity(0.5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {
                  Get.dialog(
                    AlertDialog(
                      title: const Text("Déconnexion de toutes les sessions"),
                      content: const Text(
                        "Êtes-vous sûr de vouloir déconnecter tous les autres appareils actifs ?",
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Get.back(),
                          child: const Text("Annuler"),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          onPressed: () {
                            AppUtils.showSuccessToast(
                              "Toutes les autres sessions ont été terminées.",
                            );
                            Get.back();
                          },
                          child: const Text(
                            "Confirmer",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.phonelink_erase_rounded),
                label: const Text(
                  "Déconnecter les autres appareils",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.grey300.withOpacity(0.5)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.backgroundGrey,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 16,
          color: Colors.grey,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSessionCard({
    required String device,
    required String ip,
    required String time,
    bool isCurrent = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Icon(
          device.contains("iPhone") || device.contains("Android")
              ? Icons.phone_iphone_rounded
              : Icons.computer_rounded,
          color: isCurrent ? Colors.green : Colors.grey,
          size: 32,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                device,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
            if (isCurrent)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  "Actuel",
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Text(
          "IP: $ip • $time",
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        trailing:
            isCurrent
                ? null
                : IconButton(
                  icon: const Icon(
                    Icons.exit_to_app_rounded,
                    color: Colors.red,
                  ),
                  onPressed: () {
                    Get.snackbar(
                      "Session",
                      "Session déconnectée avec succès.",
                      backgroundColor: Colors.green,
                      colorText: Colors.white,
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  },
                ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_modal.dart';
import '../../services/auth_service.dart';
import '../../core/widgets/watermark_background.dart';

class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  final _emailController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _requestPasswordReset() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      AppModal.showError(
        context: context,
        title: "Erreur",
        message: "Veuillez entrer votre adresse email.",
      );
      return;
    }

    if (!GetUtils.isEmail(email)) {
      AppModal.showError(
        context: context,
        title: "Erreur",
        message: "Veuillez entrer une adresse email valide.",
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final success = await _authService.forgotPassword(email);

    setState(() {
      _isLoading = false;
    });

    if (success) {
      AppModal.showSuccess(
        context: context,
        title: "Email envoyé",
        message:
            "Un email de réinitialisation a été envoyé à $email. "
            "Veuillez vérifier votre boîte de réception.",
      );
      // Attendre un peu avant de fermer
      await Future.delayed(const Duration(milliseconds: 500));
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: AppColors.cardBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Get.back(),
        ),
      ),
      body: WatermarkBackground(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 24 : 40,
              vertical: 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                // Icône
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lock_reset_rounded,
                      size: 64,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Titre
                Text(
                  "Mot de passe oublié ?",
                  style: TextStyle(
                    fontSize: isMobile ? 28 : 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                // Description
                Text(
                  "Entrez votre adresse email et nous vous enverrons un lien pour réinitialiser votre mot de passe.",
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 16,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                // Carte de formulaire
                Container(
                  padding: EdgeInsets.all(isMobile ? 24 : 32),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.textPrimary.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Champ email
                      _buildTextField(
                        controller: _emailController,
                        label: "Adresse email",
                        hint: "votre@email.com",
                        icon: Icons.alternate_email_rounded,
                        keyboardType: TextInputType.emailAddress,
                        isMobile: isMobile,
                      ),
                      const SizedBox(height: 32),
                      // Bouton envoyer
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _requestPasswordReset,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.cardBackground,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      "Envoyer le lien",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.send_rounded, size: 20),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Lien retour connexion
                      Center(
                        child: TextButton(
                          onPressed: () => Get.back(),
                          child: Text(
                            "Retour à la connexion",
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    required bool isMobile,
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
            border: Border.all(
              color: AppColors.border,
              width: 1.2,
            ),
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
}

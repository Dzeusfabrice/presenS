import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/auth_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_utils.dart';
import '../../core/widgets/watermark_background.dart';
import '../../models/user_model.dart';

class LoginView extends StatefulWidget {
  const LoginView({Key? key}) : super(key: key);

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> with TickerProviderStateMixin {
  final AuthController _authController = Get.find<AuthController>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  late AnimationController _mainController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.2, 1.0, curve: Curves.fastLinearToSlowEaseIn),
      ),
    );

    _mainController.forward();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (!GetUtils.isEmail(email)) {
      AppUtils.showWarningToast("Adresse email invalide.");
      return;
    }
    if (password.length < 6) {
      AppUtils.showWarningToast("Mot de passe trop court.");
      return;
    }

    final success = await _authController.login(email, password);

    if (success) {
      AppUtils.showSuccessToast("Connexion réussie");
      final role = _authController.user.value?.role;

      if (role == UserRole.ETUDIANT) {
        Get.offAllNamed('/student/dashboard');
      } else if (role == UserRole.ENSEIGNANT) {
        Get.offAllNamed('/teacher/dashboard');
      } else if (role == UserRole.ADMIN) {
        Get.offAllNamed('/admin/dashboard');
      }
    } else {
      AppUtils.showErrorToast("Identifiants incorrects.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.height < 700;
    final isTablet = size.width > 600;
    final isMobile = size.width < 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: WatermarkBackground(
        child: Stack(
          children: [
            // ── Background Décoratif ─────────────────────────────────────────
            Positioned(
              top: -size.height * 0.1,
              right: -size.width * 0.2,
              child: Container(
                height: size.height * 0.45,
                width: size.height * 0.45,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(0.04),
                ),
              ),
            ),
            Positioned(
              bottom: -size.height * 0.15,
              left: -size.width * 0.15,
              child: Container(
                height: size.height * 0.35,
                width: size.height * 0.35,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryLight.withOpacity(0.03),
                ),
              ),
            ),

            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // ── Header avec Image ─────────────────────────────────────────
                  Stack(
                    children: [
                      Container(
                        height:
                            isSmallScreen
                                ? size.height * 0.30
                                : isTablet
                                ? size.height * 0.35
                                : size.height * 0.38,
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage('assets/images/inscrptions.jpg'),
                            fit: BoxFit.cover,
                            alignment: Alignment.center,
                          ),
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(50),
                            bottomRight: Radius.circular(50),
                          ),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              AppColors.textPrimary.withOpacity(0.75),
                            ],
                            ),
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(50),
                              bottomRight: Radius.circular(50),
                            ),
                          ),
                        ),
                      ),
                      SafeArea(
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: _buildHeroSection(isSmallScreen, isMobile),
                        ),
                      ),
                    ],
                  ),

                  // ── Login Content ────────────────────────────────────────────────
                  Padding(
                    padding: EdgeInsets.only(
                      top: isSmallScreen ? 20 : 30,
                      left: isTablet ? 60 : (isMobile ? 20 : 24),
                      right: isTablet ? 60 : (isMobile ? 20 : 24),
                    ),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: _buildLoginCard(isTablet, isMobile),
                      ),
                    ),
                  ),

                  SizedBox(height: isSmallScreen ? 20 : 24),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildFooter(context, isMobile),
                  ),
                  SizedBox(height: isSmallScreen ? 24 : 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection(bool isSmallScreen, bool isMobile) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 24 : 30,
        isSmallScreen ? 28 : 36,
        isMobile ? 24 : 30,
        isSmallScreen ? 20 : 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: isSmallScreen ? 28 : 142),
          Center(
            child: Text(
              "Bienvenue,",
              style: TextStyle(
                fontFamily: 'NeuraDisplay',
                fontSize:
                    isMobile
                        ? (isSmallScreen ? 32 : 36)
                        : (isSmallScreen ? 36 : 42),
                fontWeight: FontWeight.w800,
                color: AppColors.cardBackground,
                height: 1.0,
                letterSpacing: -1,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              "Sur PresenS",
              style: TextStyle(
                fontSize:
                    isMobile
                        ? (isSmallScreen ? 14 : 16)
                        : (isSmallScreen ? 16 : 18),
                fontWeight: FontWeight.w500,
                color: AppColors.cardBackground.withOpacity(0.9),
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginCard(bool isTablet, bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 28,
        vertical: isMobile ? 24 : 32,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withOpacity(0.08),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Identifiez-vous",
            style: TextStyle(
              fontFamily: 'NeuraDisplay',
              fontSize: isTablet ? 30 : (isMobile ? 24 : 26),
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          // SizedBox(height: isMobile ? 4 : 6),
          // Text(
          //   "Veuillez entrer vos informations de connexion pour continuer.",
          //   style: GoogleFonts.outfit(
          //     fontSize: isTablet ? 15 : (isMobile ? 13 : 14),
          //     color: AppColors.textSecondary,
          //     height: 1.5,
          //   ),
          // ),
          SizedBox(height: isMobile ? 24 : 28),

          _AppTextField(
            controller: _emailController,
            label: "Email",
            hint: "votre@email.com",
            icon: Icons.alternate_email_rounded,
            keyboardType: TextInputType.emailAddress,
            isMobile: isMobile,
          ),
          SizedBox(height: isMobile ? 16 : 18),

          _AppTextField(
            controller: _passwordController,
            label: "Mot de passe",
            hint: "••••••••",
            icon: Icons.lock_outline_rounded,
            obscureText: _obscurePassword,
            isMobile: isMobile,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.textSecondary.withOpacity(0.6),
                size: isMobile ? 18 : 20,
              ),
              onPressed:
                  () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),

          SizedBox(height: isMobile ? 8 : 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Get.toNamed('/forgot-password'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                "Mot de passe oublié ?",
                style: TextStyle(
                  fontSize: isTablet ? 14 : (isMobile ? 12 : 13),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          SizedBox(height: isMobile ? 24 : 28),

          Obx(() => _buildSubmitButton(isMobile)),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(bool isMobile) {
    final isLoading = _authController.isLoading.value;

    return GestureDetector(
      onTap: isLoading ? null : _login,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: isMobile ? 56 : 62,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors:
                isLoading
                    ? [
                      AppColors.primary.withOpacity(0.6),
                      AppColors.primary.withOpacity(0.4),
                    ]
                    : AppColors.mainGradient,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            if (!isLoading)
              BoxShadow(
                color: AppColors.primary.withOpacity(0.35),
                blurRadius: 20,
                offset: const Offset(0, 10),
                spreadRadius: -2,
              ),
          ],
        ),
        child: Center(
          child:
              isLoading
                  ? SizedBox(
                    height: isMobile ? 22 : 24,
                    width: isMobile ? 22 : 24,
                    child: CircularProgressIndicator(
                      color: AppColors.cardBackground,
                      strokeWidth: 2.5,
                    ),
                  )
                  : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Se connecter",
                        style: TextStyle(
                          color: AppColors.cardBackground,
                          fontSize: isMobile ? 16 : 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(width: isMobile ? 10 : 12),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: AppColors.cardBackground,
                        size: isMobile ? 18 : 20,
                      ),
                    ],
                  ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context, bool isMobile) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 1,
              width: isMobile ? 40 : 50,
              color: AppColors.grey300,
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16),
              child: Text(
                "OU",
                style: TextStyle(
                  color: AppColors.grey500,
                  fontSize: isMobile ? 11 : 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              height: 1,
              width: isMobile ? 40 : 50,
              color: AppColors.grey300,
            ),
          ],
        ),
        SizedBox(height: isMobile ? 20 : 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Nouveau sur la plateforme ? ",
              style: GoogleFonts.outfit(
                color: AppColors.textSecondary,
                fontSize: isMobile ? 14 : 15,
              ),
            ),
            GestureDetector(
              onTap: () => Get.toNamed('/register'),
              child: Text(
                "Inscrivez-vous",
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: isMobile ? 14 : 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType keyboardType;
  final Widget? suffixIcon;
  final bool isMobile;

  const _AppTextField({
    Key? key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.suffixIcon,
    this.isMobile = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4, bottom: isMobile ? 6 : 8),
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: isMobile ? 13 : 14,
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
              color: AppColors.grey300.withOpacity(0.8),
              width: 1.2,
            ),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            style: GoogleFonts.outfit(
              fontSize: isMobile ? 14 : 15,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.outfit(
                color: AppColors.textSecondary.withOpacity(0.5),
                fontSize: isMobile ? 14 : 15,
              ),
              prefixIcon: Icon(
                icon,
                color: AppColors.primary.withOpacity(0.7),
                size: isMobile ? 18 : 20,
              ),
              suffixIcon: suffixIcon,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                vertical: isMobile ? 16 : 18,
                horizontal: isMobile ? 18 : 20,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

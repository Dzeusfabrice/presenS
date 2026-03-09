import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/auth_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_utils.dart';
import '../../core/widgets/watermark_background.dart';
import '../../models/class_model.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({Key? key}) : super(key: key);

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView>
    with TickerProviderStateMixin {
  final AuthController _authController = Get.find<AuthController>();
  final PageController _pageController = PageController();

  int _currentStep = 0;
  final int _totalSteps = 3;

  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _matriculeController = TextEditingController();

  String? _selectedLocationId;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

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
    _authController.fetchClasses();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pageController.dispose();
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _matriculeController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      if (_validateCurrentStep()) {
        setState(() => _currentStep++);
        _pageController.nextPage(
          duration: const Duration(milliseconds: 500),
          curve: Curves.fastOutSlowIn,
        );
      }
    } else {
      _finishRegistration();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.fastOutSlowIn,
      );
    } else {
      Get.back();
    }
  }

  bool _validateCurrentStep() {
    if (_currentStep == 0) {
      if (_nomController.text.trim().isEmpty ||
          _prenomController.text.trim().isEmpty ||
          !GetUtils.isEmail(_emailController.text.trim())) {
        AppUtils.showWarningToast(
          "Veuillez remplir correctement les informations personnelles.",
        );
        return false;
      }
    } else if (_currentStep == 1) {
      if (_matriculeController.text.trim().isEmpty ||
          _selectedLocationId == null) {
        AppUtils.showWarningToast(
          "Veuillez renseigner votre matricule et choisir une classe.",
        );
        return false;
      }
    }
    return true;
  }

  Future<void> _finishRegistration() async {
    if (_passwordController.text.trim().length < 6) {
      AppUtils.showWarningToast(
        "Le mot de passe doit contenir au moins 6 caractères.",
      );
      return;
    }
    if (_passwordController.text.trim() !=
        _confirmPasswordController.text.trim()) {
      AppUtils.showWarningToast("Les mots de passe ne correspondent pas.");
      return;
    }

    final selectedClass = _authController.classes.firstWhere(
      (c) => c.id == _selectedLocationId,
      orElse: () => ClassModel(id: "", nom: "", niveau: "", parcours: ""),
    );

    // Afficher le loader modal
    Get.dialog(
      WillPopScope(
        onWillPop: () async => false,
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.textPrimary.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  strokeWidth: 3,
                ),
                const SizedBox(height: 20),
                Text(
                  "Enregistrement en cours...",
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Veuillez patienter pendant que nous créons votre compte",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );

    try {
      final success = await _authController.registerStudent(
        nom: _nomController.text.trim(),
        prenom: _prenomController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        matricule: _matriculeController.text.trim(),
        classeId: _selectedLocationId ?? "",
        niveau: selectedClass.niveau,
        parcours: selectedClass.parcours,
      );

      // Fermer le loader
      Get.back();

      if (success) {
        AppUtils.showSuccessToast("Compte créé avec succès !");
        await Future.delayed(const Duration(milliseconds: 1500));
        Get.offAllNamed('/login');
      } else {
        AppUtils.showErrorToast(
          "Erreur lors de l'enregistrement. Veuillez réessayer.",
        );
      }
    } catch (e) {
      // Fermer le loader en cas d'erreur
      Get.back();
      AppUtils.handleError(e);
    }
  }

  String _getStepSubtitle() {
    switch (_currentStep) {
      case 0:
        return "Commençons par faire connaissance";
      case 1:
        return "Parlez-nous de votre parcours";
      case 2:
        return "Dernière étape : la sécurité";
      default:
        return "";
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
            // Background Décoratif
            Positioned(
              bottom: -size.height * 0.1,
              left: -size.width * 0.2,
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
              top: -size.height * 0.08,
              right: -size.width * 0.15,
              child: Container(
                height: size.height * 0.3,
                width: size.height * 0.3,
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
                  Stack(
                    children: [
                      Container(
                        height:
                            isSmallScreen
                                ? size.height * 0.30
                                : isTablet
                                ? size.height * 0.34
                                : size.height * 0.36,
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage('assets/images/inscription.jpg'),
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
                                AppColors.textPrimary.withOpacity(0.8),
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
                          child: _buildHeroSection(isMobile, isSmallScreen),
                        ),
                      ),
                    ],
                  ),

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
                        child: _buildFormCard(isTablet, isMobile),
                      ),
                    ),
                  ),

                  SizedBox(height: isSmallScreen ? 20 : 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection(bool isMobile, bool isSmallScreen) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 20 : 24,
        isSmallScreen ? 18 : 20,
        isMobile ? 20 : 24,
        isSmallScreen ? 20 : 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: _previousStep,
            child: Container(
              padding: EdgeInsets.all(isMobile ? 10 : 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: isMobile ? 18 : 20,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: isSmallScreen ? 20 : 94),
          Center(
            child: Text(
              "Créer un compte",
              style: TextStyle(
                fontFamily: 'NeuraDisplay',
                fontSize:
                    isMobile
                        ? (isSmallScreen ? 30 : 32)
                        : (isSmallScreen ? 34 : 36),
                fontWeight: FontWeight.w800,
                color: AppColors.cardBackground,
                height: 1.1,
                letterSpacing: -1,
              ),
            ),
          ),
          SizedBox(height: isMobile ? 6 : 8),
          Center(
            child: Text(
              _getStepSubtitle(),
              style: GoogleFonts.outfit(
                fontSize: isMobile ? 14 : 16,
                color: AppColors.cardBackground.withOpacity(0.9),
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(bool isTablet, bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 22 : 28,
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
          _buildProgressIndicator(isMobile),
          SizedBox(height: isMobile ? 20 : 24),

          SizedBox(
            height: _stepHeight(isMobile),
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [_step1(isMobile), _step2(isMobile), _step3(isMobile)],
            ),
          ),

          SizedBox(height: isMobile ? 20 : 24),
          _buildActionButton(isMobile),
          SizedBox(height: isMobile ? 16 : 20),
          _buildFooter(isMobile),
        ],
      ),
    );
  }

  double _stepHeight(bool isMobile) {
    switch (_currentStep) {
      case 0:
        return isMobile ? 290 : 310;
      case 1:
        return isMobile ? 190 : 210;
      case 2:
        return isMobile ? 260 : 280;
      default:
        return isMobile ? 260 : 280;
    }
  }

  Widget _buildProgressIndicator(bool isMobile) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final externalPadding = isTablet ? 120.0 : (isMobile ? 40.0 : 48.0);
    final internalPadding = isMobile ? 44.0 : 56.0;
    final totalPadding = externalPadding + internalPadding;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Étape ${_currentStep + 1} / $_totalSteps",
              style: GoogleFonts.outfit(
                fontSize: isMobile ? 13 : 14,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            Text(
              "${((_currentStep + 1) / _totalSteps * 100).toInt()}%",
              style: GoogleFonts.outfit(
                fontSize: isMobile ? 13 : 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        SizedBox(height: isMobile ? 10 : 12),
        Stack(
          children: [
            Container(
              height: isMobile ? 5 : 6,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              height: isMobile ? 5 : 6,
              width:
                  (screenWidth - totalPadding) *
                  ((_currentStep + 1) / _totalSteps),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: AppColors.mainGradient),
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
    );
  }

  Widget _step1(bool isMobile) {
    return Column(
      children: [
        _AppTextField(
          controller: _nomController,
          label: "Nom",
          hint: "Votre nom de famille",
          icon: Icons.person_outline_rounded,
          isMobile: isMobile,
        ),
        SizedBox(height: isMobile ? 14 : 16),
        _AppTextField(
          controller: _prenomController,
          label: "Prénom",
          hint: "Votre prénom",
          icon: Icons.person_outline_rounded,
          isMobile: isMobile,
        ),
        SizedBox(height: isMobile ? 14 : 16),
        _AppTextField(
          controller: _emailController,
          label: "Email",
          hint: "votre@email.com",
          icon: Icons.alternate_email_rounded,
          keyboardType: TextInputType.emailAddress,
          isMobile: isMobile,
        ),
      ],
    );
  }

  Widget _step2(bool isMobile) {
    return Column(
      children: [
        _AppTextField(
          controller: _matriculeController,
          label: "Matricule",
          hint: "Votre numéro matricule",
          icon: Icons.badge_outlined,
          isMobile: isMobile,
        ),
        SizedBox(height: isMobile ? 14 : 16),
        _buildGlassDropdown(isMobile),
      ],
    );
  }

  Widget _buildGlassDropdown(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4, bottom: isMobile ? 6 : 8),
          child: Text(
            "Classe",
            style: GoogleFonts.outfit(
              fontSize: isMobile ? 13 : 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary.withOpacity(0.85),
            ),
          ),
        ),
        Obx(() {
          final classes = _authController.classes;
          final isLoading = _authController.isLoading.value;

          if (isLoading) {
            return Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 14 : 16,
                vertical: isMobile ? 16 : 18,
              ),
              decoration: BoxDecoration(
                color: AppColors.backgroundGrey.withOpacity(0.6),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: isMobile ? 18 : 20,
                    height: isMobile ? 18 : 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  ),
                  SizedBox(width: isMobile ? 10 : 12),
                  Expanded(
                    child: Text(
                      "Chargement des classes...",
                      style: GoogleFonts.outfit(
                        color: AppColors.textSecondary,
                        fontSize: isMobile ? 13 : 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          if (classes.isEmpty && !isLoading) {
            return Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 14 : 16,
                vertical: isMobile ? 16 : 18,
              ),
              decoration: BoxDecoration(
                color: AppColors.backgroundGrey.withOpacity(0.6),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.warning.withOpacity(0.3),
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.warning,
                    size: isMobile ? 18 : 20,
                  ),
                  SizedBox(width: isMobile ? 8 : 10),
                  Expanded(
                    child: Text(
                      "Aucune classe disponible. Veuillez réessayer plus tard.",
                      style: GoogleFonts.outfit(
                        color: AppColors.textSecondary,
                        fontSize: isMobile ? 13 : 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return Container(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 14 : 16),
            decoration: BoxDecoration(
              color: AppColors.backgroundGrey.withOpacity(0.6),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.grey300.withOpacity(0.8),
                width: 1.2,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedLocationId,
                isExpanded: true,
                hint: Text(
                  classes.isEmpty
                      ? "Chargement des classes..."
                      : "Sélectionner votre classe",
                  style: GoogleFonts.outfit(
                    color: AppColors.textSecondary.withOpacity(0.5),
                    fontSize: isMobile ? 14 : 15,
                  ),
                ),
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.primary,
                  size: isMobile ? 20 : 22,
                ),
                dropdownColor: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(18),
                items:
                    classes.isEmpty
                        ? null
                        : classes.map((cls) {
                          return DropdownMenuItem<String>(
                            value: cls.id,
                            child: Text(
                              cls.nom.isNotEmpty ? cls.nom : "Classe ${cls.id}",
                              style: GoogleFonts.outfit(
                                color: AppColors.textPrimary,
                                fontSize: isMobile ? 14 : 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                onChanged:
                    classes.isEmpty
                        ? null
                        : (val) => setState(() => _selectedLocationId = val),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _step3(bool isMobile) {
    return Column(
      children: [
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
        SizedBox(height: isMobile ? 14 : 16),
        _AppTextField(
          controller: _confirmPasswordController,
          label: "Confirmation",
          hint: "Confirmer le mot de passe",
          icon: Icons.lock_outline_rounded,
          obscureText: _obscureConfirm,
          isMobile: isMobile,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirm
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: AppColors.textSecondary.withOpacity(0.6),
              size: isMobile ? 18 : 20,
            ),
            onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(bool isMobile) {
    return Obx(() {
      final isLoading = _authController.isLoading.value;
      return GestureDetector(
        onTap: isLoading ? null : _nextStep,
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
                          _currentStep == _totalSteps - 1
                              ? "Finaliser"
                              : "Suivant",
                          style: TextStyle(
                            color: AppColors.cardBackground,
                            fontSize: isMobile ? 16 : 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(width: isMobile ? 10 : 12),
                        Icon(
                          _currentStep == _totalSteps - 1
                              ? Icons.check_circle_rounded
                              : Icons.arrow_forward_rounded,
                          color: AppColors.cardBackground,
                          size: isMobile ? 18 : 20,
                        ),
                      ],
                    ),
          ),
        ),
      );
    });
  }

  Widget _buildFooter(bool isMobile) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Déjà un compte ? ",
            style: GoogleFonts.outfit(
              color: AppColors.textSecondary,
              fontSize: isMobile ? 13 : 14,
            ),
          ),
          GestureDetector(
            onTap: () => Get.back(),
            child: Text(
              "Se connecter",
              style: TextStyle(
                color: AppColors.primary,
                fontSize: isMobile ? 13 : 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
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

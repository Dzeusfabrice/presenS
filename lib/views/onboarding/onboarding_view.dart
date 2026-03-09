import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({Key? key}) : super(key: key);

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _slides = [
    {
      'title': AppStrings.onboardingTitle1,
      'description': AppStrings.onboardingDesc1,
      'image': 'assets/images/student.jpg',
      'icon': Icons.qr_code_scanner_rounded,
    },
    {
      'title': AppStrings.onboardingTitle2,
      'description': AppStrings.onboardingDesc2,
      'image': 'assets/images/Students.jpg',
      'icon': Icons.bar_chart_rounded,
    },
    {
      'title': AppStrings.onboardingTitle3,
      'description': AppStrings.onboardingDesc3,
      'image': 'assets/images/teacher.jpg',
      'icon': Icons.notifications_active_rounded,
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _onDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    Get.offAllNamed('/login');
  }

  Future<void> _onSkip() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    Get.offAllNamed('/login');
  }

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _onDone();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // PageView (occupies entire screen)
          Positioned.fill(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemCount: _slides.length,
              itemBuilder: (context, index) {
                return _buildSlide(_slides[index]);
              },
            ),
          ),

          // Skip button
          if (_currentPage != _slides.length - 1)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: GestureDetector(
                onTap: _onSkip,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    AppStrings.skip,
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

          // Indicators and buttons
          Positioned(
            left: 32,
            right: 32,
            bottom: MediaQuery.of(context).padding.bottom + 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Page indicators
                SmoothPageIndicator(
                  controller: _pageController,
                  count: _slides.length,
                  effect: ExpandingDotsEffect(
                    activeDotColor: AppColors.primary,
                    dotColor: AppColors.primary.withOpacity(0.3),
                    dotHeight: 10,
                    dotWidth: 10,
                    expansionFactor: 3,
                    spacing: 8,
                  ),
                ),

                const SizedBox(height: 32),

                // Action button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _currentPage == _slides.length - 1
                              ? AppStrings.start
                              : AppStrings.next,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          _currentPage == _slides.length - 1
                              ? Icons.check_rounded
                              : Icons.arrow_forward_rounded,
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlide(Map<String, dynamic> slide) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(color: AppColors.background),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image de fond professionnelle
          Positioned.fill(
            child: Image.asset(
              slide['image'] as String,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary.withOpacity(0.1),
                        AppColors.primaryLight.withOpacity(0.05),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Overlay gradient professionnel pour améliorer la lisibilité
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primary.withOpacity(0.1),
                    AppColors.primary.withOpacity(0.1),
                    AppColors.background.withOpacity(0.8),
                    AppColors.background.withOpacity(0.9),
                    AppColors.background,
                  ],
                  stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
                ),
              ),
            ),
          ),
          // Contenu du slide centré et professionnel
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 1),
                // Icône avec effet glassmorphism
                // Container(
                //   width: 120,
                //   height: 120,
                //   decoration: BoxDecoration(
                //     color: AppColors.cardBackground.withOpacity(0.2),
                //     shape: BoxShape.circle,
                //     border: Border.all(
                //       color: AppColors.primary.withOpacity(0.4),
                //       width: 3,
                //     ),
                //     boxShadow: [
                //       BoxShadow(
                //         color: AppColors.primary.withOpacity(0.3),
                //         blurRadius: 20,
                //         spreadRadius: 2,
                //       ),
                //     ],
                //   ),
                //   child: Icon(
                //     slide['icon'] as IconData,
                //     size: 56,
                //     color: AppColors.primary,
                //   ),
                // ),
                const SizedBox(height: 186),
                // Titre avec style professionnel
                Text(
                  slide['title'] as String,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.8,
                    shadows: [
                      Shadow(
                        color: AppColors.textPrimary.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                // Description avec style professionnel
                Text(
                  slide['description'] as String,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    color: AppColors.textSecondary,
                    height: 1.6,
                    letterSpacing: 0.3,
                  ),
                ),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

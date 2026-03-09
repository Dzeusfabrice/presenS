import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/startup_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/circular_progress_clock.dart';

class SplashView extends StatelessWidget {
  const SplashView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(StartupController());

    return Scaffold(
      body: Stack(
        children: [
          /// ================= BACKGROUND IMAGE =================
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/etudiantglasmorph.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          /// ================= PRIMARY BLUE OVERLAY =================
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  // AppColors.primary.withOpacity(0.75),
                  // AppColors.background.withOpacity(0.92),
                  AppColors.primary.withValues(alpha: 0.2),
                  AppColors.primary.withValues(alpha: 0.95),
                ],
              ),
            ),
          ),

          /// ================= CONTENT =================
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),

                  /// APP NAME
                  const Text(
                    "PRESENS",
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 8,
                    ),
                  ),

                  Text(
                    "Système de gestion des présences",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.75),
                      letterSpacing: 2,
                    ),
                  ),

                  const SizedBox(height: 60),

                  /// CIRCULAR PROGRESS CLOCK
                  _buildLoadingState(controller),

                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }


  /// =========================================================
  /// LOADING STATE WITH CIRCULAR PROGRESS CLOCK
  /// =========================================================
  Widget _buildLoadingState(StartupController controller) {
    return Obx(() {
      if (controller.hasError.value) {
        return _buildErrorState(controller);
      }
      
      return Column(
        children: [
          // Horloge de progression circulaire
          AnimatedContainer(
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            child: CircularProgressClock(
              progress: controller.progress.value,
              size: 180,
              centerText: "${(controller.progress.value * 100).toInt()}%",
              minLabel: "0%",
              maxLabel: "100%",
            ),
          ),

          const SizedBox(height: 30),

          // Statut de chargement
          Text(
            controller.loadingStatus.value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    });
  }

  /// =========================================================
  /// ERROR STATE
  /// =========================================================
  Widget _buildErrorState(StartupController controller) {
    return Column(
      children: [
        const Icon(
          Icons.cloud_off_rounded,
          color: Colors.orangeAccent,
          size: 40,
        ),

        const SizedBox(height: 12),

        Text(
          controller.errorMessage.value,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),

        const SizedBox(height: 20),

        ElevatedButton(
          onPressed: controller.retry,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryLight,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text("Réessayer"),
        ),
      ],
    );
  }
}

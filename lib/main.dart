import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'views/auth/login_view.dart';
import 'views/auth/register_view.dart';
import 'views/auth/forgot_password_view.dart';
import 'views/onboarding/onboarding_view.dart';
import 'views/splash/splash_view.dart';
import 'views/student/student_dashboard.dart';
import 'views/teacher/teacher_dashboard.dart';
import 'views/admin/admin_dashboard.dart';
import 'views/student/mark_attendance_view.dart';
import 'views/teacher/create_session_view.dart';
import 'views/teacher/manual_attendance_view.dart';
import 'views/teacher/session_recap_view.dart';
import 'views/profile/profile_view.dart';
import 'controllers/auth_controller.dart';
import 'controllers/session_controller.dart';
import 'controllers/attendance_controller.dart';
import 'core/theme/app_colors.dart';
import 'core/constants/app_strings.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'controllers/theme_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr', null);

  // Charger la préférence de thème sauvegardée
  // final prefs = await SharedPreferences.getInstance();

  Get.put(ThemeController());
  Get.put(AuthController());
  Get.put(SessionController());
  Get.put(AttendanceController());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    return Obx(
      () => GetMaterialApp(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        themeMode:
            themeController.isDarkMode ? ThemeMode.dark : ThemeMode.light,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            primary: AppColors.primary,
            onPrimary: Colors.white,
            secondary: AppColors.primaryLight,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          fontFamily: 'Agumony',
          scaffoldBackgroundColor: AppColors.backgroundGrey,
          appBarTheme: AppBarTheme(
            backgroundColor: AppColors.cardBackground,
            foregroundColor: AppColors.textPrimary,
            elevation: 0,
          ),
          cardColor: AppColors.cardBackground,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            primary: AppColors.primary,
            onPrimary: Colors.white,
            secondary: AppColors.primaryLight,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          fontFamily: 'Agumony',
          scaffoldBackgroundColor: const Color(0xFF111827),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1F2937),
            foregroundColor: Color(0xFFF9FAFB),
            elevation: 0,
          ),
          cardColor: const Color(0xFF1F2937),
        ),
        initialRoute: '/',
        getPages: [
          GetPage(name: '/', page: () => const SplashView()),
          GetPage(name: '/onboarding', page: () => const OnboardingView()),
          GetPage(name: '/login', page: () => const LoginView()),
          GetPage(name: '/register', page: () => const RegisterView()),
          GetPage(
            name: '/forgot-password',
            page: () => const ForgotPasswordView(),
          ),

          // Modules Routes
          GetPage(
            name: '/student/dashboard',
            page: () => const StudentDashboard(),
          ),
          GetPage(
            name: '/student/mark-attendance',
            page: () => const MarkAttendanceView(),
          ),
          GetPage(
            name: '/teacher/dashboard',
            page: () => const TeacherDashboard(),
          ),
          GetPage(
            name: '/teacher/create-session',
            page: () => const CreateSessionView(),
          ),
          GetPage(
            name: '/teacher/manual-attendance',
            page: () {
              final args = Get.arguments as Map<String, dynamic>?;
              return ManualAttendanceView(
                sessionId: args?['sessionId'] ?? '',
                additionalLocationIds:
                    args?['additionalLocationIds'] as List<String>?,
              );
            },
          ),
          GetPage(
            name: '/session-recap',
            page: () {
              final args = Get.arguments as Map<String, dynamic>?;
              return SessionRecapView(sessionId: args?['sessionId'] ?? '');
            },
          ),
          GetPage(name: '/admin/dashboard', page: () => const AdminDashboard()),
          GetPage(name: '/profile', page: () => const ProfileView()),
        ],
      ),
    );
  }
}

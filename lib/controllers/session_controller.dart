import 'package:get/get.dart';
import '../models/session_model.dart';
import '../services/auth_service.dart';
import 'auth_controller.dart';

class SessionController extends GetxController {
  final AuthService _authService = AuthService();
  final AuthController _authController = Get.find<AuthController>();

  var isLoading = false.obs;
  var sessions = <SessionModel>[].obs;
  var activeSessions = <SessionModel>[].obs;

  // Real stats
  var totalSessionsCount = 0.obs;
  var totalStudentsContained = 0.obs;
  var avgAttendanceRate = 0.0.obs;

  // Filtrage
  var selectedFilter = "Tous".obs;
  var filteredSessions = <SessionModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    // Écouter les changements pour appliquer le filtre automatiquement
    ever(sessions, (_) => applyFilter());
    ever(selectedFilter, (_) => applyFilter());

    // Charger les données
    fetchSessions();
  }

  void setFilter(String filter) {
    selectedFilter.value = filter;
  }

  void applyFilter() {
    // On travaille sur une copie de la liste originale pour ne pas la polluer
    List<SessionModel> list = List<SessionModel>.from(sessions);

    // Filtrage par statut
    if (selectedFilter.value == "En cours") {
      list = list.where((s) => s.statut == SessionStatus.EN_COURS).toList();
    } else if (selectedFilter.value == "Terminés") {
      list = list.where((s) => s.statut == SessionStatus.CLOS).toList();
    }

    // Tri (toujours trié, mais change selon le critère)
    if (selectedFilter.value == "Anciens") {
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    } else {
      // Par défaut ou "Récents" ou filtres de statut : Plus récent d'abord
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    filteredSessions.assignAll(list);
    filteredSessions.refresh(); // Force la notification
  }

  int getFilterCount(String filter) {
    if (filter == "Tous" || filter == "Récents" || filter == "Anciens") {
      return sessions.length;
    }
    if (filter == "En cours") {
      return sessions.where((s) => s.statut == SessionStatus.EN_COURS).length;
    }
    if (filter == "Terminés") {
      return sessions.where((s) => s.statut == SessionStatus.CLOS).length;
    }
    return 0;
  }

  Future<void> fetchSessions() async {
    isLoading.value = true;
    try {
      final list = await _authService.getSessions();
      sessions.assignAll(list);

      // Appliquer immédiatement le filtre pour la vue initiale
      applyFilter();
      activeSessions.assignAll(
        list.where((s) => s.statut == SessionStatus.EN_COURS),
      );

      // Update real stats
      totalSessionsCount.value = list.length;

      // We'll calculate unique students from sessions if possible
      // This is an estimation: we'll show sum of students expected in these classes
      final classIds =
          list.expand((s) {
            try {
              return s.classeIds;
            } catch (_) {
              return <String>[];
            }
          }).toSet();
      // For now we set it to sessions.length * 30 as a "fallback" but
      // ideally we should fetch from UserManagementController
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> createSession({
    String? matiereId,
    required String matiere,
    required String lieuId,
    required List<String> classeIds,
    required SessionMode mode,
    required DateTime heureDebut,
    required DateTime heureFin,
    required int margeTolerance,
  }) async {
    isLoading.value = true;
    try {
      final newSession = SessionModel(
        id: "sess-${DateTime.now().millisecondsSinceEpoch}",
        matiereId: matiereId,
        matiere: matiere,
        enseignantId: _authController.user.value?.id ?? "unknown",
        lieuId: lieuId,
        classeIds: classeIds,
        mode: mode,
        statut: SessionStatus.ATTENTE,
        createdAt: DateTime.now(),
        heureDebut: heureDebut,
        heureFin: heureFin,
        margeTolerance: margeTolerance,
        // Le QR Code est maintenant lié au lieu, pas à la séance
        qrCode: null,
      );

      final success = await _authService.createSession(newSession);
      if (success) {
        await fetchSessions();
        return true;
      }
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> startSession(String sessionId) async {
    isLoading.value = true;
    try {
      final success = await _authService.updateSessionStatus(
        sessionId,
        SessionStatus.EN_COURS,
      );

      if (success || _authService.useMock) {
        final index = sessions.indexWhere((s) => s.id == sessionId);
        if (index != -1) {
          final session = sessions[index];
          final updatedSession = SessionModel(
            id: session.id,
            matiere: session.matiere,
            enseignantId: session.enseignantId,
            lieuId: session.lieuId,
            classeIds: session.classeIds,
            mode: session.mode,
            statut: SessionStatus.EN_COURS,
            createdAt: session.createdAt,
            heureDebut: session.heureDebut,
            heureFin: session.heureFin,
            margeTolerance: session.margeTolerance,
            qrCode: session.qrCode,
          );

          sessions[index] = updatedSession;

          final activeIndex = activeSessions.indexWhere(
            (s) => s.id == sessionId,
          );
          if (activeIndex != -1) {
            activeSessions[activeIndex] = updatedSession;
          } else {
            activeSessions.add(updatedSession);
          }

          sessions.refresh();
          activeSessions.refresh();
          return true;
        }
      }
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> endSession(String sessionId) async {
    isLoading.value = true;
    try {
      final success = await _authService.updateSessionStatus(
        sessionId,
        SessionStatus.CLOS,
      );

      if (success || _authService.useMock) {
        final index = sessions.indexWhere((s) => s.id == sessionId);
        if (index != -1) {
          final session = sessions[index];
          final updatedSession = SessionModel(
            id: session.id,
            matiere: session.matiere,
            enseignantId: session.enseignantId,
            lieuId: session.lieuId,
            classeIds: session.classeIds,
            mode: session.mode,
            statut: SessionStatus.CLOS,
            createdAt: session.createdAt,
            heureDebut: session.heureDebut,
            heureFin: session.heureFin,
            margeTolerance: session.margeTolerance,
            qrCode: session.qrCode,
          );

          sessions[index] = updatedSession;
          activeSessions.removeWhere((s) => s.id == sessionId);

          sessions.refresh();
          activeSessions.refresh();
          return true;
        }
      }
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}

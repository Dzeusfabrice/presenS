import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/attendance_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../models/user_model.dart';
import '../../models/attendance_model.dart';
import '../../models/class_model.dart';
import 'package:geolocator/geolocator.dart';
import 'session_recap_view.dart';

class ClassAttendanceMonitorView extends StatefulWidget {
  final String sessionId;
  final ClassModel classModel;
  final List<UserModel> students;

  const ClassAttendanceMonitorView({
    Key? key,
    required this.sessionId,
    required this.classModel,
    required this.students,
  }) : super(key: key);

  @override
  State<ClassAttendanceMonitorView> createState() => _ClassAttendanceMonitorViewState();
}

class _ClassAttendanceMonitorViewState extends State<ClassAttendanceMonitorView> {
  final AttendanceController _attendanceController = Get.find<AttendanceController>();
  final RxMap<String, AttendanceStatus> _pendingChanges = <String, AttendanceStatus>{}.obs;
  final TextEditingController _searchController = TextEditingController();
  final RxString _searchQuery = "".obs;
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.classModel.nom,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            if (widget.classModel.parcours.isNotEmpty)
              Text(
                widget.classModel.parcours,
                style: const TextStyle(fontSize: 11, color: Colors.white70),
              ),
          ],
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Obx(() => _pendingChanges.isNotEmpty 
            ? IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => _pendingChanges.clear(),
                tooltip: "Réinitialiser les changements",
              )
            : const SizedBox.shrink()
          ),
        ],
      ),
      body: Column(
        children: [
          _buildClassStatsHeader(),
          _buildSearchBar(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildAttendanceSheet(),
            ),
          ),
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildClassStatsHeader() {
    return Obx(() {
      final attendances = _attendanceController.attendances.toList();
      
      // Calculer les stats en tenant compte des changements en attente
      int presentCount = 0;
      for (var student in widget.students) {
        final pending = _pendingChanges[student.id];
        if (pending != null) {
          if (pending == AttendanceStatus.PRESENT) presentCount++;
        } else {
          final att = attendances.firstWhereOrNull((a) => a.etudiantId == student.id);
          if (att?.statut == AttendanceStatus.PRESENT) presentCount++;
        }
      }
      
      final total = widget.students.length;

      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.primaryLight],
          ),
        ),
        child: Row(
          children: [
            _buildHeaderStat("Total", "$total", Colors.white),
            _buildHeaderStat("Présents", "$presentCount", Colors.greenAccent),
            _buildHeaderStat("Absents", "${total - presentCount}", Colors.redAccent),
          ],
        ),
      );
    });
  }

  Widget _buildHeaderStat(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => _searchQuery.value = val,
        decoration: InputDecoration(
          hintText: "Rechercher un étudiant...",
          prefixIcon: const Icon(Icons.search, size: 20),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }

  Widget _buildAttendanceSheet() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "LISTE DES ÉTUDIANTS",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2),
                ),
                Obx(() => _pendingChanges.isNotEmpty 
                  ? Text(
                      "${_pendingChanges.length} modifs",
                      style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 10),
                    )
                  : const SizedBox.shrink()
                ),
              ],
            ),
          ),
          Expanded(
            child: Obx(() {
              final attendancesList = _attendanceController.attendances.toList();
              final query = _searchQuery.value.toLowerCase();
              
              final filteredStudents = widget.students.where((s) {
                final fullName = "${s.nom} ${s.prenom}".toLowerCase();
                return fullName.contains(query) || (s.matricule?.toLowerCase().contains(query) ?? false);
              }).toList();

              return ListView.builder(
                itemCount: filteredStudents.length,
                itemBuilder: (context, index) {
                  final student = filteredStudents[index];
                  
                  // Utiliser le changement en attente s'il existe, sinon l'état réel
                  final pendingStatus = _pendingChanges[student.id];
                  final bool isPresent;
                  final bool isModified = pendingStatus != null;

                  if (isModified) {
                    isPresent = pendingStatus == AttendanceStatus.PRESENT;
                  } else {
                    final att = attendancesList.firstWhereOrNull((a) => a.etudiantId == student.id);
                    isPresent = att?.statut == AttendanceStatus.PRESENT;
                  }

                  return InkWell(
                    onTap: () {
                      final targetStatus = isPresent ? AttendanceStatus.ABSENT : AttendanceStatus.PRESENT;
                      
                      // Si on revient à l'état initial (du serveur), on enlève de _pendingChanges
                      final attOnServer = attendancesList.firstWhereOrNull((a) => a.etudiantId == student.id);
                      final serverStatus = attOnServer?.statut ?? AttendanceStatus.ABSENT;
                      
                      if (targetStatus == serverStatus) {
                        _pendingChanges.remove(student.id);
                      } else {
                        _pendingChanges[student.id] = targetStatus;
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1))),
                        color: isPresent 
                              ? Colors.green.withOpacity(0.04) 
                              : Colors.transparent,
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: (isPresent ? Colors.green : AppColors.primary).withOpacity(0.1),
                            child: Text(
                              student.nom[0].toUpperCase(),
                              style: TextStyle(color: isPresent ? Colors.green : AppColors.primary, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${student.nom.toUpperCase()} ${student.prenom}",
                                  style: TextStyle(
                                    fontWeight: isPresent ? FontWeight.bold : FontWeight.normal,
                                    color: isPresent ? AppColors.primary : AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  "${student.matricule ?? 'Sans matricule'}${isModified ? ' (Modification)' : ''}",
                                  style: TextStyle(color: isModified ? Colors.orange : AppColors.textSecondary, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            isPresent ? Icons.check_circle : Icons.circle_outlined,
                            color: isPresent ? Colors.green : Colors.grey.withOpacity(0.3),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Obx(() {
      if (_pendingChanges.isEmpty) return const SizedBox.shrink();

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveBulkAttendance,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isSaving 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text("ENREGISTRER ${_pendingChanges.length} MODIFICATIONS"),
          ),
        ),
      );
    });
  }

  Future<void> _saveBulkAttendance() async {
    setState(() => _isSaving = true);
    
    try {
      double? lat;
      double? lon;
      
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 5),
        );
        lat = position.latitude;
        lon = position.longitude;
      } catch (e) {
        print("Could not get location for bulk marking: $e");
      }

      final changes = Map<String, AttendanceStatus>.from(_pendingChanges);
      
      final success = await _attendanceController.updateBulkManualStatus(
        sessionId: widget.sessionId,
        changes: changes,
        lat: lat,
        lon: lon,
      );
      
      if (success) {
        _pendingChanges.clear();
        Get.snackbar("Succès", "L'appel a été mis à jour avec succès", 
          backgroundColor: Colors.green, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
        
        // Redirection vers le récapitulatif comme demandé
        Get.off(() => SessionRecapView(sessionId: widget.sessionId));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

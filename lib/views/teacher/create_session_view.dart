import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/session_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../models/session_model.dart';
import '../../core/utils/app_utils.dart';
import 'live_monitor_view.dart';

class CreateSessionView extends StatefulWidget {
  const CreateSessionView({Key? key}) : super(key: key);

  @override
  State<CreateSessionView> createState() => _CreateSessionViewState();
}

class _CreateSessionViewState extends State<CreateSessionView> {
  final SessionController _sessionController = Get.find<SessionController>();
  final AuthController _authController = Get.find<AuthController>();

  final _toleranceController = TextEditingController(text: "15");
  String? _selectedLieuId;
  String? _selectedMatterId;
  final List<String> _selectedClasseIds = [];
  SessionMode _selectedMode = SessionMode.GPS;

  DateTime? _heureDebut;
  DateTime? _heureFin;

  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _authController.fetchLocations();
    _authController.fetchClasses();
    _authController.fetchAcademicData(); // S'assurer que les matières sont là
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Créer une séance",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(
            context,
          ).colorScheme.copyWith(primary: AppColors.primary),
        ),
        child: Stepper(
          type: StepperType.horizontal,
          currentStep: _currentStep,
          elevation: 0,
          physics: const ClampingScrollPhysics(),
          onStepTapped: (step) {
            if (step < _currentStep) {
              setState(() => _currentStep = step);
            } else if (step > _currentStep) {
              // On ne peut pas sauter des étapes en avant sans valider l'actuelle
              if (_validateCurrentStep()) {
                setState(() => _currentStep = step);
              }
            }
          },
          onStepContinue: () {
            if (_validateCurrentStep()) {
              if (_currentStep < 2) {
                setState(() => _currentStep += 1);
              } else {
                _handleSubmit();
              }
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) {
              setState(() => _currentStep -= 1);
            }
          },
          controlsBuilder: (BuildContext context, ControlsDetails details) {
            return Padding(
              padding: const EdgeInsets.only(top: 32.0, bottom: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Obx(
                      () => ElevatedButton(
                        onPressed:
                            _sessionController.isLoading.value
                                ? null
                                : details.onStepContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child:
                            _sessionController.isLoading.value &&
                                    _currentStep == 2
                                ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                                : Text(
                                  _currentStep == 2
                                      ? "Lancer la séance"
                                      : "Suivant",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                      ),
                    ),
                  ),
                  if (_currentStep > 0) ...[
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            _sessionController.isLoading.value
                                ? null
                                : details.onStepCancel,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          side: BorderSide(color: AppColors.primary),
                        ),
                        child: Text(
                          "Retour",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
          steps: [
            Step(
              title: const Text("Infos"),
              content: _buildStep1Infos(),
              isActive: _currentStep >= 0,
              state: _currentStep > 0 ? StepState.complete : StepState.indexed,
            ),
            Step(
              title: const Text("Horaires"),
              content: _buildStep2Horaires(),
              isActive: _currentStep >= 1,
              state: _currentStep > 1 ? StepState.complete : StepState.indexed,
            ),
            Step(
              title: const Text("Validation"),
              content: _buildStep3Validation(),
              isActive: _currentStep >= 2,
              state: _currentStep == 2 ? StepState.editing : StepState.indexed,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1Infos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Informations du cours",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        _buildLabel("Matière"),
        Obx(
          () => DropdownButtonFormField<String>(
            value: _selectedMatterId,
            decoration: _inputDecoration("Sélectionner la matière"),
            items:
                _authController.matters.map((matter) {
                  return DropdownMenuItem(
                    value: matter.id,
                    child: Text(matter.nom),
                  );
                }).toList(),
            onChanged: (val) => setState(() => _selectedMatterId = val),
          ),
        ),
        const SizedBox(height: 16),
        _buildLabel("Classes concernées"),
        InkWell(
          onTap: () => _showClassSelectionModal(),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.backgroundGrey,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.class_rounded,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedClasseIds.isEmpty
                        ? "Sélectionner les classes"
                        : "${_selectedClasseIds.length} classe(s) sélectionnée(s)",
                    style: TextStyle(
                      color:
                          _selectedClasseIds.isEmpty
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
                      fontWeight:
                          _selectedClasseIds.isEmpty
                              ? FontWeight.normal
                              : FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down_rounded,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
        if (_selectedClasseIds.isNotEmpty) ...[
          const SizedBox(height: 8),
          Obx(
            () => Wrap(
              spacing: 6,
              runSpacing: 6,
              children:
                  _selectedClasseIds.map((id) {
                    final cls = _authController.classes.firstWhereOrNull(
                      (c) => c.id == id,
                    );
                    return Chip(
                      label: Text(
                        cls?.fullName ?? cls?.nom ?? id,
                        style: const TextStyle(fontSize: 12),
                      ),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted:
                          () => setState(() => _selectedClasseIds.remove(id)),
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      labelStyle: TextStyle(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    );
                  }).toList(),
            ),
          ),
        ],
        const SizedBox(height: 16),
        _buildLabel("Salle de classe"),
        Obx(
          () => DropdownButtonFormField<String>(
            value: _selectedLieuId,
            decoration: _inputDecoration("Sélectionner la salle"),
            items:
                _authController.locations.map((loc) {
                  return DropdownMenuItem(value: loc.id, child: Text(loc.name));
                }).toList(), 
            onChanged: (val) => setState(() => _selectedLieuId = val),
          ),
        ),
      ],
    );
  }

  Widget _buildStep2Horaires() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Horaires de la séance",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel("Heure de début"),
                  InkWell(
                    onTap: () => _pickTime(true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundGrey,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                           Icon(
                            Icons.access_time_rounded,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _heureDebut != null
                                ? DateFormat('HH:mm').format(_heureDebut!)
                                : "--:--",
                            style: TextStyle(
                              color:
                                  _heureDebut != null
                                      ? AppColors.textPrimary
                                      : AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel("Heure de fin"),
                  InkWell(
                    onTap: () => _pickTime(false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundGrey,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                           Icon(
                            Icons.access_time_rounded,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _heureFin != null
                                ? DateFormat('HH:mm').format(_heureFin!)
                                : "--:--",
                            style: TextStyle(
                              color:
                                  _heureFin != null
                                      ? AppColors.textPrimary
                                      : AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
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
        const SizedBox(height: 16),
        _buildLabel("Marge de tolérance (en min)"),
        TextField(
          controller: _toleranceController,
          keyboardType: TextInputType.number,
          decoration: _inputDecoration("Ex: 15"),
        ),
      ],
    );
  }

  Widget _buildStep3Validation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Type de validation",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildLabel("Méthode de pointage pour les étudiants"),
        const SizedBox(height: 10),
        _buildModeSelector(),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: TextStyle(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppColors.backgroundGrey,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _buildModeSelector() {
    return Row(
      children: [
        _modeItem(SessionMode.GPS, Icons.location_on_rounded, "GPS"),
        const SizedBox(width: 12),
        _modeItem(SessionMode.SCAN_QR, Icons.qr_code_rounded, "QR Code"),
        const SizedBox(width: 12),
        _modeItem(SessionMode.MANUEL, Icons.edit_note_rounded, "Manuel"),
      ],
    );
  }

  Widget _modeItem(SessionMode mode, IconData icon, String label) {
    final isSelected = _selectedMode == mode;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedMode = mode),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color:
                isSelected ? AppColors.primary.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.grey300,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color:
                      isSelected ? AppColors.primary : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _validateCurrentStep() {
    if (_currentStep == 0) {
      if (_selectedMatterId == null) {
        AppUtils.showErrorToast("Veuillez sélectionner une matière");
        return false;
      }
      if (_selectedClasseIds.isEmpty) {
        AppUtils.showErrorToast("Veuillez sélectionner au moins une classe");
        return false;
      }
      if (_selectedLieuId == null) {
        AppUtils.showErrorToast("Veuillez sélectionner une salle");
        return false;
      }
    } else if (_currentStep == 1) {
      if (_heureDebut == null) {
        AppUtils.showErrorToast("Veuillez choisir l'heure de début");
        return false;
      }
      if (_heureFin == null) {
        AppUtils.showErrorToast("Veuillez choisir l'heure de fin");
        return false;
      }
      if (_toleranceController.text.trim().isEmpty) {
        AppUtils.showErrorToast("Veuillez saisir la marge de tolérance");
        return false;
      }
    }
    return true;
  }

  void _showClassSelectionModal() {
    final tempSelected = List<String>.from(_selectedClasseIds);

    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Sélectionner les classes",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  "Sélectionnez une ou plusieurs classes",
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                Obx(() {
                  final classes = _authController.classes;
                  if (classes.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: Text("Aucune classe disponible")),
                    );
                  }
                  return ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.4,
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: classes.length,
                      itemBuilder: (context, index) {
                        final cls = classes[index];
                        final isChecked = tempSelected.contains(cls.id);
                        return CheckboxListTile(
                          value: isChecked,
                          onChanged: (val) {
                            setModalState(() {
                              if (val == true) {
                                tempSelected.add(cls.id);
                              } else {
                                tempSelected.remove(cls.id);
                              }
                            });
                          },
                          title: Text(
                            cls.fullName ?? cls.nom,
                            style: TextStyle(
                              fontWeight:
                                  isChecked
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                              color:
                                  isChecked
                                      ? AppColors.primary
                                      : AppColors.textPrimary,
                            ),
                          ),
                          activeColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: EdgeInsets.zero,
                        );
                      },
                    ),
                  );
                }),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _selectedClasseIds.clear();
                        _selectedClasseIds.addAll(tempSelected);
                      });
                      Get.back();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      tempSelected.isEmpty
                          ? "Aucune classe"
                          : "Confirmer (${tempSelected.length} classe${tempSelected.length > 1 ? 's' : ''})",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      isScrollControlled: true,
    );
  }

  Future<void> _pickTime(bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final now = DateTime.now();
      final selectedDate = DateTime(
        now.year,
        now.month,
        now.day,
        picked.hour,
        picked.minute,
      );

      setState(() {
        if (isStart) {
          _heureDebut = selectedDate;
        } else {
          _heureFin = selectedDate;
        }
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (_selectedMatterId == null ||
        _selectedLieuId == null ||
        _selectedClasseIds.isEmpty ||
        _heureDebut == null ||
        _heureFin == null) {
      Get.snackbar(
        "Erreur",
        "Veuillez remplir tous les champs obligatoires (sélectionnez au moins une classe)",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    int margeTol = int.tryParse(_toleranceController.text) ?? 15;

    final sessionCreated = await _sessionController.createSession(
      matiereId: _selectedMatterId,
      matiere:
          _authController.matters
              .firstWhere((m) => m.id == _selectedMatterId)
              .nom,
      lieuId: _selectedLieuId!,
      classeIds: _selectedClasseIds,
      mode: _selectedMode,
      heureDebut: _heureDebut!,
      heureFin: _heureFin!,
      margeTolerance: margeTol,
    );

    if (sessionCreated != null) {
      await _sessionController.startSession(sessionCreated.id);

      Get.off(() => LiveMonitorView(sessionId: sessionCreated.id));

      Get.snackbar(
        "Séance Lancée",
        "Notifications envoyées aux étudiants",
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}

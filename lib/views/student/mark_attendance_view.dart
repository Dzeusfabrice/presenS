import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:geolocator/geolocator.dart';
import '../../controllers/attendance_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/session_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/location_utils.dart';
import '../../models/session_model.dart';

class MarkAttendanceView extends StatefulWidget {
  final String? preSelectedSessionId;
  const MarkAttendanceView({Key? key, this.preSelectedSessionId})
    : super(key: key);

  @override
  State<MarkAttendanceView> createState() => _MarkAttendanceViewState();
}

class _MarkAttendanceViewState extends State<MarkAttendanceView> {
  final AttendanceController _attendanceController =
      Get.find<AttendanceController>();
  final AuthController _authController = Get.find<AuthController>();
  final SessionController _sessionController = Get.find<SessionController>();

  bool _isVerifying = false;
  String? _selectedSessionId;
  SessionModel? _currentSession;
  MobileScannerController? _scannerController;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    if (widget.preSelectedSessionId != null) {
      _selectedSessionId = widget.preSelectedSessionId;
      _updateCurrentSession();
    }
    _scannerController = MobileScannerController();
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    super.dispose();
  }

  void _updateCurrentSession() {
    if (_selectedSessionId != null) {
      _currentSession = _sessionController.activeSessions.firstWhereOrNull(
        (s) => s.id == _selectedSessionId,
      );
    } else {
      _currentSession = null;
    }
  }

  /// Démarre le scanner QR pour le mode SCAN_QR
  void _startQRScanner() {
    if (_currentSession?.mode != SessionMode.SCAN_QR) {
      _handleGPSAttendance();
      return;
    }

    setState(() {
      _isScanning = true;
    });
    _scannerController?.start();
  }

  /// Gère le scan du QR Code
  Future<void> _handleQRScan(String scannedData) async {
    if (_selectedSessionId == null || _currentSession == null) return;

    setState(() {
      _isScanning = false;
      _isVerifying = true;
    });
    _scannerController?.stop();

    try {
      // 1. Décoder le QR Code pour extraire le locationId
      final locationIdFromQR = _decodeQRCode(scannedData);
      print('📱 QR Code scanné - Location ID: $locationIdFromQR');

      // 2. Vérifier que le lieu du QR correspond au lieu de la séance
      if (locationIdFromQR != _currentSession!.lieuId) {
        Get.snackbar(
          "Erreur",
          "Ce QR Code ne correspond pas à la salle de cette séance.",
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        setState(() => _isVerifying = false);
        return;
      }

      // 3. Récupérer les coordonnées GPS de l'étudiant
      final position = await _getCurrentLocation();
      final studentLat = position.latitude;
      final studentLon = position.longitude;
      print('📍 Position étudiante: $studentLat, $studentLon');

      // 4. Récupérer les informations du lieu
      final location = _authController.locations.firstWhereOrNull(
        (loc) => loc.id == _currentSession!.lieuId,
      );

      if (location == null ||
          location.latitude == null ||
          location.longitude == null) {
        Get.snackbar(
          "Erreur",
          "Impossible de vérifier votre position. Lieu introuvable.",
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        setState(() => _isVerifying = false);
        return;
      }

      // 5. Calculer la distance entre l'étudiant et le lieu
      final distance = LocationUtils.calculateDistance(
        studentLat,
        studentLon,
        location.latitude!,
        location.longitude!,
      );

      // 6. Vérifier que l'étudiant est dans le rayon autorisé
      final radius = location.radius ?? 50.0; // Rayon par défaut
      print('📏 Distance: ${distance.toStringAsFixed(1)}m / Rayon max: ${radius}m');

      if (distance > radius) {
        Get.snackbar(
          "Hors zone",
          "Vous êtes trop loin de la salle.\nDistance: ${distance.toStringAsFixed(1)}m (max: ${radius}m)",
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 4),
        );
        setState(() => _isVerifying = false);
        return;
      }

      // 7. Tout est OK → Enregistrer la présence
      final success = await _attendanceController.markPresence(
        sessionId: _selectedSessionId!,
        etudiantId: _authController.user.value?.id ?? "unknown",
        lat: studentLat,
        lon: studentLon,
      );

      setState(() => _isVerifying = false);

      if (success) {
        Get.back();
        Get.snackbar(
          "Succès",
          "Votre présence a été enregistrée avec succès !",
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          "Erreur",
          "Impossible d'enregistrer votre présence.",
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      setState(() => _isVerifying = false);
      Get.snackbar(
        "Erreur",
        "Erreur lors du scan: ${e.toString()}",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Gère le marquage de présence en mode GPS
  Future<void> _handleGPSAttendance() async {
    if (_selectedSessionId == null || _currentSession == null) return;

    // In MANUEL mode, the student shouldn't validate themselves
    if (_currentSession!.mode == SessionMode.MANUEL) {
      Get.snackbar(
        "Mode Manuel",
        "Veuillez attendre que l'enseignant fasse l'appel.",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    setState(() => _isVerifying = true);

    try {
      // Récupérer la position GPS
      final position = await _getCurrentLocation();
      final studentLat = position.latitude;
      final studentLon = position.longitude;

      // Vérifier la position pour le mode GPS aussi
      final location = _authController.locations.firstWhereOrNull(
        (loc) => loc.id == _currentSession!.lieuId,
      );

      if (location != null &&
          location.latitude != null &&
          location.longitude != null) {
        final distance = LocationUtils.calculateDistance(
          studentLat,
          studentLon,
          location.latitude!,
          location.longitude!,
        );
        final radius = location.radius ?? 50.0;

        if (distance > radius) {
          Get.snackbar(
            "Hors zone",
            "Vous êtes trop loin de la salle.\nDistance: ${distance.toStringAsFixed(1)}m (max: ${radius}m)",
            backgroundColor: Colors.orange,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 4),
          );
          setState(() => _isVerifying = false);
          return;
        }
      }

      final success = await _attendanceController.markPresence(
        sessionId: _selectedSessionId!,
        etudiantId: _authController.user.value?.id ?? "unknown",
        lat: studentLat,
        lon: studentLon,
      );

      setState(() => _isVerifying = false);

      if (success) {
        Get.back();
        Get.snackbar(
          "Succès",
          "Votre présence a été enregistrée avec succès !",
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      setState(() => _isVerifying = false);
      Get.snackbar(
        "Erreur",
        "Erreur lors de la vérification GPS: ${e.toString()}",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Décode le QR Code pour extraire le locationId
  String _decodeQRCode(String qrData) {
    try {
      // Si le QR Code est un JSON, parser
      final json = jsonDecode(qrData);
      return json['locationId'] ?? json['id'] ?? qrData;
    } catch (_) {
      // Si c'est juste l'ID directement
      return qrData;
    }
  }

  /// Récupère la position GPS actuelle de l'étudiant
  Future<Position> _getCurrentLocation() async {
    // Vérifier les permissions
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception(
        'Les services de localisation sont désactivés. Veuillez les activer.',
      );
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception(
          'Les permissions de localisation sont refusées.',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Les permissions de localisation sont définitivement refusées. Veuillez les activer dans les paramètres.',
      );
    }

    // Obtenir la position
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: Stack(
        children: [
          // Scanner QR ou fond selon le mode
          if (_isScanning && _currentSession?.mode == SessionMode.SCAN_QR)
            _buildQRScanner()
          else
            Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.black87,
              child: Center(
                child: Icon(
                  _currentSession?.mode == SessionMode.SCAN_QR
                      ? Icons.qr_code_scanner_rounded
                      : _currentSession?.mode == SessionMode.GPS
                      ? Icons.gps_fixed_rounded
                      : Icons.supervised_user_circle_rounded,
                  color: Colors.white24,
                  size: 150,
                ),
              ),
            ),

          // Glass Overlay
          if (!_isScanning)
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: _buildActionCard(),
            ),

          if (_isVerifying) _buildVerifyingOverlay(),
        ],
      ),
    );
  }

  Widget _buildActionCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Marquage de présence",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              _buildContextLabel(),

              const SizedBox(height: 24),

              // Session Selection
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Obx(
                  () => DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedSessionId,
                      hint: const Text(
                        "Choisir une séance en cours",
                        style: TextStyle(color: Colors.white54),
                      ),
                      dropdownColor: Colors.grey.shade900,
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.white,
                      ),
                      isExpanded: true,
                      style: const TextStyle(color: Colors.white),
                      items:
                          _sessionController.activeSessions.map((s) {
                            return DropdownMenuItem(
                              value: s.id,
                              child: Text(s.matiere),
                            );
                          }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedSessionId = val;
                          _updateCurrentSession();
                        });
                      },
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              if (_currentSession?.mode != SessionMode.MANUEL)
                ElevatedButton(
                  onPressed: _selectedSessionId == null
                      ? null
                      : _currentSession?.mode == SessionMode.SCAN_QR
                      ? _startQRScanner
                      : _handleGPSAttendance,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _currentSession?.mode == SessionMode.SCAN_QR
                        ? "Scanner le QR Code"
                        : "Je suis présent (GPS)",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContextLabel() {
    if (_currentSession == null) {
      return Text(
        "Sélectionnez une séance pour voir le mode de validation.",
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
      );
    }

    switch (_currentSession!.mode) {
      case SessionMode.GPS:
        return Text(
          "Ce cours utilise le mode GPS. Veuillez vous assurer d'être dans le rayon de la salle.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
        );
      case SessionMode.SCAN_QR:
        return Text(
          "Ce cours utilise le mode QR Code. Scannez le code affiché dans la salle de cours.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
        );
      case SessionMode.MANUEL:
        return Text(
          "L'appel se fait manuellement par l'enseignant. Vous n'avez rien à faire sur votre application.",
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.orangeAccent,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        );
    }
  }

  Widget _buildVerifyingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.primaryLight),
            const SizedBox(height: 20),
            Text(
              _currentSession?.mode == SessionMode.SCAN_QR
                  ? "Vérification du QR Code et de votre position..."
                  : "Vérification GPS & Anti-fraude...",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construit le widget du scanner QR
  Widget _buildQRScanner() {
    return Stack(
      children: [
        MobileScanner(
          controller: _scannerController,
          onDetect: (capture) {
            final List<Barcode> barcodes = capture.barcodes;
            if (barcodes.isNotEmpty && !_isVerifying) {
              final barcode = barcodes.first;
              if (barcode.rawValue != null) {
                _handleQRScan(barcode.rawValue!);
              }
            }
          },
        ),
        // Overlay avec instructions
        Positioned(
          top: 100,
          left: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.qr_code_scanner_rounded,
                  color: Colors.white,
                  size: 48,
                ),
                SizedBox(height: 12),
                Text(
                  "Scannez le QR Code de la salle",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  "Positionnez le code dans le cadre",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        // Bouton retour
        Positioned(
          top: 40,
          left: 20,
          child: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () {
              setState(() {
                _isScanning = false;
              });
              _scannerController?.stop();
            },
            style: IconButton.styleFrom(
              backgroundColor: Colors.black.withOpacity(0.5),
            ),
          ),
        ),
      ],
    );
  }
}

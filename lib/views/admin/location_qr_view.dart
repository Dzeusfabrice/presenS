import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../controllers/auth_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_utils.dart';
import '../../models/location_model.dart';

class LocationQrView extends StatefulWidget {
  const LocationQrView({Key? key}) : super(key: key);

  @override
  State<LocationQrView> createState() => _LocationQrViewState();
}

class _LocationQrViewState extends State<LocationQrView> {
  final AuthController _authController = Get.find<AuthController>();

  @override
  void initState() {
    super.initState();
    _authController.fetchLocations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      appBar: AppBar(
        title: Text(
          "Générateur QR Codes",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.cardBackground,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: Obx(() {
        final locations = _authController.locations;

        if (_authController.isLoading.value && locations.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (locations.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: locations.length,
          itemBuilder: (context, index) {
            final loc = locations[index];
            return _buildLocationItem(loc);
          },
        );
      }),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.location_off_rounded,
            size: 64,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            "Aucune salle disponible",
            style: GoogleFonts.outfit(
              fontSize: 18,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationItem(LocationModel location) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.meeting_room_rounded,
                color: AppColors.primary,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    location.buildingName,
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Salle : ${location.roomNumber}",
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _showQRCodeDialog(location),
              icon: const Icon(Icons.qr_code_2_rounded),
              color: AppColors.primary,
              iconSize: 32,
              tooltip: "Générer QR",
            ),
          ],
        ),
      ),
    );
  }

  void _showQRCodeDialog(LocationModel location) {
    Get.dialog(
      _QrCodeDialog(location: location),
      barrierColor: Colors.black.withOpacity(0.7),
    );
  }
}

class _QrCodeDialog extends StatefulWidget {
  final LocationModel location;
  const _QrCodeDialog({Key? key, required this.location}) : super(key: key);

  @override
  State<_QrCodeDialog> createState() => _QrCodeDialogState();
}

class _QrCodeDialogState extends State<_QrCodeDialog> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isSaving = false;

  Future<void> _saveQrCode() async {
    setState(() => _isSaving = true);
    try {
      // Demander la permission de stockage si nécessaire
      if (Platform.isAndroid) {
        var status = await Permission.storage.request();
        // Optionnel: request manageExternalStorage for Android 11+
        if (!status.isGranted) {
           await Permission.manageExternalStorage.request();
           // Même sans la permission, pour le dossier public "Download", l'écriture peut parfois fonctionner.
        }
      }

      // Capturer le widget entier en tant qu'image (avec fond blanc, nom de la salle, etc.)
      final Uint8List? imageBytes = await _screenshotController.capture(
        delay: const Duration(milliseconds: 100),
        pixelRatio: 3.0,
      );

      if (imageBytes != null) {
        Directory? customDir;
        if (Platform.isAndroid) {
          customDir = Directory('/storage/emulated/0/Download/PresenS_QRCodes');
        } else {
          final dir = await getApplicationDocumentsDirectory();
          customDir = Directory('${dir.path}/PresenS_QRCodes');
        }

        if (!await customDir.exists()) {
          await customDir.create(recursive: true);
        }

        final sanitizeName = widget.location.name.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
        final filePath = '${customDir.path}/QR_${sanitizeName}_${DateTime.now().millisecondsSinceEpoch}.png';
        final file = File(filePath);

        await file.writeAsBytes(imageBytes);

        AppUtils.showSuccessToast("QR sauvegardé dans :\n$filePath");
      }
    } catch (e) {
      print("Erreur création QR code: $e");
      AppUtils.showErrorToast("Erreur lors de la sauvegarde : $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // C'est ce bloc qui sera capturé
            Screenshot(
              controller: _screenshotController,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.location.buildingName,
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Salle : ${widget.location.roomNumber}",
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 24),
                    QrImageView(
                      data: widget.location.id,
                      version: QrVersions.auto,
                      size: 200.0,
                      backgroundColor: Colors.white,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "PresenS App - Scan for Attendance",
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.back(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      side: BorderSide(
                        color: AppColors.grey300,
                      ),
                    ),
                    child: Text(
                      "Fermer",
                      style: GoogleFonts.outfit(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveQrCode,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.download_rounded, color: Colors.white),
                    label: Text(
                      _isSaving ? "Patientez..." : "Télécharger",
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../core/api/api_endpoints.dart';
import '../core/utils/app_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ExportService {
  // Méthode générique pour télécharger un fichier
  Future<bool> _downloadFile({
    required String url,
    required String fileName,
    required String format,
  }) async {
    try {
      // 1. Demande de permissions sur Android
      if (Platform.isAndroid) {
        var status = await Permission.storage.request();
        if (!status.isGranted) {
          await Permission.manageExternalStorage.request();
        }
      }

      // 2. Trouver et créer le dossier Téléchargements/PresenS
      Directory? downloadsDir;
      if (Platform.isAndroid) {
        downloadsDir = Directory('/storage/emulated/0/Download');
        if (!downloadsDir.existsSync()) {
          downloadsDir = Directory('/storage/emulated/0/Downloads');
        }
      } else {
        downloadsDir = await getDownloadsDirectory();
      }

      if (downloadsDir == null) {
        throw Exception("Dossier de téléchargement introuvable.");
      }

      final presenSDirPath = '${downloadsDir.path}/PresenS';
      final presenSDir = Directory(presenSDirPath);

      if (!await presenSDir.exists()) {
        await presenSDir.create(recursive: true);
      }

      // 3. Téléchargement du fichier
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.get(
        Uri.parse(url),
        headers: ApiEndpoints.getHeaders(token),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final extension = format.toLowerCase() == 'excel' || format.toLowerCase() == 'csv'
            ? (format.toLowerCase() == 'csv' ? 'csv' : 'xlsx')
            : 'pdf';
        final finalFileName =
            '${fileName}_${DateTime.now().millisecondsSinceEpoch}.$extension';
        final file = File('$presenSDirPath/$finalFileName');

        await file.writeAsBytes(response.bodyBytes);

        Get.snackbar(
          "Succès ✅",
          "Sauvegardé : Téléchargements/PresenS/$finalFileName",
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );
        return true;
      } else {
        throw Exception(
          "Erreur serveur : ${response.statusCode} - ${response.body}",
        );
      }
    } catch (e) {
      AppUtils.handleError(e);
      Get.snackbar(
        "Erreur d'exportation ❌",
        "Impossible de télécharger : ${e.toString()}",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
      return false;
    }
  }

  // Export des étudiants
  Future<bool> exportStudents(String format) async {
    Get.snackbar(
      "Exportation en cours...",
      "Téléchargement de la liste des étudiants en format $format",
      backgroundColor: Colors.blue,
      colorText: Colors.white,
    );

    return await _downloadFile(
      url: ApiEndpoints.exportStudents(format.toLowerCase()),
      fileName: 'Liste_Etudiants',
      format: format,
    );
  }

  // Export des enseignants
  Future<bool> exportTeachers(String format) async {
    Get.snackbar(
      "Exportation en cours...",
      "Téléchargement de la liste des enseignants en format $format",
      backgroundColor: Colors.blue,
      colorText: Colors.white,
    );

    return await _downloadFile(
      url: ApiEndpoints.exportTeachers(format.toLowerCase()),
      fileName: 'Liste_Enseignants',
      format: format,
    );
  }

  // Export des lieux/salles
  Future<bool> exportLocations(String format) async {
    Get.snackbar(
      "Exportation en cours...",
      "Téléchargement du rapport des salles en format $format",
      backgroundColor: Colors.blue,
      colorText: Colors.white,
    );

    return await _downloadFile(
      url: ApiEndpoints.exportLocations(format.toLowerCase()),
      fileName: 'Rapport_Salles',
      format: format,
    );
  }

  // Export des rapports de présence
  Future<bool> exportAttendance(String format) async {
    Get.snackbar(
      "Exportation en cours...",
      "Téléchargement du rapport de présence en format $format",
      backgroundColor: Colors.blue,
      colorText: Colors.white,
    );

    return await _downloadFile(
      url: ApiEndpoints.exportAttendance(format.toLowerCase()),
      fileName: 'Rapport_Presence_Global',
      format: format,
    );
  }

  // Méthode existante pour les rapports de session
  Future<void> downloadReport(String sessionId, String format) async {
    try {
      // 1. Demande de permissions sur Android
      if (Platform.isAndroid) {
        var status = await Permission.storage.request();
        if (!status.isGranted) {
          // Sur Android 11+ on peut avoir besoin de manageExternalStorage
          await Permission.manageExternalStorage.request();
        }
      }

      // 2. Trouver et créer le dossier Téléchargements/Jenesis
      Directory? downloadsDir;
      if (Platform.isAndroid) {
        downloadsDir = Directory('/storage/emulated/0/Download');
        if (!downloadsDir.existsSync()) {
          downloadsDir = Directory('/storage/emulated/0/Downloads');
        }
      } else {
        downloadsDir = await getDownloadsDirectory();
      }

      if (downloadsDir == null) {
        throw Exception("Dossier de téléchargement introuvable.");
      }

      final jenesisDirPath = '${downloadsDir.path}/PresenS';
      final jenesisDir = Directory(jenesisDirPath);

      if (!await jenesisDir.exists()) {
        await jenesisDir.create(recursive: true);
      }

      Get.snackbar(
        "Exportation en cours...",
        "Le téléchargement du rapport $format a commencé.",
        backgroundColor: Colors.blue,
        colorText: Colors.white,
      );

      // 3. Téléchargement du fichier
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final url = Uri.parse(
        "${ApiEndpoints.exportReport(sessionId)}?format=${format.toLowerCase()}",
      );

      final response = await http.get(
        url,
        headers: ApiEndpoints.getHeaders(token),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final extension = format.toLowerCase() == 'excel' ? 'xlsx' : 'pdf';
        final fileName =
            'Presence_${sessionId}_${DateTime.now().millisecondsSinceEpoch}.$extension';
        final file = File('$jenesisDirPath/$fileName');

        await file.writeAsBytes(response.bodyBytes);

        Get.snackbar(
          "Succès ✅",
          "Sauvegardé : Téléchargements/PresenS/$fileName",
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );
      } else {
        throw Exception(
          "Erreur serveur : ${response.statusCode} - ${response.body}",
        );
      }
    } catch (e) {
      AppUtils.handleError(e);
      Get.snackbar(
        "Erreur d'exportation ❌",
        "Impossible de télécharger : $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    }
  }
}

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../core/api/api_endpoints.dart';
import '../core/utils/app_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:excel/excel.dart' as excel_lib;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:csv/csv.dart';

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

      print('📤 Demande d\'exportation vers: $url');
      final response = await http.get(
        Uri.parse(url),
        headers: ApiEndpoints.getHeaders(token),
      );

      print('📥 Réponse exportation [${response.statusCode}]');

      if (response.statusCode == 200 || response.statusCode == 201) {
        Uint8List finalBytes;
        String extension;

        final lowerFormat = format.toLowerCase();

        // Si le backend renvoie du CSV mais que l'utilisateur veut un autre format
        if (lowerFormat == 'excel' || lowerFormat == 'xlsx') {
          extension = 'xlsx';
          finalBytes = _convertCsvToExcel(response.body);
        } else if (lowerFormat == 'pdf') {
          extension = 'pdf';
          finalBytes = await _convertCsvToPdf(response.body, fileName);
        } else {
          extension = 'csv';
          finalBytes = response.bodyBytes;
        }

        final finalFileName =
            '${fileName}_${DateTime.now().millisecondsSinceEpoch}.$extension';
        final file = File('$presenSDirPath/$finalFileName');

        await file.writeAsBytes(finalBytes);

        Get.snackbar(
          "Succès ✅",
          "Sauvegardé : Téléchargements/PresenS/$finalFileName",
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );
        return true;
      } else {
        print('❌ Échec de l\'exportation [${response.statusCode}]: ${response.body}');
        throw Exception(
          "Erreur serveur : ${response.statusCode} - ${response.body}",
        );
      }
    } catch (e) {
      print('❌ Erreur critique lors de l\'exportation: $e');
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
  Future<bool> exportStudents(String format, {String? classId}) async {
    Get.snackbar(
      "Exportation en cours...",
      "Téléchargement de la liste des étudiants en format $format",
      backgroundColor: Colors.blue,
      colorText: Colors.white,
    );

    return await _downloadFile(
      url: ApiEndpoints.exportStudents(format.toLowerCase(), classId: classId),
      fileName: classId != null ? 'Liste_Etudiants_$classId' : 'Liste_Etudiants',
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
  Future<bool> exportAttendance(String format, {String? classId}) async {
    Get.snackbar(
      "Exportation en cours...",
      "Téléchargement du rapport de présence en format $format",
      backgroundColor: Colors.blue,
      colorText: Colors.white,
    );

    return await _downloadFile(
      url: ApiEndpoints.exportAttendance(format.toLowerCase(), classId: classId),
      fileName: classId != null ? 'Rapport_Presence_$classId' : 'Rapport_Presence_Global',
      format: format,
    );
  }

  // Export du Bilan de Classe (Toutes les séances)
  Future<bool> exportClassReport(String format, String classId) async {
    Get.snackbar(
      "Exportation en cours...",
      "Téléchargement du bilan de classe en format $format",
      backgroundColor: Colors.blue,
      colorText: Colors.white,
    );

    return await _downloadFile(
      url: ApiEndpoints.classReport(classId, format.toLowerCase()),
      fileName: 'Bilan_Classe_$classId',
      format: format,
    );
  }

  // Export de l'Historique d'un Étudiant
  Future<bool> exportStudentReport(String format, String studentId) async {
    Get.snackbar(
      "Exportation en cours...",
      "Téléchargement de l'historique étudiant en format $format",
      backgroundColor: Colors.blue,
      colorText: Colors.white,
    );

    return await _downloadFile(
      url: ApiEndpoints.studentReport(studentId, format.toLowerCase()),
      fileName: 'Historique_Etudiant_$studentId',
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
        ApiEndpoints.exportReport(sessionId, format.toLowerCase()),
      );

      print('📤 Demande de rapport vers: $url');
      final response = await http.get(
        url,
        headers: ApiEndpoints.getHeaders(token),
      );

      print('📥 Réponse rapport [${response.statusCode}]');

      if (response.statusCode == 200 || response.statusCode == 201) {
        Uint8List finalBytes;
        String extension;

        final lowerFormat = format.toLowerCase();

        if (lowerFormat == 'excel' || lowerFormat == 'xlsx') {
          extension = 'xlsx';
          finalBytes = _convertCsvToExcel(response.body);
        } else if (lowerFormat == 'pdf') {
          extension = 'pdf';
          finalBytes = await _convertCsvToPdf(
            response.body,
            "Rapport_Presence_$sessionId",
          );
        } else {
          extension = 'csv';
          finalBytes = response.bodyBytes;
        }

        final fileName =
            'Presence_${sessionId}_${DateTime.now().millisecondsSinceEpoch}.$extension';
        final file = File('$jenesisDirPath/$fileName');

        await file.writeAsBytes(finalBytes);

        Get.snackbar(
          "Succès ✅",
          "Sauvegardé : Téléchargements/PresenS/$fileName",
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );
      } else {
        print('❌ Échec du téléchargement du rapport [${response.statusCode}]: ${response.body}');
        throw Exception(
          "Erreur serveur : ${response.statusCode} - ${response.body}",
        );
      }
    } catch (e) {
      print('❌ Erreur critique lors du téléchargement du rapport: $e');
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

  // Helper pour convertir CSV en Excel (.xlsx)
  Uint8List _convertCsvToExcel(String csvData) {
    var excel = excel_lib.Excel.createExcel();
    var sheet = excel['Sheet1'];

    List<List<dynamic>> rows = const CsvToListConverter().convert(csvData);

    for (var i = 0; i < rows.length; i++) {
      for (var j = 0; j < rows[i].length; j++) {
        var cell = sheet.cell(
          excel_lib.CellIndex.indexByColumnRow(columnIndex: j, rowIndex: i),
        );
        cell.value = excel_lib.TextCellValue(rows[i][j].toString());
      }
    }

    final bytes = excel.save();
    return Uint8List.fromList(bytes!);
  }

  // Helper pour convertir CSV en PDF
  Future<Uint8List> _convertCsvToPdf(String csvData, String title) async {
    final pdf = pw.Document();
    List<List<dynamic>> rows = const CsvToListConverter().convert(csvData);

    if (rows.isEmpty) return Uint8List(0);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build:
            (context) => [
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      title.replaceAll('_', ' '),
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    pw.Text(DateTime.now().toString().split('.')[0]),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.blueGrey800,
                ),
                cellHeight: 30,
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerLeft,
                },
                data:
                    rows
                        .map(
                          (row) => row.map((cell) => cell.toString()).toList(),
                        )
                        .toList(),
              ),
            ],
      ),
    );

    return await pdf.save();
  }
}

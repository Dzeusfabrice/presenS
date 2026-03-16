import 'dart:io';
import 'dart:convert';
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
import 'package:flutter/services.dart' show rootBundle;
import 'package:share_plus/share_plus.dart';

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
        
        // --- NOUVEAU : Nettoyage des données ---
        List<List<dynamic>> rows = _processRawData(response.body);

        if (lowerFormat == 'excel' || lowerFormat == 'xlsx') {
          extension = 'xlsx';
          finalBytes = _convertRowsToExcel(rows);
        } else if (lowerFormat == 'pdf') {
          extension = 'pdf';
          finalBytes = await _convertRowsToPdf(rows, fileName);
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
          duration: const Duration(seconds: 4),
        );

        // Déclencher le partage automatiquement
        await Share.shareXFiles([XFile(file.path)], text: 'Rapport PresenS $finalFileName');
        
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
          finalBytes = _convertRowsToExcel(_processRawData(response.body));
        } else if (lowerFormat == 'pdf') {
          extension = 'pdf';
          finalBytes = await _convertRowsToPdf(
            _processRawData(response.body),
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

  // --- HELPERS DE TRAITEMENT DES DONNÉES ---

  // Nettoie la réponse JSON pour extraire uniquement les lignes de données
  List<List<dynamic>> _processRawData(String rawBody) {
    try {
      final decoded = jsonDecode(rawBody);
      
      // Si c'est un Map avec une clé 'data' (format standard de votre API)
      if (decoded is Map && decoded.containsKey('data')) {
        final data = decoded['data'];
        
        if (data is List) {
          if (data.isEmpty) return [];
          
          // 1. Extraire les clés du premier objet pour faire les en-têtes
          List<String> rawHeaders = (data.first as Map<String, dynamic>).keys.toList();
          List<String> cleanHeaders = rawHeaders.map((h) => _beautifyHeader(h)).toList();
          
          List<List<dynamic>> rows = [cleanHeaders];
          
          // 2. Extraire les valeurs pour chaque ligne
          for (var item in data) {
            if (item is Map) {
              rows.add(rawHeaders.map((key) => item[key] ?? "").toList());
            }
          }
          return rows;
        } else if (data is String) {
          // Si 'data' contient déjà du CSV
          return const CsvToListConverter(fieldDelimiter: ",").convert(data);
        }
      }
      
      // Si c'est directement une liste d'objets
      if (decoded is List) {
        if (decoded.isEmpty) return [];
        List<String> rawHeaders = (decoded.first as Map<String, dynamic>).keys.toList();
        List<List<dynamic>> rows = [rawHeaders.map((h) => _beautifyHeader(h)).toList()];
        for (var item in decoded) {
          rows.add(rawHeaders.map((key) => item[key] ?? "").toList());
        }
        return rows;
      }
    } catch (e) {
      print("Pas un format JSON standard, essai de lecture CSV brute : $e");
    }

    // Par défaut, traite comme du CSV brut
    String separator = rawBody.contains(";") ? ";" : ",";
    return CsvToListConverter(fieldDelimiter: separator).convert(rawBody);
  }

  // Transforme les clés techniques en titres lisibles
  String _beautifyHeader(String key) {
    switch (key.toLowerCase()) {
      case 'id': return 'ID';
      case 'nom': return 'NOM';
      case 'prenom': return 'PRÉNOM';
      case 'email': return 'E-MAIL';
      case 'role': return 'RÔLE';
      case 'classe': return 'CLASSE';
      case 'matiere': return 'MATIÈRE';
      case 'presence': return 'STATUT';
      case 'date': return 'DATE';
      case 'heure': return 'HEURE';
      case 'telephone': return 'TÉLÉPHONE';
      default: return key.toUpperCase().replaceAll('_', ' ');
    }
  }

  // --- CONVERTISSEURS ---

  // Version améliorée qui prend directement des lignes traitées
  Uint8List _convertRowsToExcel(List<List<dynamic>> rows) {
    if (rows.isEmpty) return Uint8List(0);

    var excel = excel_lib.Excel.createExcel();
    excel.delete('Sheet1');
    var sheet = excel['Rapport'];

    var titleStyle = excel_lib.CellStyle(
      fontSize: 18,
      bold: true,
      fontColorHex: excel_lib.ExcelColor.fromHexString("#1E293B"),
      verticalAlign: excel_lib.VerticalAlign.Center,
    );

    var headerStyle = excel_lib.CellStyle(
      backgroundColorHex: excel_lib.ExcelColor.fromHexString("#2C3E50"),
      fontColorHex: excel_lib.ExcelColor.fromHexString("#FFFFFF"),
      bold: true,
      horizontalAlign: excel_lib.HorizontalAlign.Center,
      verticalAlign: excel_lib.VerticalAlign.Center,
      leftBorder: excel_lib.Border(borderStyle: excel_lib.BorderStyle.Thin),
      rightBorder: excel_lib.Border(borderStyle: excel_lib.BorderStyle.Thin),
      topBorder: excel_lib.Border(borderStyle: excel_lib.BorderStyle.Thin),
      bottomBorder: excel_lib.Border(borderStyle: excel_lib.BorderStyle.Thin),
    );

    var dataStyle = excel_lib.CellStyle(
      horizontalAlign: excel_lib.HorizontalAlign.Left,
      verticalAlign: excel_lib.VerticalAlign.Center,
      leftBorder: excel_lib.Border(borderStyle: excel_lib.BorderStyle.Thin),
      rightBorder: excel_lib.Border(borderStyle: excel_lib.BorderStyle.Thin),
      topBorder: excel_lib.Border(borderStyle: excel_lib.BorderStyle.Thin),
      bottomBorder: excel_lib.Border(borderStyle: excel_lib.BorderStyle.Thin),
    );

    // Titre de la feuille (Ligne 0)
    sheet.merge(
      excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
      excel_lib.CellIndex.indexByColumnRow(columnIndex: rows[0].length - 1, rowIndex: 0),
    );
    var titleCell = sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0));
    titleCell.value = excel_lib.TextCellValue("PRESENS - RAPPORT D'ACTIVITÉ");
    titleCell.cellStyle = titleStyle;
    sheet.setRowHeight(0, 30);

    // Date de génération (Ligne 1)
    var dateCell = sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1));
    dateCell.value = excel_lib.TextCellValue("Généré le: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year} à ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}");

    int startRow = 3; // On laisse une ligne vide puis on commence les en-têtes à la ligne 4 (index 3)

    for (var i = 0; i < rows.length; i++) {
      for (var j = 0; j < rows[i].length; j++) {
        var cell = sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: j, rowIndex: i + startRow));
        cell.value = excel_lib.TextCellValue(rows[i][j].toString());

        if (i == 0) {
          cell.cellStyle = headerStyle;
        } else {
          cell.cellStyle = dataStyle;
        }
      }
      sheet.setRowHeight(i + startRow, 20);
    }

    // Auto-ajuster les colonnes
    for (var j = 0; j < rows[0].length; j++) {
      sheet.setColumnAutoFit(j);
    }

    return Uint8List.fromList(excel.save()!);
  }

  // Version améliorée pour le PDF
  Future<Uint8List> _convertRowsToPdf(List<List<dynamic>> rows, String title) async {
    final pdf = pw.Document();

    pw.MemoryImage? logoImage;
    try {
      final ByteData data = await rootBundle.load('assets/images/logo.png');
      logoImage = pw.MemoryImage(data.buffer.asUint8List());
    } catch (e) {}

    if (rows.isEmpty) return Uint8List(0);

    final List<String> headers = rows.first.map((e) => e.toString()).toList();
    final List<List<String>> data = rows.skip(1).map((row) => row.map((e) => e.toString()).toList()).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(30),
        build: (context) => [
          // En-tête
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Row(
                children: [
                  if (logoImage != null) pw.Container(width: 40, height: 40, child: pw.Image(logoImage)),
                  pw.SizedBox(width: 10),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("PRESENS - GESTION D'ASSIDUITÉ", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                      pw.Text(title.replaceAll('_', ' '), style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900)),
                    ],
                  ),
                ],
              ),
              pw.Text("Généré le: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}"),
            ],
          ),
          pw.Divider(thickness: 2, color: PdfColors.blueGrey800),
          pw.SizedBox(height: 20),

          // Tableau
          pw.TableHelper.fromTextArray(
            headers: headers,
            data: data,
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellHeight: 25,
            oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
            cellAlignments: {for (var i = 0; i < headers.length; i++) i: pw.Alignment.centerLeft},
          ),
        ],
      ),
    );

    return await pdf.save();
  }
}

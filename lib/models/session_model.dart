enum SessionMode { GPS, SCAN_QR, MANUEL }

enum SessionStatus { ATTENTE, EN_COURS, CLOS }

class SessionModel {
  final String id;
  final String matiere;
  final String enseignantId;
  final String lieuId;
  final List<String> classeIds;
  final SessionMode mode;
  final SessionStatus statut;
  final DateTime createdAt;
  final DateTime? heureDebut;
  final DateTime? heureFin;
  final int? margeTolerance;
  final String? qrCode;

  SessionModel({
    required this.id,
    required this.matiere,
    required this.enseignantId,
    required this.lieuId,
    required this.classeIds,
    required this.mode,
    required this.statut,
    required this.createdAt,
    this.heureDebut,
    this.heureFin,
    this.margeTolerance,
    this.qrCode,
  });

  factory SessionModel.fromJson(Map<String, dynamic> json) {
    List<String> classes = [];
    try {
      if (json['classe_ids'] != null && json['classe_ids'] is List) {
        classes =
            (json['classe_ids'] as List)
                .where((e) => e != null)
                .map((e) => e.toString())
                .toList();
      } else if (json['classe_id'] != null) {
        classes = [json['classe_id'].toString()];
      }
    } catch (_) {
      classes = [];
    }

    return SessionModel(
      id: json['id'] ?? '',
      matiere: json['matiere'] ?? '',
      enseignantId: json['enseignant_id'] ?? '',
      lieuId: json['lieu_id'] ?? '',
      classeIds: classes,
      mode: _parseMode(json['mode']),
      statut: _parseStatus(json['statut']),
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : DateTime.now(),
      heureDebut: _parseDateTime(json['heure_debut'] ?? json['heureDebut']),
      heureFin: _parseDateTime(json['heure_fin'] ?? json['heureFin']),
      margeTolerance: json['marge_tolerance'],
      qrCode: json['qr_code'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'matiere': matiere,
      'enseignant_id': enseignantId,
      'lieu_id': lieuId,
      'classe_ids': classeIds,
      'mode': mode.name,
      'statut': statut.name,
      'created_at': createdAt.toIso8601String(),
      'heure_debut': heureDebut?.toIso8601String(),
      'heure_fin': heureFin?.toIso8601String(),
      'marge_tolerance': margeTolerance,
      'qr_code': qrCode,
    };
  }

  static SessionMode _parseMode(String? mode) {
    switch (mode?.toUpperCase()) {
      case 'SCAN_QR':
        return SessionMode.SCAN_QR;
      case 'MANUEL':
        return SessionMode.MANUEL;
      default:
        return SessionMode.GPS;
    }
  }

  static SessionStatus _parseStatus(String? status) {
    switch (status?.toUpperCase()) {
      case 'EN_COURS':
        return SessionStatus.EN_COURS;
      case 'CLOS':
        return SessionStatus.CLOS;
      default:
        return SessionStatus.ATTENTE;
    }
  }

  /// Parse une date depuis différents formats possibles
  static DateTime? _parseDateTime(dynamic dateValue) {
    if (dateValue == null) return null;

    try {
      // Si c'est déjà une DateTime (peu probable mais possible)
      if (dateValue is DateTime) {
        return dateValue;
      }

      // Si c'est une chaîne
      if (dateValue is String) {
        // Essayer différents formats
        try {
          return DateTime.parse(dateValue);
        } catch (e) {
          // Essayer avec format ISO 8601 sans timezone
          try {
            return DateTime.parse('${dateValue}Z');
          } catch (e2) {
            // Essayer avec format simple YYYY-MM-DD HH:mm:ss
            try {
              final parts = dateValue.split(' ');
              if (parts.length == 2) {
                final datePart = parts[0].split('-');
                final timePart = parts[1].split(':');
                if (datePart.length == 3 && timePart.length >= 2) {
                  return DateTime(
                    int.parse(datePart[0]),
                    int.parse(datePart[1]),
                    int.parse(datePart[2]),
                    int.parse(timePart[0]),
                    int.parse(timePart[1]),
                    timePart.length > 2 ? int.parse(timePart[2]) : 0,
                  );
                }
              }
            } catch (e3) {
              print('❌ Erreur parsing date: $dateValue - $e3');
            }
          }
        }
      }

      // Si c'est un timestamp (nombre)
      if (dateValue is int || dateValue is num) {
        return DateTime.fromMillisecondsSinceEpoch(dateValue.toInt());
      }

      return null;
    } catch (e) {
      print('❌ Erreur parsing date: $dateValue - $e');
      return null;
    }
  }
}

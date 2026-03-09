enum AttendanceStatus { PRESENT, RETARD, ABSENT }

class AttendanceModel {
  final String id;
  final String sessionId;
  final String etudiantId;
  final DateTime timestamp;
  final double? latClient;
  final double? longClient;
  final AttendanceStatus statut;
  final bool isMocked;

  AttendanceModel({
    required this.id,
    required this.sessionId,
    required this.etudiantId,
    required this.timestamp,
    this.latClient,
    this.longClient,
    required this.statut,
    this.isMocked = false,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id'] ?? '',
      sessionId: json['session_id'] ?? '',
      etudiantId: json['etudiant_id'] ?? '',
      timestamp:
          json['timestamp'] != null
              ? DateTime.parse(json['timestamp'])
              : DateTime.now(),
      latClient: (json['lat_client'] as num?)?.toDouble(),
      longClient: (json['long_client'] as num?)?.toDouble(),
      statut: _parseStatus(json['statut']),
      isMocked: json['is_mocked'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_id': sessionId,
      'etudiant_id': etudiantId,
      'timestamp': timestamp.toIso8601String(),
      'lat_client': latClient,
      'long_client': longClient,
      'statut': statut.name,
      'is_mocked': isMocked,
    };
  }

  static AttendanceStatus _parseStatus(String? status) {
    switch (status?.toUpperCase()) {
      case 'RETARD':
        return AttendanceStatus.RETARD;
      case 'ABSENT':
        return AttendanceStatus.ABSENT;
      default:
        return AttendanceStatus.PRESENT;
    }
  }
}

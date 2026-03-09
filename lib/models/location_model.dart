class LocationModel {
  final String id;
  final String buildingName;
  final String roomNumber;
  final double? latitude;
  final double? longitude;
  final double? radius;

  LocationModel({
    required this.id,
    required this.buildingName,
    required this.roomNumber,
    this.latitude,
    this.longitude,
    this.radius,
  });

  // Getter pour afficher un nom complet lisible dans le dropdown
  String get name => "$buildingName - $roomNumber";

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      id: json['id'] ?? '',
      buildingName: json['nom_batiment'] ?? json['name'] ?? '',
      roomNumber: json['numero_salle'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      radius: (json['rayon'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom_batiment': buildingName,
      'numero_salle': roomNumber,
      'latitude': latitude,
      'longitude': longitude,
      'rayon': radius,
    };
  }
}

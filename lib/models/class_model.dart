class ClassModel {
  final String id;
  final String nom;
  final String niveau;
  final String parcours;
  final String? fullName;

  ClassModel({
    required this.id,
    required this.nom,
    required this.niveau,
    required this.parcours,
    this.fullName,

  });

  factory ClassModel.fromJson(Map<String, dynamic> json) {
    return ClassModel(
      id: json['id']?.toString() ?? '',
      nom: json['nom']?.toString() ?? json['name']?.toString() ?? '',
      niveau: json['niveau']?.toString() ?? '',
      parcours: json['parcours']?.toString() ?? '',
      fullName: json['nom_complet']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'niveau': niveau,
      'parcours': parcours,
      'nom_complet': fullName,
    };
  }
}

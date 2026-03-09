class ClassModel {
  final String id;
  final String nom;
  final String niveau;
  final String parcours;

  ClassModel({
    required this.id,
    required this.nom,
    required this.niveau,
    required this.parcours,
  });

  factory ClassModel.fromJson(Map<String, dynamic> json) {
    return ClassModel(
      id: json['id']?.toString() ?? '',
      nom: json['nom']?.toString() ?? json['name']?.toString() ?? '',
      niveau: json['niveau']?.toString() ?? '',
      parcours: json['parcours']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'nom': nom, 'niveau': niveau, 'parcours': parcours};
  }
}

class ClassModel {
  final String id;
  final String nom;
  final String niveau;
  final String parcours;
  final String? filiereId;
  final String? niveauId;
  final String? parcoursId;
  final String? anneeId;
  final String? fullName;

  ClassModel({
    required this.id,
    required this.nom,
    required this.niveau,
    required this.parcours,
    this.filiereId,
    this.niveauId,
    this.parcoursId,
    this.anneeId,
    this.fullName,
  });

  factory ClassModel.fromJson(Map<String, dynamic> json) {
    return ClassModel(
      id: json['id']?.toString() ?? '',
      nom: json['nom']?.toString() ?? json['name']?.toString() ?? '',
      niveau: json['niveau']?.toString() ?? '',
      parcours: json['parcours']?.toString() ?? '',
      filiereId: json['filiere_id']?.toString(),
      niveauId: json['niveau_id']?.toString(),
      parcoursId: json['parcours_id']?.toString(),
      anneeId: json['annee_id']?.toString(),
      fullName: json['nom_complet']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'niveau': niveau,
      'parcours': parcours,
      'filiere_id': filiereId,
      'niveau_id': niveauId,
      'parcours_id': parcoursId,
      'annee_id': anneeId,
      'nom_complet': fullName,
    };
  }
}

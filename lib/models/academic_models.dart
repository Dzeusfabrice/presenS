class AcademicYearModel {
  final String id;
  final String nom;

  AcademicYearModel({required this.id, required this.nom});

  factory AcademicYearModel.fromJson(Map<String, dynamic> json) {
    return AcademicYearModel(
      id: json['id']?.toString() ?? '',
      nom: json['libelle']?.toString() ?? json['annee']?.toString() ?? json['nom']?.toString() ?? '',
    );
  }
}

class FiliereModel {
  final String id;
  final String nom;

  FiliereModel({required this.id, required this.nom});

  factory FiliereModel.fromJson(Map<String, dynamic> json) {
    return FiliereModel(
      id: json['id']?.toString() ?? '',
      nom: json['nom']?.toString() ?? '',
    );
  }
}

class LevelModel {
  final String id;
  final String nom;

  LevelModel({required this.id, required this.nom});

  factory LevelModel.fromJson(Map<String, dynamic> json) {
    return LevelModel(
      id: json['id']?.toString() ?? '',
      nom: json['nom']?.toString() ?? '',
    );
  }
}

class ParcoursModel {
  final String id;
  final String nom;
  final String filiereId;

  ParcoursModel({required this.id, required this.nom, required this.filiereId});

  factory ParcoursModel.fromJson(Map<String, dynamic> json) {
    return ParcoursModel(
      id: json['id']?.toString() ?? '',
      nom: json['nom']?.toString() ?? '',
      filiereId: json['filiere_id']?.toString() ?? '',
    );
  }
}

class MatterModel {
  final String id;
  final String nom;
  final String code;

  MatterModel({required this.id, required this.nom, this.code = ''});

  factory MatterModel.fromJson(Map<String, dynamic> json) {
    return MatterModel(
      id: json['id']?.toString() ?? '',
      nom: json['nom']?.toString() ?? json['name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
    );
  }
}

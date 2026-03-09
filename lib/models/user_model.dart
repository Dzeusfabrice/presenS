enum UserRole { ETUDIANT, ENSEIGNANT, ADMIN }

class UserModel {
  final String id;
  final String nom;
  final String prenom;
  final String email;
  final UserRole role;
  final DateTime? createdAt;
  final bool isActive;
  final String? token;
  final String? deviceId;

  // Student specific fields
  final String? matricule;
  final String? classeId;
  final String? niveau;
  final String? parcours;

  // Teacher specific fields
  final String? matriculeEnseignant;
  final String? departement;
  final String? grade;
  final String? password; // Initial password set by admin

  UserModel({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.role,
    this.createdAt,
    this.isActive = true,
    this.token,
    this.deviceId,
    this.matricule,
    this.classeId,
    this.niveau,
    this.parcours,
    this.matriculeEnseignant,
    this.departement,
    this.grade,
    this.password,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] ?? json['_id'] ?? json['userId'] ?? '').toString(),
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      email: json['email'] ?? '',
      role: _parseRole(json['role']),
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : null,
      isActive: json['is_active'] ?? true,
      token: json['token'],
      deviceId: json['device_id'],
      matricule: json['matricule'],
      classeId: json['classe_id'],
      niveau: json['niveau'],
      parcours: json['parcours'],
      matriculeEnseignant: json['matricule_enseignant'],
      departement: json['departement'],
      grade: json['grade'],
      password: json['password'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'role': role.name,
      'created_at': createdAt?.toIso8601String(),
      'is_active': isActive,
      'token': token,
      'device_id': deviceId,
      'matricule': matricule,
      'classe_id': classeId,
      'niveau': niveau,
      'parcours': parcours,
      'matricule_enseignant': matriculeEnseignant,
      'departement': departement,
      'grade': grade,
      'password': password,
    };
  }

  UserModel copyWith({
    String? id,
    String? nom,
    String? prenom,
    String? email,
    UserRole? role,
    DateTime? createdAt,
    bool? isActive,
    String? token,
    String? deviceId,
    String? matricule,
    String? classeId,
    String? niveau,
    String? parcours,
    String? matriculeEnseignant,
    String? departement,
    String? grade,
    String? password,
  }) {
    return UserModel(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      email: email ?? this.email,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      token: token ?? this.token,
      deviceId: deviceId ?? this.deviceId,
      matricule: matricule ?? this.matricule,
      classeId: classeId ?? this.classeId,
      niveau: niveau ?? this.niveau,
      parcours: parcours ?? this.parcours,
      matriculeEnseignant: matriculeEnseignant ?? this.matriculeEnseignant,
      departement: departement ?? this.departement,
      grade: grade ?? this.grade,
      password: password ?? this.password,
    );
  }

  String get roleLabel {
    switch (role) {
      case UserRole.ENSEIGNANT:
        return "Enseignant";
      case UserRole.ADMIN:
        return "Administrateur";
      case UserRole.ETUDIANT:
        return "Étudiant";
    }
  }

  static UserRole _parseRole(String? role) {
    switch (role?.toUpperCase()) {
      case 'ENSEIGNANT':
        return UserRole.ENSEIGNANT;
      case 'ADMIN':
        return UserRole.ADMIN;
      case 'ETUDIANT':
      default:
        return UserRole.ETUDIANT;
    }
  }
}

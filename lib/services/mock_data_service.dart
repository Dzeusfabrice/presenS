import '../models/user_model.dart';
import '../models/location_model.dart';
import '../models/session_model.dart';
import '../models/attendance_model.dart';
import '../models/class_model.dart';

class MockDataService {
  // Singleton
  static final MockDataService _instance = MockDataService._internal();
  factory MockDataService() => _instance;
  MockDataService._internal();

  // --- MOCK CLASSES ---
  final List<ClassModel> classes = [
    ClassModel(
      id: "c1",
      nom: "Licence 3 - Génie Logiciel",
      niveau: "L3",
      parcours: "GL",
    ),
    ClassModel(
      id: "c2",
      nom: "Master 1 - Cybersécurité",
      niveau: "M1",
      parcours: "CYBER",
    ),
  ];

  // --- MOCK USERS ---
  final List<UserModel> users = [
    UserModel(
      id: "user-1",
      nom: "Admin",
      prenom: "System",
      email: "admin@chrono.com",
      role: UserRole.ADMIN,
    ),
    UserModel(
      id: "user-2",
      nom: "Koffi",
      prenom: "Jean",
      email: "jean.koffi@univ.ci",
      role: UserRole.ENSEIGNANT,
      matriculeEnseignant: "ENS-001",
      departement: "Informatique",
    ),
    UserModel(
      id: "user-3",
      nom: "Doe",
      prenom: "John",
      email: "john.doe@etudiant.univ.ci",
      role: UserRole.ETUDIANT,
      matricule: "ETU-2024-001",
      classeId: "loc-1",
      niveau: "L3",
      parcours: "Génie Logiciel",
    ),
  ];

  // --- MOCK LOCATIONS ---
  final List<LocationModel> locations = [
    LocationModel(
      id: "loc-1",
      buildingName: "Batiment A",
      roomNumber: "A101",
      latitude: 5.348,
      longitude: -4.003,
      radius: 50,
    ),
    LocationModel(
      id: "loc-2",
      buildingName: "Bloc B",
      roomNumber: "B302",
      latitude: 5.350,
      longitude: -4.005,
      radius: 30,
    ),
    LocationModel(
      id: "loc-3",
      buildingName: "Amphithéâtre",
      roomNumber: "Ampère",
      latitude: 5.345,
      longitude: -4.001,
      radius: 100,
    ),
  ];

  // --- MOCK SESSIONS ---
  final List<SessionModel> sessions = [
    SessionModel(
      id: "sess-1",
      matiere: "Algorithmique Avancée",
      enseignantId: "user-2",
      lieuId: "loc-1",
      classeIds: ["loc-1"],
      mode: SessionMode.GPS,
      statut: SessionStatus.EN_COURS,
      createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
    ),
    SessionModel(
      id: "sess-2",
      matiere: "Base de Données D1",
      enseignantId: "user-2",
      lieuId: "loc-2",
      classeIds: ["loc-1"],
      mode: SessionMode.SCAN_QR,
      statut: SessionStatus.ATTENTE,
      createdAt: DateTime.now().add(const Duration(hours: 2)),
    ),
  ];

  // --- MOCK ATTENDANCES ---
  final List<AttendanceModel> attendances = [
    AttendanceModel(
      id: "att-1",
      sessionId: "sess-1",
      etudiantId: "user-3",
      timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
      latClient: 5.34801,
      longClient: -4.00301,
      statut: AttendanceStatus.PRESENT,
    ),
  ];
}

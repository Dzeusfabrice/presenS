import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chrono/core/utils/diviceManager.dart';
import 'package:http/http.dart' as http;
import '../core/api/logged_http_client.dart';
import '../core/api/api_endpoints.dart';
import '../core/utils/app_utils.dart';
import '../models/user_model.dart';
import '../models/location_model.dart';
import '../models/session_model.dart';
import '../models/attendance_model.dart';
import '../models/class_model.dart';
import 'mock_data_service.dart';

class AuthService {
  final http.Client _client = LoggedClient();
  final MockDataService _mock = MockDataService();
  final bool useMock = false; // Flag pour basculer entre Mock et API

  // Demander la réinitialisation du mot de passe
  Future<bool> forgotPassword(String email) async {
    if (useMock) {
      await Future.delayed(const Duration(seconds: 1));
      AppUtils.showSuccessToast("Email de réinitialisation envoyé (Mode Mock)");
      return true;
    }
    try {
      final response = await _client.post(
        Uri.parse(ApiEndpoints.forgotPassword),
        headers: ApiEndpoints.getHeaders(),
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final message = data['message'] ?? 
            "Un email de réinitialisation a été envoyé à votre adresse.";
        AppUtils.showSuccessToast(message);
        return true;
      } else {
        print('Forgot password failed [${response.statusCode}]: ${response.body}');
        try {
          final errorData = jsonDecode(response.body);
          final errorMsg = errorData['message'] ?? 
              errorData['error'] ?? 
              "Erreur lors de la demande de réinitialisation";
          AppUtils.showErrorToast(errorMsg);
        } catch (_) {
          AppUtils.showErrorToast("Erreur serveur (${response.statusCode})");
        }
        return false;
      }
    } catch (e) {
      print('Forgot password error: $e');
      AppUtils.handleError(e);
      return false;
    }
  }

  // Réinitialiser le mot de passe avec un token
  Future<bool> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    if (useMock) {
      await Future.delayed(const Duration(seconds: 1));
      AppUtils.showSuccessToast("Mot de passe réinitialisé (Mode Mock)");
      return true;
    }
    try {
      final response = await _client.post(
        Uri.parse(ApiEndpoints.resetPassword),
        headers: ApiEndpoints.getHeaders(),
        body: jsonEncode({
          'token': token,
          'password': newPassword,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final message = data['message'] ?? 
            "Votre mot de passe a été réinitialisé avec succès.";
        AppUtils.showSuccessToast(message);
        return true;
      } else {
        print('Reset password failed [${response.statusCode}]: ${response.body}');
        try {
          final errorData = jsonDecode(response.body);
          final errorMsg = errorData['message'] ?? 
              errorData['error'] ?? 
              "Erreur lors de la réinitialisation";
          AppUtils.showErrorToast(errorMsg);
        } catch (_) {
          AppUtils.showErrorToast("Erreur serveur (${response.statusCode})");
        }
        return false;
      }
    } catch (e) {
      print('Reset password error: $e');
      AppUtils.handleError(e);
      return false;
    }
  }

  Future<UserModel?> login(String email, String password) async {
    if (useMock) {
      await Future.delayed(const Duration(seconds: 1)); // Simulation délai
      try {
        return _mock.users.firstWhere((u) => u.email == email);
      } catch (_) {
        return null;
      }
    }
    try {
      final response = await _client.post(
        Uri.parse(ApiEndpoints.login),
        headers: ApiEndpoints.getHeaders(),
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final userObj = Map<String, dynamic>.from(
          data['data'] ?? data['user'] ?? data,
        );
        if ((userObj['id'] == null || userObj['id'] == '') &&
            data['id'] != null) {
          userObj['id'] = data['id'];
        }
        return UserModel.fromJson(userObj);
      } else {
        // Gérer les erreurs HTTP explicitement
        print('Login failed [${response.statusCode}]: ${response.body}');
        try {
          final errorData = jsonDecode(response.body);
          final errorMsg =
              errorData['message'] ??
              errorData['error'] ??
              "Erreur de connexion (${response.statusCode})";
          AppUtils.showErrorToast(errorMsg);
        } catch (_) {
          AppUtils.showErrorToast("Erreur serveur (${response.statusCode})");
        }
        return null;
      }
    } catch (e) {
      print('Login error: $e');
      // Seulement appeler handleError si c'est vraiment une erreur de connexion
      AppUtils.handleError(e);
      return null;
    }
  }

  // Auto-inscription étudiant
  Future<UserModel?> registerStudent({
    required String nom,
    required String prenom,
    required String email,
    required String password,
    required String matricule,
    required String classeId,
    required String niveau,
    required String parcours,
  }) async {
    if (useMock) {
      await Future.delayed(const Duration(seconds: 1));
      final newUser = UserModel(
        id: "new-user-${DateTime.now().millisecondsSinceEpoch}",
        nom: nom,
        prenom: prenom,
        email: email,
        role: UserRole.ETUDIANT,
        matricule: matricule,
        classeId: classeId,
        niveau: niveau,
        parcours: parcours,
      );
      _mock.users.add(newUser);
      AppUtils.showSuccessToast("Inscription réussie (Mode Mock)");
      return newUser;
    }
    try {
      final deviceId = await DeviceManager.getDeviceId();
      final body = {
        'nom': nom,
        'prenom': prenom,
        'email': email,
        'password': password,
        'matricule': matricule,
        'classe_id': classeId,
        'niveau': niveau,
        'parcours': parcours,
        'role': 'ETUDIANT',
        'device_id': deviceId,
      };

      print(
        '📤 Envoi de la requête d\'inscription vers: ${ApiEndpoints.register}',
      );
      print('📋 Données envoyées: $body');

      final response = await _client.post(
        Uri.parse(ApiEndpoints.register),
        headers: ApiEndpoints.getHeaders(),
        body: jsonEncode(body),
      );

      print('📥 Réponse reçue [${response.statusCode}]: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Si le backend renvoie un champ 'success': false même avec un code 200/201
        if (data is Map && data['success'] == false) {
          final errorMsg = data['message'] ?? "L'inscription a échoué";
          print('❌ Erreur d\'inscription: $errorMsg');
          AppUtils.showErrorToast(errorMsg);
          return null;
        }

        final userObj = Map<String, dynamic>.from(
          data['data'] ?? data['user'] ?? data,
        );
        if ((userObj['id'] == null || userObj['id'] == '') &&
            data['id'] != null) {
          userObj['id'] = data['id'];
        }

        print('✅ Inscription réussie pour: ${userObj['email']}');
        // Ne pas afficher le toast ici car il sera géré dans le controller
        return UserModel.fromJson(userObj);
      } else {
        print(
          '❌ Échec de l\'inscription [${response.statusCode}]: ${response.body}',
        );

        try {
          final errorData = jsonDecode(response.body);
          final errorMsg =
              errorData['message'] ??
              errorData['error'] ??
              "Erreur serveur (${response.statusCode})";
          print('❌ Message d\'erreur: $errorMsg');
          AppUtils.showErrorToast(errorMsg);
        } catch (_) {
          final errorMsg = "Erreur serveur (${response.statusCode})";
          print('❌ Erreur de parsing: $errorMsg');
          AppUtils.showErrorToast(errorMsg);
        }
        return null;
      }
    } catch (e) {
      print('Registration error: $e');
      AppUtils.handleError(e);
      return null;
    }
  }

  Future<UserModel?> getProfile(String token) async {
    if (useMock) {
      return _mock.users[0]; // Retourne l'admin par défaut en mock
    }
    try {
      final response = await _client.get(
        Uri.parse(ApiEndpoints.me),
        headers: ApiEndpoints.getHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final userObj = data['data'] ?? data['user'] ?? data;
        return UserModel.fromJson(userObj);
      } else {
        print('GetProfile failed [${response.statusCode}]: ${response.body}');
        // Ne pas afficher d'erreur pour getProfile car c'est appelé au démarrage
        return null;
      }
    } catch (e) {
      print('GetProfile error: $e');
      AppUtils.handleError(e);
      return null;
    }
  }

  Future<List<UserModel>> getUsers() async {
    if (useMock) {
      return _mock.users;
    }
    try {
      final token = await _getToken();
      print('📤 Fetching users from: ${ApiEndpoints.users}');
      final response = await _client.get(
        Uri.parse(ApiEndpoints.users),
        headers: ApiEndpoints.getHeaders(token),
      );

      print('📥 Users response [${response.statusCode}]');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List list = data['data'] ?? data['users'] ?? [];
        print('✅ Users fetched: ${list.length}');
        return list.map((item) => UserModel.fromJson(item)).toList();
      } else {
        print(
          '❌ Error fetching users [${response.statusCode}]: ${response.body}',
        );
        return [];
      }
    } catch (e) {
      print('❌ Error fetching users: $e');
      return [];
    }
  }

  /// Récupérer les étudiants d'une classe spécifique
  /// Récupère tous les utilisateurs via /users et filtre côté frontend
  Future<List<UserModel>> getStudentsByClass(String classId) async {
    if (useMock) {
      return _mock.users
          .where((u) => u.role == UserRole.ETUDIANT && u.classeId == classId)
          .toList();
    }
    try {
      print('📤 Récupération des étudiants pour la classe: $classId');
      // Récupérer tous les utilisateurs via /users
      final allUsers = await getUsers();

      // Filtrer côté frontend : étudiants de la classe spécifiée
      final students =
          allUsers
              .where(
                (u) => u.role == UserRole.ETUDIANT && u.classeId == classId,
              )
              .toList();

      print('✅ Étudiants trouvés pour la classe $classId: ${students.length}');
      return students;
    } catch (e) {
      print('❌ Erreur lors de la récupération des étudiants par classe: $e');
      AppUtils.handleError(e);
      return [];
    }
  }

  Future<bool> addUser(UserModel user) async {
    if (useMock) {
      _mock.users.add(user);
      return true;
    }
    try {
      final token = await _getToken();
      final response = await _client.post(
        Uri.parse(ApiEndpoints.users),
        headers: ApiEndpoints.getHeaders(token),
        body: jsonEncode(user.toJson()),
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        print('Error adding user [${response.statusCode}]: ${response.body}');
        try {
          final errorData = jsonDecode(response.body);
          final errorMsg =
              errorData['message'] ?? errorData['error'] ?? 'Erreur serveur';
          AppUtils.showErrorToast(errorMsg);
        } catch (_) {
          AppUtils.showErrorToast("Erreur serveur (${response.statusCode})");
        }
        return false;
      }
    } catch (e) {
      print('Error adding user: $e');
      AppUtils.handleError(e);
      return false;
    }
  }

  Future<bool> updateUser(UserModel user) async {
    if (useMock) {
      final index = _mock.users.indexWhere((u) => u.id == user.id);
      if (index != -1) {
        _mock.users[index] = user;
        return true;
      }
      return false;
    }
    try {
      final token = await _getToken();
      final response = await _client.patch(
        Uri.parse(ApiEndpoints.userById(user.id)),
        headers: ApiEndpoints.getHeaders(token),
        body: jsonEncode(user.toJson()),
      );
      if (response.statusCode == 200) {
        return true;
      } else {
        print('Error updating user [${response.statusCode}]: ${response.body}');
        try {
          final errorData = jsonDecode(response.body);
          final errorMsg =
              errorData['message'] ?? errorData['error'] ?? 'Erreur serveur';
          AppUtils.showErrorToast(errorMsg);
        } catch (_) {
          AppUtils.showErrorToast("Erreur serveur (${response.statusCode})");
        }
        return false;
      }
    } catch (e) {
      print('Error updating user: $e');
      AppUtils.handleError(e);
      return false;
    }
  }

  Future<bool> deleteUser(String id) async {
    if (useMock) {
      _mock.users.removeWhere((u) => u.id == id);
      return true;
    }
    try {
      final token = await _getToken();
      final response = await _client.delete(
        Uri.parse(ApiEndpoints.userById(id)),
        headers: ApiEndpoints.getHeaders(token),
      );
      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        print('Error deleting user [${response.statusCode}]: ${response.body}');
        try {
          final errorData = jsonDecode(response.body);
          final errorMsg =
              errorData['message'] ?? errorData['error'] ?? 'Erreur serveur';
          AppUtils.showErrorToast(errorMsg);
        } catch (_) {
          AppUtils.showErrorToast("Erreur serveur (${response.statusCode})");
        }
        return false;
      }
    } catch (e) {
      print('Error deleting user: $e');
      AppUtils.handleError(e);
      return false;
    }
  }

  Future<bool> addLocation(LocationModel location) async {
    if (useMock) {
      _mock.locations.add(location);
      return true;
    }
    try {
      final token = await _getToken();
      final response = await _client.post(
        Uri.parse(ApiEndpoints.locations),
        headers: ApiEndpoints.getHeaders(token),
        body: jsonEncode(location.toJson()),
      );
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print('Error adding location: $e');
      AppUtils.handleError(e);
      return false;
    }
  }

  Future<bool> updateLocation(LocationModel location) async {
    if (useMock) {
      final index = _mock.locations.indexWhere((l) => l.id == location.id);
      if (index != -1) {
        _mock.locations[index] = location;
        return true;
      }
      return false;
    }
    try {
      final token = await _getToken();
      final response = await _client.patch(
        Uri.parse(ApiEndpoints.locationById(location.id)),
        headers: ApiEndpoints.getHeaders(token),
        body: jsonEncode(location.toJson()),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error updating location: $e');
      AppUtils.handleError(e);
      return false;
    }
  }

  Future<bool> deleteLocation(String id) async {
    if (useMock) {
      _mock.locations.removeWhere((l) => l.id == id);
      return true;
    }
    try {
      final token = await _getToken();
      final response = await _client.delete(
        Uri.parse(ApiEndpoints.locationById(id)),
        headers: ApiEndpoints.getHeaders(token),
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('Error deleting location: $e');
      AppUtils.handleError(e);
      return false;
    }
  }

  Future<List<LocationModel>> getLocations() async {
    if (useMock) {
      return _mock.locations;
    }
    try {
      final token = await _getToken();
      final response = await _client.get(
        Uri.parse(ApiEndpoints.locations),
        headers: ApiEndpoints.getHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List list = data['data'] ?? data['locations'] ?? [];
        return list.map((item) => LocationModel.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching locations: $e');
      AppUtils.handleError(e);
      return [];
    }
  }

  /// Récupère le QR Code d'un lieu (peut être une URL d'image ou des données JSON)
  Future<String?> getLocationQRCode(String locationId) async {
    if (useMock) {
      // En mode mock, retourner l'ID du lieu comme QR Code
      return jsonEncode({'locationId': locationId, 'type': 'location_qr'});
    }
    try {
      final token = await _getToken();
      final response = await _client.get(
        Uri.parse(ApiEndpoints.locationQRCode(locationId)),
        headers: ApiEndpoints.getHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Le backend peut retourner soit une URL d'image, soit des données JSON
        if (data['qr_code'] != null) {
          return data['qr_code'].toString();
        } else if (data['data'] != null) {
          return data['data'].toString();
        } else {
          // Si le backend ne retourne rien, générer un QR Code basé sur l'ID
          return jsonEncode({'locationId': locationId, 'type': 'location_qr'});
        }
      }
      // Fallback: générer un QR Code basé sur l'ID
      return jsonEncode({'locationId': locationId, 'type': 'location_qr'});
    } catch (e) {
      print('Error fetching location QR code: $e');
      // En cas d'erreur, retourner quand même un QR Code basé sur l'ID
      return jsonEncode({'locationId': locationId, 'type': 'location_qr'});
    }
  }

  Future<List<ClassModel>> getClasses() async {
    if (useMock) {
      // Return some mock classes
      return [
        ClassModel(
          id: "c1",
          nom: "Licence 3 - Génie Logiciel",
          niveau: '',
          parcours: '',
        ),
        ClassModel(
          id: "c2",
          nom: "Master 1 - Cybersécurité",
          niveau: '',
          parcours: '',
        ),
        ClassModel(
          id: "c3",
          nom: "Licence 2 - Réseaux et Télécoms",
          niveau: '',
          parcours: '',
        ),
      ];
    }
    try {
      // Essayer d'abord avec un token si disponible
      final token = await _getToken();
      print(
        '🔑 Token disponible pour getClasses: ${token != null ? "Oui" : "Non"}',
      );

      http.Response response;

      // Essayer avec token d'abord
      if (token != null) {
        response = await _client.get(
          Uri.parse(ApiEndpoints.classes),
          headers: ApiEndpoints.getHeaders(token),
        );
      } else {
        // Si pas de token, essayer sans token (pour l'inscription)
        print('⚠️ Pas de token, tentative sans authentification');
        response = await _client.get(
          Uri.parse(ApiEndpoints.classes),
          headers: ApiEndpoints.getHeaders(),
        );
      }

      final responseBody = response.body;
      print('📥 Réponse classes [${response.statusCode}]');
      print(
        '📄 Body (premiers 500 chars): ${responseBody.length > 500 ? responseBody.substring(0, 500) + "..." : responseBody}',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);

        // Gérer le format de réponse avec 'data' ou directement un tableau
        List list = [];
        if (data is Map) {
          if (data['data'] != null) {
            list = data['data'] is List ? data['data'] : [];
            print('📋 Classes trouvées dans data.data: ${list.length}');
          } else if (data['classes'] != null) {
            list = data['classes'] is List ? data['classes'] : [];
            print('📋 Classes trouvées dans data.classes: ${list.length}');
          } else {
            print(
              '⚠️ Structure de réponse inattendue. Clés: ${data.keys.toList()}',
            );
          }
        } else if (data is List) {
          list = data;
          print(
            '📋 Classes trouvées directement dans la liste: ${list.length}',
          );
        }

        if (list.isEmpty) {
          print('⚠️ Aucune classe dans la réponse');
          if (data is Map) {
            print('⚠️ Structure complète: $data');
          }
          return [];
        }

        final classes = <ClassModel>[];
        for (var item in list) {
          try {
            if (item is Map<String, dynamic>) {
              final classModel = ClassModel.fromJson(item);
              print(
                '✅ Classe parsée: ${classModel.nom} (id: ${classModel.id}, niveau: ${classModel.niveau})',
              );
              classes.add(classModel);
            } else {
              print('⚠️ Item n\'est pas un Map: ${item.runtimeType}');
            }
          } catch (e) {
            print('❌ Erreur parsing classe: $item - $e');
          }
        }

        print('✅ Total classes parsées avec succès: ${classes.length}');
        return classes;
      } else {
        print(
          '❌ Échec récupération classes [${response.statusCode}]: $responseBody',
        );
        try {
          final errorData = jsonDecode(responseBody);
          final errorMsg =
              errorData['message'] ?? errorData['error'] ?? 'Erreur inconnue';
          print('❌ Message d\'erreur: $errorMsg');
          if (response.statusCode == 401 || response.statusCode == 403) {
            // Ne pas afficher d'erreur si c'est juste une question d'authentification
            // Le cache sera utilisé à la place
            print(
              '⚠️ Authentification requise, utilisation du cache si disponible',
            );
          } else {
            AppUtils.showErrorToast(errorMsg);
          }
        } catch (_) {
          print('⚠️ Erreur de parsing de la réponse d\'erreur');
        }
        return [];
      }
    } catch (e) {
      print('❌ Erreur lors de la récupération des classes: $e');
      AppUtils.handleError(e);
      return [];
    }
  }

  Future<bool> addClass(ClassModel classe) async {
    if (useMock) {
      _mock.classes.add(classe);
      return true;
    }
    try {
      final token = await _getToken();
      final response = await _client.post(
        Uri.parse(ApiEndpoints.classes),
        headers: ApiEndpoints.getHeaders(token),
        body: jsonEncode(classe.toJson()),
      );
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print('Error adding class: $e');
      AppUtils.handleError(e);
      return false;
    }
  }

  Future<bool> updateClass(ClassModel classe) async {
    if (useMock) {
      final index = _mock.classes.indexWhere((c) => c.id == classe.id);
      if (index != -1) {
        _mock.classes[index] = classe;
        return true;
      }
      return false;
    }
    try {
      final token = await _getToken();
      final response = await _client.patch(
        Uri.parse(ApiEndpoints.classById(classe.id)),
        headers: ApiEndpoints.getHeaders(token),
        body: jsonEncode(classe.toJson()),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error updating class: $e');
      AppUtils.handleError(e);
      return false;
    }
  }

  Future<bool> deleteClass(String id) async {
    if (useMock) {
      _mock.classes.removeWhere((c) => c.id == id);
      return true;
    }
    try {
      final token = await _getToken();
      final response = await _client.delete(
        Uri.parse(ApiEndpoints.classById(id)),
        headers: ApiEndpoints.getHeaders(token),
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('Error deleting class: $e');
      AppUtils.handleError(e);
      return false;
    }
  }

  // --- NOUVELLES METHODES CAHIER DES CHARGES ---

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<List<SessionModel>> getSessions() async {
    if (useMock) {
      return _mock.sessions;
    }
    try {
      final token = await _getToken();
      final response = await _client.get(
        Uri.parse(ApiEndpoints.sessions),
        headers: ApiEndpoints.getHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List list = data['data'] ?? data['sessions'] ?? [];
        final sessions = <SessionModel>[];
        for (var item in list) {
          try {
            final session = SessionModel.fromJson(item);
            // Debug: afficher les horaires récupérés
            if (session.heureDebut != null && session.heureFin != null) {
              print(
                '✅ Session ${session.matiere}: ${session.heureDebut} - ${session.heureFin}',
              );
            } else {
              print('⚠️ Session ${session.matiere}: horaires manquants');
              print(
                '   Raw data: ${item['heure_debut']} - ${item['heure_fin']}',
              );
            }
            sessions.add(session);
          } catch (e) {
            print('❌ Erreur parsing session: $e');
            print('   Raw item: $item');
          }
        }
        return sessions;
      }
      return [];
    } catch (e) {
      print('Error fetching sessions: $e');
      AppUtils.handleError(e);
      return [];
    }
  }

  Future<bool> createSession(SessionModel session) async {
    if (useMock) {
      _mock.sessions.add(session);
      return true;
    }
    try {
      final token = await _getToken();

      // Préparer le JSON avec le format attendu par l'API
      // Le backend attend 'classe_id' (une seule classe)
      // On envoie la première classe sélectionnée
      final Map<String, dynamic> sessionJson = {
        'matiere': session.matiere,
        'enseignant_id': session.enseignantId,
        'lieu_id': session.lieuId,
        'classe_id':
            session.classeIds.isNotEmpty ? session.classeIds.first : '',
        'mode': session.mode.name,
        'marge_tolerance': session.margeTolerance,
        if (session.qrCode != null) 'qr_code': session.qrCode,
      };

      // Formater les horaires selon le format attendu par l'API
      if (session.heureDebut != null && session.heureFin != null) {
        final dateDebut = session.heureDebut!;
        final dateFin = session.heureFin!;

        sessionJson['date_seance'] =
            '${dateDebut.year}-${dateDebut.month.toString().padLeft(2, '0')}-${dateDebut.day.toString().padLeft(2, '0')}';

        sessionJson['heure_debut'] =
            '${dateDebut.year}-${dateDebut.month.toString().padLeft(2, '0')}-${dateDebut.day.toString().padLeft(2, '0')} '
            '${dateDebut.hour.toString().padLeft(2, '0')}:${dateDebut.minute.toString().padLeft(2, '0')}:00';

        sessionJson['heure_fin'] =
            '${dateFin.year}-${dateFin.month.toString().padLeft(2, '0')}-${dateFin.day.toString().padLeft(2, '0')} '
            '${dateFin.hour.toString().padLeft(2, '0')}:${dateFin.minute.toString().padLeft(2, '0')}:00';

        print('📅 Date séance: ${sessionJson['date_seance']}');
        print('⏰ Heure début: ${sessionJson['heure_debut']}');
        print('⏰ Heure fin: ${sessionJson['heure_fin']}');
      } else {
        print('⚠️ ATTENTION: Les horaires sont null !');
      }

      print('📤 Création session: ${session.matiere}');
      print('   JSON envoyé: ${jsonEncode(sessionJson)}');

      final response = await _client.post(
        Uri.parse(ApiEndpoints.sessions),
        headers: ApiEndpoints.getHeaders(token),
        body: jsonEncode(sessionJson),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        print('✅ Session créée avec succès');
        return true;
      } else {
        print(
          '❌ Erreur création session [${response.statusCode}]: ${response.body}',
        );
        try {
          final errorData = jsonDecode(response.body);
          final errorMsg =
              errorData['message'] ??
              errorData['error'] ??
              'Erreur serveur (${response.statusCode})';
          AppUtils.showErrorToast(errorMsg);
        } catch (_) {
          AppUtils.showErrorToast('Erreur serveur (${response.statusCode})');
        }
        return false;
      }
    } catch (e) {
      print('Error creating session: $e');
      AppUtils.handleError(e);
      return false;
    }
  }

  Future<List<AttendanceModel>> getAttendanceForSession(
    String sessionId,
  ) async {
    if (useMock) {
      return _mock.attendances.where((a) => a.sessionId == sessionId).toList();
    }
    try {
      final token = await _getToken();
      final response = await _client.get(
        Uri.parse(ApiEndpoints.attendanceBySession(sessionId)),
        headers: ApiEndpoints.getHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List list = data['data'] ?? data['attendances'] ?? [];
        return list.map((item) => AttendanceModel.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching attendance for session: $e');
      AppUtils.handleError(e);
      return [];
    }
  }

  Future<List<AttendanceModel>> getAttendanceForStudent(
    String etudiantId,
  ) async {
    if (useMock) {
      return _mock.attendances
          .where((a) => a.etudiantId == etudiantId)
          .toList();
    }
    try {
      final token = await _getToken();
      final response = await _client.get(
        Uri.parse(ApiEndpoints.attendanceByStudent(etudiantId)),
        headers: ApiEndpoints.getHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List list = data['data'] ?? data['attendances'] ?? [];
        return list.map((item) => AttendanceModel.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching attendance for student: $e');
      AppUtils.handleError(e);
      return [];
    }
  }

  Future<bool> markAttendance(AttendanceModel attendance) async {
    if (useMock) {
      _mock.attendances.add(attendance);
      AppUtils.showSuccessToast("Présence enregistrée ! (MODE MOCK)");
      return true;
    }
    try {
      final token = await _getToken();
      final body = attendance.toJson();

      print('📤 Envoi de présence vers: ${ApiEndpoints.attendanceMark}');
      print('📋 Données envoyées: $body');

      final response = await _client.post(
        Uri.parse(ApiEndpoints.attendanceMark),
        headers: ApiEndpoints.getHeaders(token),
        body: jsonEncode(body),
      );

      print('📥 Réponse marquage [${response.statusCode}]: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        AppUtils.showSuccessToast("Présence enregistrée !");
        return true;
      } else {
        final data = jsonDecode(response.body);
        print('❌ Échec marquage: ${data['message'] ?? 'Erreur inconnue'}');
        AppUtils.showErrorToast(data['message'] ?? "Erreur lors du marquage");
        return false;
      }
    } catch (e) {
      print('❌ Erreur critique lors du marquage: $e');
      AppUtils.handleError(e);
      return false;
    }
  }

  Future<bool> updateSessionStatus(
    String sessionId,
    SessionStatus status,
  ) async {
    if (useMock) return true;
    try {
      final token = await _getToken();
      final response = await _client.patch(
        Uri.parse(ApiEndpoints.sessionStatus(sessionId)),
        headers: ApiEndpoints.getHeaders(token),
        body: jsonEncode({'statut': status.name}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error updating session status: $e');
      return false;
    }
  }
}

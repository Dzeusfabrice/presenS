⏱️ PresenS - Système de Gestion de Présence

PresenS est une solution mobile révolutionnaire conçue pour moderniser le suivi de présence dans les établissements éducatifs et les entreprises. Fini les feuilles d’émargement papier : PresenS utilise le QR Code spatial et la Géolocalisation pour garantir une présence réelle et infalsifiable.

🌟 Pourquoi PresenS ?

La gestion traditionnelle des présences est souvent lente, sujette aux erreurs et facile à contourner. PresenS répond à ces problématiques par :

Rapidité : Un scan de moins de 2 secondes suffit.
Fiabilité : Vérification de la position GPS en temps réel.
Transparence : Données accessibles instantanément pour les administrateurs et les étudiants.
Éco-responsable : Zéro papier.
🛠️ Fonctionnalités Détaillées
🎓 Module Étudiant
Scan & Go : Scanner le QR Code de la session pour marquer sa présence.
Auto-Validation : Vérification automatique de la proximité avec le lieu du cours.
Dashboard d’Assiduité : Visualisation claire du taux de présence par matière.
Historique : Liste complète des présences et absences passées.
Notifications : Alertes pour les sessions à venir et rappels importants.
👨‍🏫 Module Enseignant
Gestion de Session : Création dynamique de sessions de cours (Matière, Salle, Mode).
QR Code Dynamique : Génération d’un code unique pour chaque session.
Appel GPS : Possibilité de déclencher un signal GPS pour valider tous les étudiants présents dans la zone.
Monitoring en Direct : Liste des étudiants présents mise à jour en temps réel.
Récapitulatifs : Visualisation des statistiques de la session immédiatement après la fin.
🏛️ Module Administration
Pilotage Global : Gestion des utilisateurs (étudiants, enseignants) et des salles/lieux.
Exports Multi-Formats : Génération de rapports en PDF, Excel et CSV.
Analyses Décisionnelles : Statistiques avancées sur l’assiduité globale de l’établissement.
Filtres Avancés : Recherche par classe, par séance ou par étudiant spécifique.
📱 Aperçus de l’Application

(Note : Remplacez par vos propres captures d’écran dans le dossier assets/screenshots)

Connexion & Accueil	Scan QR Code	Dashboard Admin

	
	
🏗️ Architecture Technique

Le projet suit une architecture propre et modulaire basée sur GetX :

lib/
├── core/             # Thèmes, constantes, utilitaires et API
├── controllers/      # Logique métier (GetX Controllers)
├── models/           # Modèles de données (JSON mapping)
├── services/         # Services API et persistence
├── views/            # Interfaces UI (Admin, Teacher, Student)
└── main.dart         # Point d'entrée et routes
Stack Technologique
Mobile : Flutter & Dart
State Management : GetX (simple, puissant et performant)
Scanner : mobile_scanner pour une lecture ultra-rapide
Cartographie : flutter_map (OpenStreetMap)
Stockage : shared_preferences
Réseau : Communication REST via http
⚙️ Installation & Lancement
Prérequis
Flutter SDK ^3.7.2
Un éditeur (VS Code ou Android Studio)
Caméra fonctionnelle (pour le scan) et GPS activé
Guide Rapide
Clonage : git clone https://github.com/votre-username/presens.git
Dépendances : flutter pub get
Exécution : flutter run
📊 Roadmap & Futur
 Mode hors ligne (synchronisation ultérieure)
 Reconnaissance faciale (optionnel)
 Intégration directe avec les plateformes LMS (Moodle/Canvas)
 Application Web pour les administrateurs
🤝 L’Équipe

Développé par le Groupe 14 avec la passion de transformer l’expérience académique.

© 2026 PresenS - Tous droits réservés.
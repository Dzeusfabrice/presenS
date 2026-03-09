import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/location_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../models/location_model.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/utils/app_utils.dart';
import 'location_detail_view.dart';
import 'dart:math' as math;

class LocationManagementView extends StatefulWidget {
  const LocationManagementView({Key? key}) : super(key: key);

  @override
  State<LocationManagementView> createState() => _LocationManagementViewState();
}

class _LocationManagementViewState extends State<LocationManagementView> {
  LocationModel? _selectedLocation;
  bool _isMapView = true; // true = carte, false = liste

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LocationController());

    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      appBar: AppBar(
        title: const Text(
          "Gestion des Lieux",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        foregroundColor: AppColors.cardBackground,
        actions: [
          // Toggle vue Carte/Liste
          IconButton(
            icon: Icon(_isMapView ? Icons.list_rounded : Icons.map_rounded),
            onPressed: () {
              setState(() {
                _isMapView = !_isMapView;
                _selectedLocation = null;
              });
            },
            tooltip: _isMapView ? "Vue Liste" : "Vue Carte",
          ),
          IconButton(
            icon: const Icon(Icons.add_location_alt_rounded),
            onPressed: () => _showLocationForm(context, controller),
            tooltip: "Ajouter un lieu",
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.locations.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.locations.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.location_off_rounded,
                  size: 64,
                  color: AppColors.grey300,
                ),
                const SizedBox(height: 16),
                Text(
                  "Aucun lieu ou salle trouvé",
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => _showLocationForm(context, controller),
                  icon: const Icon(Icons.add_location_alt_rounded),
                  label: const Text("Ajouter un lieu"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.cardBackground,
                  ),
                ),
              ],
            ),
          );
        }

        // Calculer le centre de la carte basé sur les lieux
        final locationsWithCoords =
            controller.locations
                .where((loc) => loc.latitude != null && loc.longitude != null)
                .toList();

        if (locationsWithCoords.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.map_outlined, size: 64, color: AppColors.grey300),
                const SizedBox(height: 16),
                Text(
                  "Aucun lieu avec coordonnées GPS",
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => _showLocationForm(context, controller),
                  icon: const Icon(Icons.add_location_alt_rounded),
                  label: const Text("Ajouter un lieu"),
                ),
              ],
            ),
          );
        }

        // Afficher la vue carte ou liste selon le toggle
        if (_isMapView) {
          return Stack(
            children: [
              // Fond de carte stylisé
              _buildMapBackground(),

              // Marqueurs des lieux positionnés sur la carte
              ..._buildLocationMarkers(controller.locations, context),

              // Panel de détails en bas (si un lieu est sélectionné)
              if (_selectedLocation != null)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _buildLocationInfoPanel(
                    _selectedLocation!,
                    controller,
                  ),
                ),
            ],
          );
        } else {
          // Vue liste moderne
          return _buildListView(controller.locations, controller);
        }
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showLocationForm(context, controller),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_location_alt_rounded, color: Colors.white),
      ),
    );
  }

  // Créer un fond qui ressemble à une carte
  Widget _buildMapBackground() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD), // Fond bleu clair comme une carte
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFE3F2FD), // Bleu très clair
            const Color(0xFFBBDEFB), // Bleu clair
            const Color(0xFF90CAF9), // Bleu moyen clair
            const Color(0xFF64B5F6), // Bleu moyen
          ],
        ),
      ),
      child: CustomPaint(painter: _MapStylePainter(), child: Container()),
    );
  }

  // Créer les marqueurs positionnés sur la carte
  List<Widget> _buildLocationMarkers(
    List<LocationModel> locations,
    BuildContext context,
  ) {
    if (locations.isEmpty) return [];

    // Calculer des positions aléatoires mais cohérentes pour chaque lieu
    final random = math.Random(42); // Seed fixe pour positions cohérentes
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return locations.asMap().entries.map((entry) {
      final index = entry.key;
      final location = entry.value;
      final isSelected = _selectedLocation?.id == location.id;

      // Position aléatoire mais cohérente basée sur l'index
      final x = (screenWidth * 0.1) + (random.nextDouble() * screenWidth * 0.8);
      final y =
          (screenHeight * 0.15) + (random.nextDouble() * screenHeight * 0.6);

      return Positioned(
        left: x - 75, // Centrer le marqueur
        top: y - 40,
        child: GestureDetector(
          onTap: () {
            setState(() {
              _selectedLocation = location;
            });
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Nom du lieu - toujours visible
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                  border: Border.all(
                    color:
                        isSelected
                            ? AppColors.primary
                            : AppColors.primary.withOpacity(0.6),
                    width: isSelected ? 2.5 : 2,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Numéro du marqueur
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : AppColors.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        "${index + 1}",
                        style: TextStyle(
                          color: isSelected ? AppColors.primary : Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Nom du bâtiment
                    Text(
                      location.buildingName,
                      style: TextStyle(
                        color:
                            isSelected ? Colors.white : AppColors.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Numéro de salle
                    Text(
                      "Salle ${location.roomNumber}",
                      style: TextStyle(
                        color:
                            isSelected
                                ? Colors.white.withOpacity(0.9)
                                : AppColors.textSecondary,
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              // Icône de marqueur
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.5),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.location_on_rounded,
                  color: isSelected ? Colors.white : AppColors.primary,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  // Vue liste moderne avec plusieurs styles proposés
  Widget _buildListView(
    List<LocationModel> locations,
    LocationController controller,
  ) {
    return Column(
      children: [
        // En-tête avec statistiques
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.location_city_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${locations.length} Lieu${locations.length > 1 ? 'x' : ''}",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      "Salles et bâtiments",
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Liste des lieux
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: locations.length,
            itemBuilder: (context, index) {
              final location = locations[index];
              return _buildLocationListCard(location, controller, index);
            },
          ),
        ),
      ],
    );
  }

  // Carte de lieu pour la vue liste - Style uniforme et sobre
  Widget _buildLocationListCard(
    LocationModel location,
    LocationController controller,
    int index,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Get.to(() => LocationDetailView(location: location));
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Numéro et icône
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "${index + 1}",
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Icon(
                        Icons.location_on_rounded,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Informations
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        location.buildingName,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.meeting_room_rounded,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "Salle ${location.roomNumber}",
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      if (location.latitude != null &&
                          location.longitude != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.gps_fixed_rounded,
                              size: 12,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                "${location.latitude!.toStringAsFixed(4)}, ${location.longitude!.toStringAsFixed(4)}",
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                // Actions rapides
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.primary,
                      ),
                      onPressed: () {
                        Get.to(() => LocationDetailView(location: location));
                      },
                      tooltip: "Détails",
                    ),
                    IconButton(
                      icon: Icon(Icons.edit_outlined, color: AppColors.primary),
                      onPressed: () {
                        _showLocationForm(
                          context,
                          controller,
                          location: location,
                        );
                      },
                      tooltip: "Modifier",
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationInfoPanel(
    LocationModel location,
    LocationController controller,
  ) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.grey300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            location.buildingName,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Salle ${location.roomNumber}",
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        setState(() {
                          _selectedLocation = null;
                        });
                      },
                    ),
                  ],
                ),
                if (location.latitude != null &&
                    location.longitude != null) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        Icons.gps_fixed_rounded,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "${location.latitude!.toStringAsFixed(6)}, ${location.longitude!.toStringAsFixed(6)}",
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
                if (location.radius != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.radar_rounded,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Rayon: ${location.radius!.toStringAsFixed(0)} mètres",
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Get.to(() => LocationDetailView(location: location));
                        },
                        icon: const Icon(Icons.info_outline_rounded),
                        label: const Text("Détails"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _showLocationForm(
                            context,
                            controller,
                            location: location,
                          );
                        },
                        icon: const Icon(Icons.edit_rounded),
                        label: const Text("Modifier"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.cardBackground,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLocationForm(
    BuildContext context,
    LocationController controller, {
    LocationModel? location,
  }) {
    final buildingController = TextEditingController(
      text: location?.buildingName,
    );
    final roomController = TextEditingController(text: location?.roomNumber);
    final latController = TextEditingController(
      text: location?.latitude?.toString(),
    );
    final lonController = TextEditingController(
      text: location?.longitude?.toString(),
    );
    final radiusController = TextEditingController(
      text: location?.radius?.toString(),
    );
    bool isLocating = false;

    Get.bottomSheet(
      isScrollControlled: true,
      Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.grey300,
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              location == null
                  ? "Ajouter une Salle/Lieu"
                  : "Modifier la Salle/Lieu",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildField(
                      buildingController,
                      "Nom du Bâtiment",
                      Icons.domain,
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      roomController,
                      "Numéro de Salle",
                      Icons.meeting_room_outlined,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(
                          Icons.gps_fixed_rounded,
                          color: Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Localisation",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    StatefulBuilder(
                      builder: (context, setBtnState) {
                        return SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed:
                                isLocating
                                    ? null
                                    : () async {
                                      setBtnState(() => isLocating = true);
                                      try {
                                        bool serviceEnabled =
                                            await Geolocator.isLocationServiceEnabled();
                                        if (!serviceEnabled) {
                                          AppUtils.showWarningToast(
                                            "Le service de localisation est désactivé.",
                                          );
                                          setBtnState(() => isLocating = false);
                                          return;
                                        }

                                        LocationPermission permission =
                                            await Geolocator.checkPermission();
                                        if (permission ==
                                            LocationPermission.denied) {
                                          permission =
                                              await Geolocator.requestPermission();
                                          if (permission ==
                                              LocationPermission.denied) {
                                            AppUtils.showWarningToast(
                                              "Permission de localisation refusée.",
                                            );
                                            setBtnState(
                                              () => isLocating = false,
                                            );
                                            return;
                                          }
                                        }

                                        if (permission ==
                                            LocationPermission.deniedForever) {
                                          AppUtils.showWarningToast(
                                            "Permission refusée définitivement.",
                                          );
                                          setBtnState(() => isLocating = false);
                                          return;
                                        }

                                        Position position =
                                            await Geolocator.getCurrentPosition(
                                              desiredAccuracy:
                                                  LocationAccuracy.high,
                                            );

                                        latController.text =
                                            position.latitude.toString();
                                        lonController.text =
                                            position.longitude.toString();
                                        AppUtils.showSuccessToast(
                                          "Coordonnées récupérées !",
                                        );
                                      } catch (e) {
                                        AppUtils.showErrorToast(
                                          "Erreur GPS : $e",
                                        );
                                      } finally {
                                        setBtnState(() => isLocating = false);
                                      }
                                    },
                            icon:
                                isLocating
                                    ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.orange,
                                      ),
                                    )
                                    : const Icon(
                                      Icons.my_location_rounded,
                                      size: 18,
                                      color: Colors.orange,
                                    ),
                            label: Text(
                              isLocating
                                  ? "Récupération..."
                                  : "Utiliser ma position actuelle",
                              style: const TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: const BorderSide(
                                color: Colors.orange,
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildField(
                            latController,
                            "Latitude",
                            Icons.south_rounded,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildField(
                            lonController,
                            "Longitude",
                            Icons.east_rounded,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      radiusController,
                      "Rayon de précision (mètres)",
                      Icons.radar_outlined,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () async {
                          if (controller.isLoading.value) return;
                          if (buildingController.text.isEmpty ||
                              roomController.text.isEmpty) {
                            Get.snackbar(
                              "Erreur",
                              "Le bâtiment et le numéro de salle sont requis.",
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: Colors.red.withOpacity(0.9),
                              colorText: Colors.white,
                            );
                            return;
                          }

                          final newLoc = LocationModel(
                            id:
                                location?.id ??
                                "loc-${DateTime.now().millisecondsSinceEpoch}",
                            buildingName: buildingController.text,
                            roomNumber: roomController.text,
                            latitude: double.tryParse(latController.text),
                            longitude: double.tryParse(lonController.text),
                            radius:
                                double.tryParse(radiusController.text) ?? 50.0,
                          );

                          bool success;
                          if (location == null) {
                            success = await controller.addLocation(newLoc);
                          } else {
                            success = await controller.updateLocation(newLoc);
                          }

                          if (success) {
                            Get.back();
                            setState(() {
                              _selectedLocation = null;
                            });
                          }
                        },
                        child: Obx(
                          () =>
                              controller.isLoading.value
                                  ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Text(
                                    "Enregistrer",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundGrey,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: AppColors.textSecondary.withOpacity(0.7),
            fontSize: 14,
          ),
          prefixIcon: Icon(
            icon,
            color: Colors.orange.withOpacity(0.7),
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 16,
          ),
        ),
      ),
    );
  }
}

// Peintre pour créer un style de carte
class _MapStylePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Lignes de grille avec variantes de bleu
    final paint1 =
        Paint()
          ..color = const Color(0xFF90CAF9).withOpacity(0.4)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;

    final paint2 =
        Paint()
          ..color = const Color(0xFF64B5F6).withOpacity(0.3)
          ..strokeWidth = 1.2
          ..style = PaintingStyle.stroke;

    final paint3 =
        Paint()
          ..color = const Color(0xFF42A5F5).withOpacity(0.25)
          ..strokeWidth = 1.0
          ..style = PaintingStyle.stroke;

    // Lignes de grille horizontales (comme des rues) avec variations
    for (double y = 0; y < size.height; y += 60) {
      final paint =
          (y / 60).toInt() % 3 == 0
              ? paint1
              : (y / 60).toInt() % 3 == 1
              ? paint2
              : paint3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Lignes de grille verticales (comme des rues) avec variations
    for (double x = 0; x < size.width; x += 60) {
      final paint =
          (x / 60).toInt() % 3 == 0
              ? paint1
              : (x / 60).toInt() % 3 == 1
              ? paint2
              : paint3;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Points d'intersection avec variantes de bleu
    final pointPaint1 =
        Paint()
          ..color = const Color(0xFF64B5F6).withOpacity(0.5)
          ..style = PaintingStyle.fill;

    final pointPaint2 =
        Paint()
          ..color = const Color(0xFF42A5F5).withOpacity(0.4)
          ..style = PaintingStyle.fill;

    final pointPaint3 =
        Paint()
          ..color = const Color(0xFF1E88E5).withOpacity(0.3)
          ..style = PaintingStyle.fill;

    for (double y = 0; y < size.height; y += 60) {
      for (double x = 0; x < size.width; x += 60) {
        final pointPaint =
            ((x / 60).toInt() + (y / 60).toInt()) % 3 == 0
                ? pointPaint1
                : ((x / 60).toInt() + (y / 60).toInt()) % 3 == 1
                ? pointPaint2
                : pointPaint3;
        canvas.drawCircle(Offset(x, y), 2, pointPaint);
      }
    }

    // Zones de bâtiments (rectangles) avec tons bleu-gris
    final buildingPaint1 =
        Paint()
          ..color = const Color(0xFF90CAF9).withOpacity(0.25)
          ..style = PaintingStyle.fill;

    final buildingPaint2 =
        Paint()
          ..color = const Color(0xFF64B5F6).withOpacity(0.2)
          ..style = PaintingStyle.fill;

    final buildingPaint3 =
        Paint()
          ..color = const Color(0xFF42A5F5).withOpacity(0.15)
          ..style = PaintingStyle.fill;

    final random = math.Random(42);
    for (int i = 0; i < 15; i++) {
      final buildingPaint =
          i % 3 == 0
              ? buildingPaint1
              : i % 3 == 1
              ? buildingPaint2
              : buildingPaint3;
      final rect = Rect.fromLTWH(
        random.nextDouble() * size.width * 0.8,
        random.nextDouble() * size.height * 0.8,
        random.nextDouble() * 80 + 40,
        random.nextDouble() * 80 + 40,
      );
      canvas.drawRect(rect, buildingPaint);
    }

    // Zones d'eau/parcs avec variantes de bleu
    final waterPaint1 =
        Paint()
          ..color = const Color(0xFF64B5F6).withOpacity(0.35)
          ..style = PaintingStyle.fill;

    final waterPaint2 =
        Paint()
          ..color = const Color(0xFF42A5F5).withOpacity(0.3)
          ..style = PaintingStyle.fill;

    final waterPaint3 =
        Paint()
          ..color = const Color(0xFF1E88E5).withOpacity(0.25)
          ..style = PaintingStyle.fill;

    for (int i = 0; i < 5; i++) {
      final waterPaint =
          i % 3 == 0
              ? waterPaint1
              : i % 3 == 1
              ? waterPaint2
              : waterPaint3;
      final rect = Rect.fromLTWH(
        random.nextDouble() * size.width * 0.7,
        random.nextDouble() * size.height * 0.7,
        random.nextDouble() * 120 + 60,
        random.nextDouble() * 120 + 60,
      );
      canvas.drawRect(rect, waterPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

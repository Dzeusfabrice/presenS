import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/location_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_modal.dart';
import '../../models/location_model.dart';

class LocationDetailView extends StatelessWidget {
  final LocationModel location;

  const LocationDetailView({
    Key? key,
    required this.location,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LocationController>();

    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      appBar: AppBar(
        title: Text(
          location.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.cardBackground,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              Get.back();
              _showLocationForm(context, controller, location: location);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            color: Colors.red,
            onPressed: () => _confirmDelete(context, location, controller),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Carte visuelle du lieu
            _buildLocationCard(),
            const SizedBox(height: 24),

            // Informations détaillées
            _buildSectionTitle("Informations"),
            const SizedBox(height: 12),
            _buildInfoCard(
              icon: Icons.domain_rounded,
              label: "Bâtiment",
              value: location.buildingName,
            ),
            const SizedBox(height: 12),
            _buildInfoCard(
              icon: Icons.meeting_room_rounded,
              label: "Salle",
              value: location.roomNumber,
            ),

            if (location.latitude != null && location.longitude != null) ...[
              const SizedBox(height: 24),
              _buildSectionTitle("Localisation GPS"),
              const SizedBox(height: 12),
              _buildInfoCard(
                icon: Icons.gps_fixed_rounded,
                label: "Latitude",
                value: location.latitude!.toStringAsFixed(6),
              ),
              const SizedBox(height: 12),
              _buildInfoCard(
                icon: Icons.gps_fixed_rounded,
                label: "Longitude",
                value: location.longitude!.toStringAsFixed(6),
              ),
            ],

            if (location.radius != null) ...[
              const SizedBox(height: 12),
              _buildInfoCard(
                icon: Icons.radar_rounded,
                label: "Rayon de précision",
                value: "${location.radius!.toStringAsFixed(0)} mètres",
              ),
            ],

            const SizedBox(height: 32),
            _buildActionButtons(context, controller),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primaryLight,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Pattern de fond
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image: const DecorationImage(
                    image: AssetImage('assets/images/map_pattern.png'),
                    repeat: ImageRepeat.repeat,
                    fit: BoxFit.none,
                  ),
                ),
              ),
            ),
          ),
          // Contenu
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_on_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        "LIEU DE COURS",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      location.buildingName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Salle ${location.roomNumber}",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: AppColors.textSecondary,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
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
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    LocationController controller,
  ) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: () {
              Get.back();
              _showLocationForm(context, controller, location: location);
            },
            icon: const Icon(Icons.edit_rounded),
            label: const Text(
              "Modifier",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton.icon(
            onPressed: () => _confirmDelete(context, location, controller),
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text(
              "Supprimer",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
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
              "Modifier le Lieu",
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
                    _buildTextField(
                      buildingController,
                      "Nom du Bâtiment",
                      Icons.domain,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      roomController,
                      "Numéro de Salle",
                      Icons.meeting_room_outlined,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      latController,
                      "Latitude",
                      Icons.south_rounded,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      lonController,
                      "Longitude",
                      Icons.east_rounded,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
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
                            AppModal.showError(
                              context: context,
                              title: "Erreur",
                              message:
                                  "Le bâtiment et le numéro de salle sont requis.",
                            );
                            return;
                          }

                          final updatedLoc = LocationModel(
                            id: location!.id,
                            buildingName: buildingController.text,
                            roomNumber: roomController.text,
                            latitude: double.tryParse(latController.text),
                            longitude: double.tryParse(lonController.text),
                            radius:
                                double.tryParse(radiusController.text) ?? 50.0,
                          );

                          final success =
                              await controller.updateLocation(updatedLoc);

                          if (success) {
                            Get.back();
                            Get.back(); // Fermer aussi la page de détails
                          }
                        },
                        child: Obx(
                          () => controller.isLoading.value
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

  Widget _buildTextField(
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
            color: AppColors.primary.withOpacity(0.7),
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

  void _confirmDelete(
    BuildContext context,
    LocationModel loc,
    LocationController controller,
  ) {
    AppModal.showConfirmation(
      context: context,
      title: "Supprimer le lieu",
      message:
          "Voulez-vous vraiment supprimer ${loc.buildingName} - Salle ${loc.roomNumber} ? Cette action est irréversible.",
      confirmText: "Supprimer",
      cancelText: "Annuler",
      onConfirm: () {
        controller.deleteLocation(loc.id);
        Get.back();
      },
    );
  }
}

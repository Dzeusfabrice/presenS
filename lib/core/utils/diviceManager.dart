import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceManager {
  static const String _deviceKey = "device_id";
  static const Uuid _uuid = Uuid();

  /// Retourne un device_id unique et persistant
  static Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();

    String? deviceId = prefs.getString(_deviceKey);

    // Si aucun device_id n'existe → on en génère un
    if (deviceId == null) {
      deviceId = _uuid.v4(); // UUID aléatoire sécurisé
      await prefs.setString(_deviceKey, deviceId);
    }

    return deviceId;
  }

  /// Permet de réinitialiser si nécessaire (logout complet par ex)
  static Future<void> clearDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_deviceKey);
  }
}
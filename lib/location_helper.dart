import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationHelper {
  static final String localWifiNamePrefix = "Telekom-b296e5";

  static Future<void> requestLocationPermission() async {
    final status = await Permission.locationWhenInUse.status;
    if (!status.isGranted) {
      await Permission.locationWhenInUse.request();
    }
  }

  static Future<bool> isAtHome({bool canRequestPermission = true}) async {
    if (canRequestPermission) {
      await requestLocationPermission();
    }
    final info = NetworkInfo();
    final wifiName = await info.getWifiName();
    final name = wifiName?.replaceAll('"', '') ?? '';
    return name.startsWith(localWifiNamePrefix);
  }
}
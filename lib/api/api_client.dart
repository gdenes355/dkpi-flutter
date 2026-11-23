import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dkpi/location_helper.dart';
import 'package:dkpi/models/device.dart';
import 'package:dkpi/models/device_status.dart';

class ApiClient {
  static final String publicBaseUrl = "https://dkpi.gdenes.com/api";
  static final String privateBaseUrl = "http://192.168.0.12:8001/api";
  
  static final String apiKey = "sPPM1eV33)@m[PXcNWoDmfY1Afmtz[K1";

  static Future<String> getBaseUrl() async {
    if (await LocationHelper.isAtHome()) {
      return privateBaseUrl;
    }
    return publicBaseUrl;
  }

  static Future<List<Device>> getDevices() async {
    final baseUrl = await getBaseUrl();
    final response = await http.get(Uri.parse('$baseUrl/devices'), headers: getHeaders());
    if (response.statusCode != 200) {
      throw Exception('Failed to load devices');
    }
    return (jsonDecode(response.body) as List).map((json) => Device.fromJson(json)).toList();
  }

  /// Forces the server to re-scan for devices. Can take a long time.
  static Future<void> scanDevices() async {
    final baseUrl = await getBaseUrl();
    final response = await http.get(Uri.parse('$baseUrl/devices/scan'), headers: getHeaders());
    if (response.statusCode != 200) {
      throw Exception('Failed to scan devices (${response.statusCode})');
    }
  }

  static Future<DeviceStatus> getDeviceStatus(String id) async {
    final baseUrl = await getBaseUrl();
    final response = await http.get(Uri.parse('$baseUrl/devices/$id/status'), headers: getHeaders());
    if (response.statusCode != 200) {
      throw Exception('Failed to load device status');
    }
    final data = jsonDecode(response.body);
    if (data.containsKey('error')) {
      throw Exception(data['error'] as String);
    }
    return DeviceStatus.fromJson(data);
  }

  static Future<DeviceStatus> updateDeviceOn(String id, bool on) async {
    final baseUrl = await getBaseUrl();
    final response = await http.post(Uri.parse('$baseUrl/devices/$id/status'), headers: getHeaders(), body: jsonEncode({'on': on}));
    if (response.statusCode != 200) {
      throw Exception('Failed to update device on/off');
    }
    return DeviceStatus.fromJson(jsonDecode(response.body));
  }

  static Future<DeviceStatus> updateDeviceBrightness(String id, int brightness) async {
    final baseUrl = await getBaseUrl();
    final response = await http.patch(Uri.parse('$baseUrl/devices/$id/status'), headers: getHeaders(), body: jsonEncode({'additional_data': {'brightness': brightness}}));
    if (response.statusCode != 200) {
      throw Exception('Failed to update device brightness');
    }
    return DeviceStatus.fromJson(jsonDecode(response.body));
  }

  static Future<DeviceStatus> updateTargetTemperature(String id, int targetTemperature) async {
    final baseUrl = await getBaseUrl();
    final response = await http.patch(Uri.parse('$baseUrl/devices/$id/status'), headers: getHeaders(), body: jsonEncode({'additional_data': {'target_temperature': targetTemperature}}));
    if (response.statusCode != 200) {
      throw Exception('Failed to update target temperature');
    }
    return DeviceStatus.fromJson(jsonDecode(response.body));
  }

  static Map<String, String> getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };
  }
}

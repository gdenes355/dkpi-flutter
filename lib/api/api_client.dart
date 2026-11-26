import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dkpi/location_helper.dart';
import 'package:dkpi/models/device.dart';
import 'package:dkpi/models/device_status.dart';
import 'package:dkpi/models/device_log.dart';

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

  /// Server diagnostics: system uptime, API process uptime, private IP and public IP.
  static Future<Map<String, dynamic>> getServerInfo() async {
    final baseUrl = await getBaseUrl();
    final response = await http.get(Uri.parse('$baseUrl/tools'), headers: getHeaders());
    if (response.statusCode != 200) {
      throw Exception('Failed to load server info (${response.statusCode})');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Aggregated device readings between [start] and [end] (at most 366 days), for all devices
  /// unless [deviceId] is given.
  static Future<DeviceLog> getDeviceLog({
    required DateTime start,
    required DateTime end,
    required LogGranularity granularity,
    String? deviceId,
  }) async {
    final baseUrl = await getBaseUrl();
    // Send UTC with an explicit offset: the server reads offset-less times as Budapest local time
    final uri = Uri.parse('$baseUrl/devices/log').replace(queryParameters: {
      'start': start.toUtc().toIso8601String(),
      'end': end.toUtc().toIso8601String(),
      'granularity': granularity.name,
      'device_id': ?deviceId,
    });
    final response = await http.get(uri, headers: getHeaders());
    if (response.statusCode != 200) {
      throw Exception('Failed to load device history (${response.statusCode}): ${response.body}');
    }
    return DeviceLog.fromJson(jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>);
  }

  /// Takes a reading of every device now and stores it (what the server's cron does every 30 min).
  /// Returns how many readings were stored. Can take a while: slow devices time out after ~10 s.
  static Future<int> logDevicesNow() async {
    final baseUrl = await getBaseUrl();
    final response = await http.post(Uri.parse('$baseUrl/devices/log'), headers: getHeaders());
    if (response.statusCode == 409) {
      throw Exception('A reading is already in progress');
    }
    if (response.statusCode != 200) {
      throw Exception('Failed to take a reading (${response.statusCode})');
    }
    return (jsonDecode(response.body)['count'] as num).toInt();
  }

  static Map<String, String> getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };
  }
}

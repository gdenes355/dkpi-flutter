import 'package:dkpi/models/device_type.dart';

class DeviceStatusAdditionalData {
  final double? humidity;
  final double? temperature;
  final int? brightness;

  const DeviceStatusAdditionalData({
    this.humidity,
    this.temperature,
    this.brightness,
  });

  factory DeviceStatusAdditionalData.fromJson(Map<String, dynamic> json) {
    return DeviceStatusAdditionalData(
      humidity: (json['humidity'] as num?)?.toDouble(),
      temperature: (json['temperature'] as num?)?.toDouble(),
      brightness: json['brightness'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'humidity': humidity,
      'temperature': temperature,
      'brightness': brightness,
    };
  }
}

class DeviceStatus {
  final String id;
  final String? name;
  final String? ip;
  final DeviceType? deviceType;
  final bool on;
  final DeviceStatusAdditionalData? additionalData;

  const DeviceStatus({
    required this.id,
    this.name,
    this.ip,
    this.deviceType,
    this.on = false,
    this.additionalData,
  });

  factory DeviceStatus.fromJson(Map<String, dynamic> json) {
    return DeviceStatus(
      id: json['id'],
      name: json['name'],
      ip: json['ip'],
      deviceType: DeviceType.fromSerialized(json['device_type']),
      on: json['on'],
      additionalData: json['additional_data'] != null
          ? DeviceStatusAdditionalData.fromJson(json['additional_data'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'ip': ip,
      'device_type': deviceType?.serialized,
      'on': on,
      'additional_data': additionalData,
    };
  }
}
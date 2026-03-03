import 'package:dkpi/models/device_type.dart';

class DeviceAdditionalData {
  final List<String> fields;
  final int? lastSeenTime;
  final int? maxBrightness;
  final List<String>? settableFields;

  const DeviceAdditionalData({
    required this.fields,
    this.lastSeenTime,
    this.maxBrightness,
    this.settableFields,
  });

  factory DeviceAdditionalData.fromJson(Map<String, dynamic> json) {
    return DeviceAdditionalData(
      fields: List<String>.from(json['fields'] ?? []),
      lastSeenTime: json['last_seen_time'],
      maxBrightness: json['max_brightness'],
      settableFields: json['settable_fields'] != null ? List<String>.from(json['settable_fields'] ?? []) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fields': fields,
      'last_seen_time': lastSeenTime,
      'max_brightness': maxBrightness,
      'settable_fields': settableFields,
    };
  }
}

class Device {
  final String id;
  final String? name;
  final String? ip;
  final DeviceType? deviceType;
  final DeviceAdditionalData? additionalData;

  const Device({
    required this.id,
    this.name,
    this.ip,
    this.additionalData,
    this.deviceType,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'],
      name: json['name'],
      ip: json['ip'],
      additionalData: json['additional_data'] != null
          ? DeviceAdditionalData.fromJson(json['additional_data'] as Map<String, dynamic>)
          : null,
      deviceType: DeviceType.fromSerialized(json['device_type']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'ip': ip,
      'additional_data': additionalData,
      'device_type': deviceType?.serialized,
    };
  }
}

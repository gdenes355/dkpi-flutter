import 'package:dkpi/models/ac_state.dart';
import 'package:dkpi/models/device_type.dart';

class DeviceStatusAdditionalData {
  final double? humidity;
  final double? temperature;
  final int? brightness;
  final String? temperatureUnit;
  final double? targetTemperature;
  final bool? heatingOn;
  final AcState? acState;

  const DeviceStatusAdditionalData({
    this.humidity,
    this.temperature,
    this.brightness,
    this.temperatureUnit,
    this.targetTemperature,
    this.heatingOn,
    this.acState,
  });

  /// Display suffix for temperatures, e.g. "°C". Defaults to Celsius.
  String get temperatureUnitSymbol =>
      temperatureUnit?.toLowerCase() == 'f' ? '°F' : '°C';

  factory DeviceStatusAdditionalData.fromJson(Map<String, dynamic> json) {
    return DeviceStatusAdditionalData(
      humidity: (json['humidity'] as num?)?.toDouble(),
      temperature: (json['temperature'] as num?)?.toDouble(),
      brightness: json['brightness'] as int?,
      temperatureUnit: json['temperature_unit'] as String?,
      targetTemperature: (json['target_temperature'] as num?)?.toDouble(),
      heatingOn: json['heating_on'] as bool?,
      acState: json['computed_state'] is Map<String, dynamic>
          ? AcState.fromJson(json['computed_state'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'humidity': humidity,
      'temperature': temperature,
      'brightness': brightness,
      'temperature_unit': temperatureUnit,
      'target_temperature': targetTemperature,
      'heating_on': heatingOn,
      'computed_state': acState?.toJson(),
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
          ? DeviceStatusAdditionalData.fromJson(
              json['additional_data'] as Map<String, dynamic>,
            )
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

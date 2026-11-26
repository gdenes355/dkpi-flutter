/// Subtype of a Tuya device, from `additional_data.device_type`.
enum TuyaDeviceType {
  thermostat;

  /// Serialized string representation for API/JSON.
  String get serialized => switch (this) {
    TuyaDeviceType.thermostat => 'thermostat',
  };

  @override
  String toString() => serialized;

  static TuyaDeviceType? fromSerialized(String? value) {
    if (value == null) return null;
    return switch (value) {
      'thermostat' => TuyaDeviceType.thermostat,
      _ => null,
    };
  }
}

enum DeviceType {
  tuya,
  dkpiDevice;

  /// Serialized string representation for API/JSON.
  /// dkpiDevice serializes as "DkpiD".
  String get serialized => switch (this) {
        DeviceType.tuya => 'tuya',
        DeviceType.dkpiDevice => 'DkpiD',
      };

  @override
  String toString() => serialized;

  static DeviceType? fromSerialized(String? value) {
    if (value == null) return null;
    return switch (value) {
      'tuya' => DeviceType.tuya,
      'DkpiD' => DeviceType.dkpiDevice,
      _ => null,
    };
  }
}
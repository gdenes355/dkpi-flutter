enum DeviceType {
  tuya,
  dkpiDevice,
  toshibaHomeAc;

  /// Serialized string representation for API/JSON.
  /// dkpiDevice serializes as "DkpiD".
  String get serialized => switch (this) {
    DeviceType.tuya => 'tuya',
    DeviceType.dkpiDevice => 'DkpiD',
    DeviceType.toshibaHomeAc => 'ToshibaHomeAc',
  };

  /// Human-readable name of the integration.
  String get label => switch (this) {
    DeviceType.tuya => 'Tuya',
    DeviceType.dkpiDevice => 'DKPI',
    DeviceType.toshibaHomeAc => 'Toshiba AC',
  };

  @override
  String toString() => serialized;

  static DeviceType? fromSerialized(String? value) {
    if (value == null) return null;
    return switch (value) {
      'tuya' => DeviceType.tuya,
      'DkpiD' => DeviceType.dkpiDevice,
      'ToshibaHomeAc' => DeviceType.toshibaHomeAc,
      _ => null,
    };
  }
}

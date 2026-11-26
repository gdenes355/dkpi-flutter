// Parsed `additional_data.computed_state` of an air conditioner
// (mirrors the backend's `DeviceStateObject`).

enum AcMode {
  auto('auto', 'Auto'),
  cool('cool', 'Cool'),
  heat('heat', 'Heat'),
  dry('dry', 'Dry'),
  fan('fan', 'Fan');

  final String serialized;
  final String label;
  const AcMode(this.serialized, this.label);

  static AcMode? fromSerialized(String? value) {
    for (final m in values) {
      if (m.serialized == value) return m;
    }
    return null;
  }
}

enum FanMode {
  auto('auto'),
  quiet('quiet'),
  low('low'),
  mediumLow('medium-low'),
  medium('medium'),
  mediumHigh('medium-high'),
  high('high');

  final String serialized;
  const FanMode(this.serialized);

  static FanMode? fromSerialized(String? value) {
    for (final m in values) {
      if (m.serialized == value) return m;
    }
    return null;
  }
}

enum Swing {
  off('off'),
  vertical('swing-vertical'),
  horizontal('swing-horizontal'),
  verticalAndHorizontal('swing-vertical-and-horizontal'),
  fixed1('fixed-1'),
  fixed2('fixed-2'),
  fixed3('fixed-3'),
  fixed4('fixed-4'),
  fixed5('fixed-5');

  final String serialized;
  const Swing(this.serialized);

  static Swing? fromSerialized(String? value) {
    for (final s in values) {
      if (s.serialized == value) return s;
    }
    return null;
  }
}

class AcState {
  final bool? on;
  final AcMode? mode;
  final int? temperature;
  final int? indoorTemperature;
  final int? outdoorTemperature;
  final FanMode? fanMode;

  /// 50, 75 or 100.
  final int? power;
  final Swing? swing;

  const AcState({
    this.on,
    this.mode,
    this.temperature,
    this.indoorTemperature,
    this.outdoorTemperature,
    this.fanMode,
    this.power,
    this.swing,
  });

  factory AcState.fromJson(Map<String, dynamic> json) {
    return AcState(
      on: json['on'] as bool?,
      mode: AcMode.fromSerialized(json['mode'] as String?),
      temperature: (json['temperature'] as num?)?.toInt(),
      indoorTemperature: (json['indoor_temperature'] as num?)?.toInt(),
      outdoorTemperature: (json['outdoor_temperature'] as num?)?.toInt(),
      fanMode: FanMode.fromSerialized(json['fan_mode'] as String?),
      power: (json['power'] as num?)?.toInt(),
      swing: Swing.fromSerialized(json['swing'] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'on': on,
      'mode': mode?.serialized,
      'temperature': temperature,
      'indoor_temperature': indoorTemperature,
      'outdoor_temperature': outdoorTemperature,
      'fan_mode': fanMode?.serialized,
      'power': power,
      'swing': swing?.serialized,
    };
  }
}

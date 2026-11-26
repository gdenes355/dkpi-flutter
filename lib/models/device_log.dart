import 'package:dkpi/models/device_type.dart';

/// Bucket size the server aggregates readings into (`granularity` on GET /devices/log).
/// Buckets are UTC-aligned on the server; weeks start on Monday 00:00 UTC.
enum LogGranularity {
  /// Individual readings, taken every 30 minutes by the server's cron.
  raw(Duration(minutes: 30)),
  hour(Duration(hours: 1)),
  day(Duration(days: 1)),
  week(Duration(days: 7));

  const LogGranularity(this.bucket);
  final Duration bucket;
}

/// One aggregated bucket of readings for a device. All values are optional:
/// each integration only reports the fields it has (e.g. only ACs have a target temperature).
class DeviceLogPoint {
  /// Bucket start.
  final DateTime ts;
  final int samples;

  /// Share of readings where the device was on, 0..1.
  final double? onRatio;
  final double? temperature;
  final double? temperatureMin;
  final double? temperatureMax;
  final double? humidity;
  final double? humidityMin;
  final double? humidityMax;
  final double? targetTemperature;
  final double? outdoorTemperature;

  /// Share of readings where the device was heating, 0..1.
  final double? heatingOnRatio;

  const DeviceLogPoint({
    required this.ts,
    required this.samples,
    this.onRatio,
    this.temperature,
    this.temperatureMin,
    this.temperatureMax,
    this.humidity,
    this.humidityMin,
    this.humidityMax,
    this.targetTemperature,
    this.outdoorTemperature,
    this.heatingOnRatio,
  });

  static double? _num(dynamic v) => v is num ? v.toDouble() : null;
  static double? _bool(dynamic v) => v is bool ? (v ? 1.0 : 0.0) : null;

  /// Parses both aggregated buckets and raw readings (granularity=raw). A raw reading becomes a
  /// one-sample bucket: its on/heating_on flags turn into 0 or 1 ratios.
  factory DeviceLogPoint.fromJson(Map<String, dynamic> json) {
    return DeviceLogPoint(
      ts: DateTime.parse(json['ts'] as String),
      samples: (json['samples'] as num?)?.toInt() ?? 1,
      onRatio: _num(json['on_ratio']) ?? _bool(json['on']),
      temperature: _num(json['temperature']),
      temperatureMin: _num(json['temperature_min']),
      temperatureMax: _num(json['temperature_max']),
      humidity: _num(json['humidity']),
      humidityMin: _num(json['humidity_min']),
      humidityMax: _num(json['humidity_max']),
      targetTemperature: _num(json['target_temperature']),
      outdoorTemperature: _num(json['outdoor_temperature']),
      heatingOnRatio: _num(json['heating_on_ratio']) ?? _bool(json['heating_on']),
    );
  }
}

class DeviceLogSeries {
  final String id;
  final String name;
  final DeviceType? deviceType;
  final List<DeviceLogPoint> points;

  const DeviceLogSeries({required this.id, required this.name, this.deviceType, required this.points});

  factory DeviceLogSeries.fromJson(Map<String, dynamic> json) {
    return DeviceLogSeries(
      id: json['id'] as String,
      name: json['name'] as String,
      deviceType: DeviceType.fromSerialized(json['device_type'] as String?),
      points: (json['points'] as List)
          .map((p) => DeviceLogPoint.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }
}

class DeviceLog {
  final DateTime start;
  final DateTime end;
  final LogGranularity granularity;
  final List<DeviceLogSeries> devices;

  const DeviceLog({required this.start, required this.end, required this.granularity, required this.devices});

  factory DeviceLog.fromJson(Map<String, dynamic> json) {
    return DeviceLog(
      start: DateTime.parse(json['start'] as String),
      end: DateTime.parse(json['end'] as String),
      granularity: LogGranularity.values.byName(json['granularity'] as String),
      devices: (json['devices'] as List)
          .map((d) => DeviceLogSeries.fromJson(d as Map<String, dynamic>))
          .toList(),
    );
  }
}

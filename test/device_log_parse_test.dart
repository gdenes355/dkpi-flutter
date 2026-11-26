import 'package:dkpi/models/device_log.dart';
import 'package:dkpi/models/device_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses aggregated device log', () {
    final log = DeviceLog.fromJson({
      'start': '2026-11-20T00:00:00Z',
      'end': '2026-11-26T16:10:11.959364Z',
      'granularity': 'day',
      'devices': [
        {
          'id': 'e6626005a75b6229', 'name': 'Fekete Asztal', 'device_type': 'DkpiD',
          'points': [
            {'ts': '2026-11-26T00:00:00Z', 'samples': 33, 'on_ratio': 0.061, 'temperature': 18.43,
             'temperature_min': 17.7454, 'temperature_max': 20, 'humidity': 37.74, 'humidity_min': 37.2,
             'humidity_max': 38.9, 'target_temperature': null, 'outdoor_temperature': null,
             'heating_on_ratio': null},
          ],
        },
      ],
    });
    expect(log.granularity, LogGranularity.day);
    final d = log.devices.single;
    expect(d.deviceType, DeviceType.dkpiDevice);
    final p = d.points.single;
    expect(p.ts, DateTime.utc(2026, 11, 26));
    expect(p.samples, 33);
    expect(p.temperatureMax, 20.0); // int in JSON still parses as double
    expect(p.targetTemperature, isNull);
    expect(p.heatingOnRatio, isNull);
  });

  test('parses raw readings as one-sample buckets', () {
    final log = DeviceLog.fromJson({
      'start': '2026-11-25T16:00:00Z', 'end': '2026-11-26T16:00:00Z', 'granularity': 'raw',
      'devices': [
        {
          'id': 'x', 'name': 'Termosztát', 'device_type': 'tuya',
          'points': [
            {'ts': '2026-11-26T10:10:00Z', 'on': true, 'temperature': 19.5, 'humidity': null,
             'target_temperature': 20, 'outdoor_temperature': null, 'heating_on': false,
             'extra': {'temperature_unit': 'c'}},
          ],
        },
      ],
    });
    expect(log.granularity, LogGranularity.raw);
    final p = log.devices.single.points.single;
    expect(p.samples, 1);
    expect(p.onRatio, 1.0);
    expect(p.heatingOnRatio, 0.0);
    expect(p.temperature, 19.5);
    expect(p.temperatureMin, isNull);
  });
}

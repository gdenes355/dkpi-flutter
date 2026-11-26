import 'package:dkpi/models/device.dart';
import 'package:dkpi/models/ac_state.dart';
import 'package:dkpi/models/device_status.dart';
import 'package:dkpi/models/device_type.dart';
import 'package:dkpi/models/tuya_device_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses tuya thermostat', () {
    final d = Device.fromJson({
      'id': 'x', 'name': 'Termosztát', 'ip': '192.168.0.22', 'device_type': 'tuya',
      'additional_data': {'version': '3.5', 'device_type': 'thermostat',
        'fields': ['temperature_unit', 'temperature', 'target_temperature', 'heating_on'],
        'settable_fields': ['target_temperature']},
    });
    expect(d.additionalData!.tuyaDeviceType, TuyaDeviceType.thermostat);
    expect(d.additionalData!.version, '3.5');
    final s = DeviceStatus.fromJson({
      'id': 'x', 'device_type': 'tuya', 'on': true,
      'additional_data': {'temperature_unit': 'c', 'temperature': 20.5, 'target_temperature': 18, 'heating_on': false},
    });
    expect(s.additionalData!.targetTemperature, 18.0);
    expect(s.additionalData!.heatingOn, false);
    expect(s.additionalData!.temperatureUnitSymbol, '°C');
  });

  test('parses toshiba AC status', () {
    final s = DeviceStatus.fromJson({
      'id': 'e5955031', 'name': 'Emelet', 'ip': 'TOSHIBA_HOME_AC', 'device_type': 'ToshibaHomeAc', 'on': false,
      'additional_data': {
        'state_data': '3143193431320010177ffe0b00001002000000',
        'mode_values': [{'Mode': '41', 'Temp': '18', 'FanSpeed': '36'}],
        'cdu': {'model_name': 'RAS-10J2AVSG-E1'},
        'fcu_type': null,
        'computed_state': {'on': false, 'mode': 'heat', 'temperature': 25, 'indoor_temperature': 23,
          'outdoor_temperature': null, 'fan_mode': 'medium', 'power': 50, 'swing': 'off'},
      },
    });
    expect(s.deviceType, DeviceType.toshibaHomeAc);
    final ac = s.additionalData!.acState!;
    expect(ac.mode, AcMode.heat);
    expect(ac.temperature, 25);
    expect(ac.indoorTemperature, 23);
    expect(ac.outdoorTemperature, isNull);
    expect(ac.fanMode, FanMode.medium);
    expect(ac.power, 50);
    expect(ac.swing, Swing.off);
  });
}

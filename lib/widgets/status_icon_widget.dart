import 'package:dkpi/models/ac_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class StatusIconWidget extends StatelessWidget {
  final bool on;
  final bool loading;
  final bool thermostat;
  final bool heating;
  final bool airConditioner;
  final AcMode? acMode;
  final String? deviceName;
  const StatusIconWidget({
    super.key,
    required this.on,
    required this.loading,
    this.thermostat = false,
    this.heating = false,
    this.airConditioner = false,
    this.acMode,
    this.deviceName,
  });

  bool get _isBigBen => deviceName?.trim().toLowerCase() == 'big ben';

  @override
  Widget build(BuildContext context) {
    final Widget icon;
    if (loading) {
      icon = const CircularProgressIndicator(strokeWidth: 2);
    } else if (_isBigBen) {
      icon = SvgPicture.asset(
        'assets/icons/big_ben.svg',
        width: 28,
        height: 28,
        colorFilter: ColorFilter.mode(
          on ? Colors.amber : Colors.black,
          BlendMode.srcIn,
        ),
      );
    } else if (airConditioner) {
      icon = Icon(
        Icons.heat_pump,
        size: 28,
        color: !on
            ? Colors.black
            : (acMode == AcMode.heat ? Colors.deepOrange : Colors.blue),
      );
    } else if (thermostat) {
      icon = Icon(
        Icons.thermostat,
        size: 28,
        color: heating ? Colors.deepOrange : (on ? Colors.blue : Colors.black),
      );
    } else {
      icon = Icon(
        Icons.lightbulb,
        size: 28,
        color: on ? Colors.amber : Colors.black,
      );
    }
    return SizedBox(width: 36, child: Center(child: icon));
  }
}

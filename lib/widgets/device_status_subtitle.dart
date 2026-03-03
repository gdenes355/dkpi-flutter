import 'package:dkpi/models/device.dart';
import 'package:dkpi/models/device_status.dart';
import 'package:flutter/material.dart';

class DeviceStatusSubtitle extends StatelessWidget {
  final Device device;
  final DeviceStatus? status;
  final bool loading;
  const DeviceStatusSubtitle({super.key, required this.device, required this.status, this.loading = false});

  @override
  Widget build(BuildContext context) {
    final hasAdditionalFields = device.additionalData?.fields?.isNotEmpty ?? false;
    if (!hasAdditionalFields) return const SizedBox.shrink();

    if (loading) return const Text('Loading more data');

    if (status?.additionalData == null) return const SizedBox.shrink();

    final parts = <String>[];
    final temp = status?.additionalData?.temperature;
    if (temp != null) {
      parts.add('${(temp * 10).round() / 10}°C');
    }
    final humidity = status?.additionalData?.humidity;
    if (humidity != null) {
      parts.add('H${humidity.round()}%');
    }
    return Text(parts.join('  '));
  }
}
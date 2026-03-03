import 'package:dkpi/cubits/devices.dart';
import 'package:dkpi/widgets/device_status_subtitle.dart';
import 'package:dkpi/widgets/status_icon_widget.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:dkpi/models/device.dart';
import 'package:dkpi/cubits/device_row.dart';

class DeviceRowWidget extends StatelessWidget {
  final Device device;
  const DeviceRowWidget({super.key, required this.device});

  void showErrorDetailsDialog(BuildContext context) {
    final cubit = context.read<DeviceRowCubit>();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(cubit.state.error ?? 'Unknown error'),
      ),
    );
  }

  void _showBrightnessDialog(BuildContext context) {
    final cubit = context.read<DeviceRowCubit>();
    final maxBrightness = device.additionalData?.maxBrightness ?? 10;
    double currentValue =
        ((cubit.state.status?.additionalData?.brightness ?? 0).toDouble())
            .clamp(0.0, maxBrightness.toDouble());
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Brightness (${currentValue.toInt()})',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Slider(
                  value: currentValue,
                  min: 0,
                  max: maxBrightness.toDouble(),
                  divisions: maxBrightness > 0 ? maxBrightness : null,
                  onChanged: (v) => setState(() => currentValue = v),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      cubit.updateBrightness(currentValue.toInt());
                    },
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<DeviceRowCubit>();
    final devicesCubit = context.read<DevicesCubit>();
    return BlocListener<DevicesCubit, DevicesState>(
      bloc: devicesCubit,
      listenWhen: (previous, current) =>
          previous.refreshTrigger != current.refreshTrigger,
      listener: (context, devicesState) =>
          context.read<DeviceRowCubit>().loadStatus(),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            StatusIconWidget(
              loading: (cubit.state.loading || cubit.state.updating),
              on: cubit.state.status?.on ?? false,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.name ?? device.id,
                    style: const TextStyle(fontSize: 18),
                  ),
                  if (cubit.state.error != null &&
                      cubit.state.error!.isNotEmpty)
                    GestureDetector(
                      onTap: () => showErrorDetailsDialog(context),
                      child: Text(
                        cubit.state.error!,
                        style: const TextStyle(color: Colors.red),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.left,
                      ),
                    ),
                  DeviceStatusSubtitle(device: device, status: cubit.state.status, loading: cubit.state.loading),
                ],
              ),
            ),
            if ((device.additionalData?.settableFields?.contains(
                      'brightness',
                    ) ??
                    false) &&
                (cubit.state.status?.on ?? false))
              TextButton(
                onPressed: () => cubit.state.loading || cubit.state.updating ? null : _showBrightnessDialog(context),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.secondary,
                ),
                child: Text(
                  'LVL: ${cubit.state.status?.additionalData?.brightness ?? 0}',
                ),
              ),
            if (cubit.state.status != null)
              TextButton(
                onPressed: () => cubit.updateDeviceOn(
                  cubit.state.status?.on == true ? false : true,
                ),
                child: Text(cubit.state.status?.on ?? false ? 'OFF' : 'ON'),
              ),
          ],
        ),
      ),
    );
  }
}

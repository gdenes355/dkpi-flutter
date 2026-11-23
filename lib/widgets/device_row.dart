import 'package:dkpi/cubits/devices.dart';
import 'package:dkpi/widgets/circular_temperature_slider.dart';
import 'package:dkpi/widgets/device_status_subtitle.dart';
import 'package:dkpi/widgets/status_icon_widget.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:dkpi/models/device.dart';
import 'package:dkpi/models/device_type.dart';
import 'package:dkpi/models/tuya_device_type.dart';
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

  static const double _minTargetTemperature = 5;
  static const double _maxTargetTemperature = 35;
  static const double _targetTemperatureStep = 1;

  void _showTargetTemperatureDialog(BuildContext context) {
    final cubit = context.read<DeviceRowCubit>();
    double currentValue =
        (cubit.state.status?.additionalData?.targetTemperature ?? 20)
            .roundToDouble()
            .clamp(_minTargetTemperature, _maxTargetTemperature);
    void step(StateSetter setState, double delta) => setState(
      () => currentValue = (currentValue + delta).clamp(
        _minTargetTemperature,
        _maxTargetTemperature,
      ),
    );
    showDialog(
      context: context,
      builder: (context) => BlocProvider.value(
        value: cubit,
        child: StatefulBuilder(
          builder: (context, setState) =>
              BlocBuilder<DeviceRowCubit, DeviceRowState>(
                builder: (context, state) {
                  final status = state.status;
                  final busy = state.loading || state.updating;
                  final error = state.error;
                  final unit =
                      status?.additionalData?.temperatureUnitSymbol ?? '°C';
                  final canSet =
                      status != null &&
                      (device.additionalData?.settableFields?.contains(
                            'target_temperature',
                          ) ??
                          false);
                  return Dialog(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  device.name ?? 'Thermostat',
                                  style: Theme.of(context).textTheme.titleLarge,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (busy)
                                const Padding(
                                  padding: EdgeInsets.only(right: 8),
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              if (status != null)
                                Switch(
                                  value: status.on,
                                  onChanged: busy
                                      ? null
                                      : (on) => cubit.updateDeviceOn(on),
                                ),
                            ],
                          ),
                          if (error != null && error.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _ErrorBanner(
                              error: error,
                              onRetry: busy ? null : cubit.loadStatus,
                            ),
                          ],
                          if (canSet) ...[
                            const SizedBox(height: 16),
                            Center(
                              child: CircularTemperatureSlider(
                                value: currentValue,
                                min: _minTargetTemperature,
                                max: _maxTargetTemperature,
                                step: _targetTemperatureStep,
                                unit: unit,
                                currentTemperature:
                                    status.additionalData?.temperature,
                                onChanged: (v) =>
                                    setState(() => currentValue = v),
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton.outlined(
                                  icon: const Icon(Icons.remove),
                                  tooltip: 'Decrease',
                                  onPressed:
                                      currentValue > _minTargetTemperature
                                      ? () => step(
                                          setState,
                                          -_targetTemperatureStep,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 32),
                                IconButton.outlined(
                                  icon: const Icon(Icons.add),
                                  tooltip: 'Increase',
                                  onPressed:
                                      currentValue < _maxTargetTemperature
                                      ? () => step(
                                          setState,
                                          _targetTemperatureStep,
                                        )
                                      : null,
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Close'),
                              ),
                              if (canSet)
                                TextButton(
                                  onPressed: busy
                                      ? null
                                      : () {
                                          Navigator.of(context).pop();
                                          cubit.updateTargetTemperature(
                                            currentValue.round(),
                                          );
                                        },
                                  child: const Text('Apply'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<DeviceRowCubit>();
    final devicesCubit = context.read<DevicesCubit>();
    final isThermostat =
        device.additionalData?.tuyaDeviceType == TuyaDeviceType.thermostat;
    final canSetTargetTemperature =
        (device.additionalData?.settableFields?.contains(
              'target_temperature',
            ) ??
            false) &&
        cubit.state.status != null;
    final busy = cubit.state.loading || cubit.state.updating;
    // Toshiba ACs: only on/off is supported for now.
    final isAirConditioner = device.deviceType == DeviceType.toshibaHomeAc;
    final hasError = cubit.state.error != null && cubit.state.error!.isNotEmpty;

    VoidCallback? onRowTap;
    if (isThermostat) {
      // Thermostats: the dialog holds the setter, on/off and any error.
      if (!busy && (cubit.state.status != null || hasError)) {
        onRowTap = () => _showTargetTemperatureDialog(context);
      }
    } else if (hasError) {
      onRowTap = () => showErrorDetailsDialog(context);
    }

    return BlocListener<DevicesCubit, DevicesState>(
      bloc: devicesCubit,
      listenWhen: (previous, current) =>
          previous.refreshTrigger != current.refreshTrigger,
      listener: (context, devicesState) =>
          context.read<DeviceRowCubit>().loadStatus(),
      child: InkWell(
        onTap: onRowTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              StatusIconWidget(
                loading: busy,
                on: cubit.state.status?.on ?? false,
                thermostat: isThermostat,
                airConditioner: isAirConditioner,
                acMode: cubit.state.status?.additionalData?.acState?.mode,
                heating: cubit.state.status?.additionalData?.heatingOn ?? false,
                deviceName: device.name,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            device.name ?? device.id,
                            style: const TextStyle(fontSize: 18),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (hasError)
                          const Padding(
                            padding: EdgeInsets.only(left: 6),
                            child: Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.red,
                              size: 20,
                              semanticLabel: 'Error',
                            ),
                          ),
                      ],
                    ),
                    DeviceStatusSubtitle(
                      device: device,
                      status: cubit.state.status,
                      loading: cubit.state.loading,
                    ),
                  ],
                ),
              ),
              if ((device.additionalData?.settableFields?.contains(
                        'brightness',
                      ) ??
                      false) &&
                  (cubit.state.status?.on ?? false))
                TextButton(
                  onPressed: () => busy ? null : _showBrightnessDialog(context),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.secondary,
                  ),
                  child: Text(
                    'LVL: ${cubit.state.status?.additionalData?.brightness ?? 0}',
                  ),
                ),
              if (canSetTargetTemperature && !isThermostat)
                TextButton(
                  onPressed: () =>
                      busy ? null : _showTargetTemperatureDialog(context),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.secondary,
                  ),
                  child: Text(
                    'SET: ${cubit.state.status?.additionalData?.targetTemperature?.round() ?? '-'}${cubit.state.status?.additionalData?.temperatureUnitSymbol ?? '°C'}',
                  ),
                ),
              if (cubit.state.status != null && !isThermostat)
                TextButton(
                  onPressed: () => cubit.updateDeviceOn(
                    cubit.state.status?.on == true ? false : true,
                  ),
                  child: Text(cubit.state.status?.on ?? false ? 'OFF' : 'ON'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String error;
  final VoidCallback? onRetry;
  const _ErrorBanner({required this.error, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: scheme.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: TextStyle(color: scheme.onErrorContainer),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

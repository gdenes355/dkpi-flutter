import 'package:dkpi/api/api_client.dart';
import 'package:dkpi/models/device.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DevicesState {
  final List<Device> devices;
  final bool loading;
  final bool scanning;
  final String? error;
  final int refreshTrigger;

  DevicesState({
    required this.devices,
    this.loading = false,
    this.scanning = false,
    this.error,
    this.refreshTrigger = 0,
  });

  DevicesState copyWith({
    List<Device>? devices,
    bool? loading,
    bool? scanning,
    String? error,
    int? refreshTrigger,
  }) {
    return DevicesState(devices: devices ?? this.devices, loading: loading ?? this.loading, scanning: scanning ?? this.scanning, error: error ?? this.error, refreshTrigger: refreshTrigger ?? this.refreshTrigger);
  }
}

class DevicesCubit extends Cubit<DevicesState> {
  DevicesCubit() : super(DevicesState(devices: []));

  void loadDevices() async {
    try {
      emit(state.copyWith(loading: true, error: null));
      final devices = await ApiClient.getDevices();
      emit(state.copyWith(devices: devices, loading: false, error: null, refreshTrigger: state.refreshTrigger + 1));
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  /// Forces a server-side re-scan, then reloads the device list.
  /// Throws on failure so the caller can show the error.
  Future<void> rescan() async {
    if (state.scanning) return;
    emit(state.copyWith(scanning: true));
    try {
      await ApiClient.scanDevices();
    } finally {
      emit(state.copyWith(scanning: false));
    }
    loadDevices();
  }
}
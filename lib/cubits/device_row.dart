import 'package:dkpi/api/api_client.dart';
import 'package:dkpi/models/device_status.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DeviceRowState {
  final DeviceStatus? status;
  final bool loading;
  final bool updating;
  final String? error;

  DeviceRowState({
    this.status,
    this.loading = false,
    this.updating = false,
    this.error,
  });

  DeviceRowState copyWith({
    DeviceStatus? status,
    bool? loading,
    bool? updating,
    String? error,
  }) {
    return DeviceRowState(status: status ?? this.status, loading: loading ?? this.loading, updating: updating ?? this.updating, error: error ?? this.error);
  }
}

class DeviceRowCubit extends Cubit<DeviceRowState> {
  final String id;
  DeviceRowCubit({required this.id}) : super(DeviceRowState());

  void loadStatus() async {
    try {
      emit(state.copyWith(loading: true, error: ''));
      final status = await ApiClient.getDeviceStatus(id);
      emit(state.copyWith(status: status, loading: false, error: ''));
    } catch (e) {
      try {
        emit(state.copyWith(loading: false, error: "Failed to load device status"));
      } catch (e) {
        print(e);
      }
    }
  }

  void updateBrightness(int brightness) async {
    try {
      emit(state.copyWith(updating: true, error: ''));
      final status = await ApiClient.updateDeviceBrightness(id, brightness);
      emit(state.copyWith(status: status, updating: false, error: ''));
    } catch (e) {
      emit(state.copyWith(updating: false, error: e.toString()));
    }
  }

  void updateTargetTemperature(int targetTemperature) async {
    try {
      emit(state.copyWith(updating: true, error: ''));
      final status = await ApiClient.updateTargetTemperature(id, targetTemperature);
      emit(state.copyWith(status: status, updating: false, error: ''));
    } catch (e) {
      emit(state.copyWith(updating: false, error: e.toString()));
    }
  }

  void updateDeviceOn(bool on) async {
    try {
      emit(state.copyWith(updating: true, error: ''));
      final status = await ApiClient.updateDeviceOn(id, on);
      emit(state.copyWith(status: status, updating: false, error: ''));
    } catch (e) {
      emit(state.copyWith(updating: false, error: e.toString()));
    }
  }
}
import 'package:mobile_labs/page/sensor_data.dart';

class HomeState {
  final List<SensorData> sensors;
  final String? userEmail;
  final bool isOffline;
  final bool isOnline;
  final String serverStatus;
  final String? key_;

  const HomeState({
    this.sensors = const [],
    this.userEmail,
    this.isOffline = false,
    this.isOnline = false,
    this.serverStatus = 'Offline',
    this.key_,
  });

  HomeState copyWith({
    List<SensorData>? sensors,
    String? userEmail,
    bool? isOffline,
    bool? isOnline,
    String? serverStatus,
    String? key_,
  }) {
    return HomeState(
      sensors: sensors ?? this.sensors,
      userEmail: userEmail ?? this.userEmail,
      isOffline: isOffline ?? this.isOffline,
      isOnline: isOnline ?? this.isOnline,
      serverStatus: serverStatus ?? this.serverStatus,
      key_: key_ ?? this.key_,
    );
  }
}

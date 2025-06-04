import 'dart:async';
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_labs/page/home_state.dart';
import 'package:mobile_labs/page/sensor_data.dart';
import 'package:mobile_labs/services/network_monitor.dart';
import 'package:mobile_labs/storage/storage.dart';
import 'package:mobile_labs/storage/storage_impl.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:typed_data/typed_data.dart';

final Storage localStorage = StorageImpl();
const _mqttBroker = 'broker.hivemq.com';
const _mqttPort = 1883;

class HomeCubit extends Cubit<HomeState> {
  late MqttServerClient _mqttClient;
  Timer? _networkCheckTimer;
  final List<String> topics = [
    'sensor/lux',
    'sensor/temperature',
    'sensor/pressure',
    'sensor/humidity',
  ];
  MqttServerClient get mqttClient => _mqttClient;
  HomeCubit() : super(const HomeState()) {
    _init();
    _startNetworkMonitor();
  }
  @override
  Future<void> close() {
    _mqttClient.disconnect();
    _networkCheckTimer?.cancel();
    return super.close();
  }
  void sendDisconnectRequest() {
    final buffer = Uint8Buffer()
      ..addAll(utf8.encode(jsonEncode({'key': 'none'})));
    try {
      _mqttClient.publishMessage(
        'sensor/disconnect',
        MqttQos.atLeastOnce,
        buffer,
      );
      emit(state.copyWith(serverStatus: 'Offline'));
    } catch (e) {
      //
    }
  }

  void sendConnectRequest(String login, String password) {
    final buffer = Uint8Buffer()
      ..addAll(
        utf8.encode(
         '{"action":"connect_request","login":"$login","password":"$password"}',
        ),
      );
    _mqttClient.publishMessage('sensor/connect', MqttQos.atLeastOnce, buffer);
  }

  void _startNetworkMonitor() {
    _networkCheckTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      final hasConnection = await NetworkMonitor.checkConnection();
      if (hasConnection != !state.isOffline) {
        emit(state.copyWith(isOffline: !hasConnection));
      }
    });
  }

  Future<void> _init() async {
    final userEmail = await localStorage.getCurrentUserEmail();
    emit(state.copyWith(userEmail: userEmail));
    await _loadSensors();
    if (state.sensors.isEmpty) {
      final sensors = topics
          .map((t) => SensorData(title: t.split('/').last, values: []))
          .toList();
      emit(state.copyWith(sensors: sensors));
      await _saveSensors();
    }
    await _setupMqtt();
  }

  Future<void> _loadSensors() async {
    final List<SensorData> sensors = [];
    for (final topic in topics) {
      final data = await localStorage.readTopicData(state.userEmail!, topic);
      if (data?['data'] is List) {
        sensors.addAll(
          (data!['data'] as List)
              .map((item) => SensorData.fromJson(item as Map<String, dynamic>)),
        );
      }
    }
    emit(state.copyWith(sensors: sensors));
  }
  Future<void> _saveSensors() async {
    final Map<String, List<SensorData>> grouped = {};
    for (var sensor in state.sensors) {
      grouped.putIfAbsent('sensor/${sensor.title}', () => []).add(sensor);
    }
    for (final entry in grouped.entries) {
      await localStorage.writeTopicData(
        state.userEmail!,
        entry.key,
        {'data': entry.value.map((e) => e.toJson()).toList()},
      );
    }
  }
  Future<void> _setupMqtt() async {
    _mqttClient = MqttServerClient(
      _mqttBroker,
      'flutter_${DateTime.now().millisecondsSinceEpoch}',
    )
      ..port = _mqttPort
      ..logging(on: false);
    try {
      await _mqttClient.connect();
    } catch (e) {
      _mqttClient.disconnect();
      return;
    }
    if (_mqttClient.connectionStatus!.state != MqttConnectionState.connected) {
      _mqttClient.disconnect();
      return;
    }
    for (var sensor in state.sensors) {
      _mqttClient.subscribe('sensor/${sensor.title}', MqttQos.atMostOnce);
    }
    _mqttClient.subscribe('sensor/status', MqttQos.atLeastOnce);
    _mqttClient.updates?.listen((events) {
      for (final event in events) {
        final msg = MqttPublishPayload.bytesToStringAsString(
          (event.payload as MqttPublishMessage).payload.message,
        );
        final topic = event.topic;

        if (topic == 'sensor/status') {
          final decoded = jsonDecode(msg);
          emit(
            state.copyWith(
              serverStatus:
                  decoded['status'] == 'connected' ? 'Online' : 'Offline',
            ),
          );
          continue;
        }
        final decoded = jsonDecode(msg);
        if (decoded is! List) continue;
        final newValues = decoded
            .map((e) => {'timestamp': e['timestamp'], 'value': e['value']})
            .toList();
        final sensors = List<SensorData>.from(state.sensors);
        final idx = sensors.indexWhere((s) => 'sensor/${s.title}' == topic);
        if (idx != -1) {
          sensors[idx] = SensorData(
            title: sensors[idx].title,
            values: List<Map<String, dynamic>>.from(newValues),
          );
          emit(state.copyWith(sensors: sensors));
          _saveSensors();
        }
      }
    });
  }
  void updateSensor(int index, List<Map<String, dynamic>> values) {
    final sensors = List<SensorData>.from(state.sensors);
    sensors[index] = SensorData(title: sensors[index].title, values: values);
    emit(state.copyWith(sensors: sensors));
    _saveSensors();
  }

  void deleteSensor(int index) {
    final sensors = List<SensorData>.from(state.sensors)..removeAt(index);
    emit(state.copyWith(sensors: sensors));
    _saveSensors();
  }
}

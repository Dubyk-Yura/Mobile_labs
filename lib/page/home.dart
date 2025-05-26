import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_labs/page/qr_scanner.dart';
import 'package:mobile_labs/page/sensor.dart';
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

class HomeCubit extends Cubit<HomeState> {
  late MqttServerClient _mqttClient;
  Timer? _networkCheckTimer;

  final List<String> topics = [
    'sensor/lux',
    'sensor/temperature',
    'sensor/pressure',
    'sensor/humidity',
  ];

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
    final buffer = Uint8Buffer();
    final disconnectPayload = jsonEncode({'key': 'none'});

    buffer.addAll(utf8.encode(disconnectPayload));

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
    final buffer = Uint8Buffer();

    final connectPayload =
        '{"action":"connect_request","login":"$login","password":"$password"}';
    buffer.addAll(utf8.encode(connectPayload));

    _mqttClient.publishMessage(
      'sensor/connect',
      MqttQos.atLeastOnce,
      buffer,
    );
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
      final defaultSensors = [
        SensorData(title: 'lux', values: []),
        SensorData(title: 'temperature', values: []),
        SensorData(title: 'pressure', values: []),
        SensorData(title: 'humidity', values: []),
      ];
      emit(state.copyWith(sensors: defaultSensors));
      await _saveSensors();
    }

    await _setupMqtt();
  }

  Future<void> _loadSensors() async {
    final List<SensorData> sensors = [];
    for (final topic in topics) {
      final data = await localStorage.readTopicData(state.userEmail!, topic);

      if (data != null && data['data'] != null && data['data'] is List) {
        final list = (data['data'] as List)
            .map((item) => SensorData.fromJson(item as Map<String, dynamic>))
            .toList();
        sensors.addAll(list);
      }
    }
    emit(state.copyWith(sensors: sensors));
  }

  Future<void> _saveSensors() async {
    final Map<String, List<SensorData>> grouped = {};
    for (var sensor in state.sensors) {
      final topic = 'sensor/${sensor.title}';
      grouped.putIfAbsent(topic, () => []).add(sensor);
    }

    for (final entry in grouped.entries) {
      final topic = entry.key;
      final jsonData = {
        'data': entry.value.map((e) => e.toJson()).toList(),
      };
      await localStorage.writeTopicData(state.userEmail!, topic, jsonData);
    }
  }

  Future<void> _setupMqtt() async {
    final clientId = 'flutter_${DateTime.now().millisecondsSinceEpoch}';
    _mqttClient = MqttServerClient(_mqttBroker, clientId);
    _mqttClient.port = _mqttPort;
    _mqttClient.logging(on: false);

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
      final topic = 'sensor/${sensor.title}';
      _mqttClient.subscribe(topic, MqttQos.atMostOnce);
    }

    _mqttClient.subscribe('sensor/status', MqttQos.atLeastOnce);

    _mqttClient.updates
        ?.listen((List<MqttReceivedMessage<MqttMessage>> events) {
      for (final event in events) {
        final rec = event.payload as MqttPublishMessage;
        final msg =
            MqttPublishPayload.bytesToStringAsString(rec.payload.message);
        final topic = event.topic;

        if (topic == 'sensor/status') {
          final decoded = jsonDecode(msg);
          if (decoded['status'] == 'connected') {
            emit(state.copyWith(serverStatus: 'Online'));
          } else {
            emit(state.copyWith(serverStatus: 'Offline'));
          }
          return;
        }

        final decoded = jsonDecode(msg);
        if (decoded is! List) return;

        final List<dynamic> msgJson = decoded;
        final newValues = msgJson.map((e) {
          return {
            'timestamp': e['timestamp'],
            'value': e['value'],
          };
        }).toList();

        final sensors = List<SensorData>.from(state.sensors);
        final idx = sensors.indexWhere((s) => 'sensor/${s.title}' == topic);
        if (idx == -1) return;

        sensors[idx] = SensorData(
          title: sensors[idx].title,
          values: List<Map<String, dynamic>>.from(newValues),
        );

        emit(state.copyWith(sensors: sensors));
        _saveSensors();
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
    final sensors = List<SensorData>.from(state.sensors);
    sensors.removeAt(index);
    emit(state.copyWith(sensors: sensors));
    _saveSensors();
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HomeCubit(),
      child: const HomePageView(),
    );
  }
}

class HomePageView extends StatelessWidget {
  const HomePageView({super.key});

  Future<void> scanQrCode(BuildContext context) async {
    final result = await Navigator.push<Map<String, dynamic>?>(
      context,
      MaterialPageRoute<Map<String, dynamic>?>(
        builder: (context) => const QrScannerPage(),
      ),
    );

    if (result != null && context.mounted) {
      final login = result['login'];
      final password = result['password'];
      if (login != null && password != null) {
        context
            .read<HomeCubit>()
            .sendConnectRequest(login.toString(), password.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HomeCubit, HomeState>(
      listener: (context, state) {
        if (state.isOffline) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You are offline')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Back online')),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WiFi Status: ${state.isOffline ? 'Offline' : 'Online'}',
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
                Text(
                  'Server Status: ${state.serverStatus}',
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
              ],
            ),
            centerTitle: false,
            actions: [
              TextButton.icon(
                onPressed: () => scanQrCode(context),
                icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                label: const Text(
                  'Connect',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: state.sensors.length,
                  itemBuilder: (context, i) {
                    final sensor = state.sensors[i];
                    return SensorWidget(
                      sensorName: sensor.title,
                      values: sensor.values,
                      onUpdate: (_, values) {
                        context.read<HomeCubit>().updateSensor(i, values);
                      },
                      onDelete: () {
                        context.read<HomeCubit>().deleteSensor(i);
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.read<HomeCubit>().sendDisconnectRequest();
                  },
                  icon: const Icon(Icons.power_settings_new),
                  label: const Text('Disconnect'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
